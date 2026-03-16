#!/bin/bash
set -e

# ── System update ─────────────────────────────────────────────
apt update && apt upgrade -y

# ── Docker (official repo) ────────────────────────────────────
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# ── AWS CLI v2 ────────────────────────────────────────────────
apt install -y unzip
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# ── Tailscale ─────────────────────────────────────────────────
# Auth key is fetched from Secrets Manager using the instance's IAM role —
# never touches the filesystem or Terraform state.
TAILSCALE_AUTH_KEY=$(aws secretsmanager get-secret-value \
  --secret-id tailscale/jenkins-auth-key \
  --query SecretString \
  --output text \
  --region ${aws_region})

curl -fsSL https://tailscale.com/install.sh | sh
tailscale up \
  --authkey="$TAILSCALE_AUTH_KEY" \
  --hostname=${tailscale_hostname} \
  --advertise-tags=tag:jenkins \
  --accept-routes

# ── Tailscale HTTPS cert ──────────────────────────────────────
CERT_DIR=/etc/ssl/tailscale
mkdir -p "$CERT_DIR"
tailscale cert \
  --cert-file "$CERT_DIR/${tailscale_hostname}.${tailscale_domain}.crt" \
  --key-file  "$CERT_DIR/${tailscale_hostname}.${tailscale_domain}.key" \
  "${tailscale_hostname}.${tailscale_domain}"

# ── Jenkins container ─────────────────────────────────────────
mkdir -p /var/jenkins_home
chown 1000:1000 /var/jenkins_home
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)

# Mount the host docker binary and compose plugin so Jenkins pipelines
# can run docker/docker compose commands against the host daemon.
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 127.0.0.1:8080:8080 \
  -v /var/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker:ro \
  -v /usr/libexec/docker/cli-plugins:/usr/libexec/docker/cli-plugins:ro \
  --group-add "$DOCKER_GID" \
  jenkins/jenkins:lts

# ── GitHub SSH known_hosts ────────────────────────────────────
# Pre-populate before any pipeline runs so git+SSH checkouts don't
# fail or prompt on first use. Owned by uid 1000 (jenkins user).
mkdir -p /var/jenkins_home/.ssh
ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts
chown -R 1000:1000 /var/jenkins_home/.ssh
chmod 700 /var/jenkins_home/.ssh
chmod 600 /var/jenkins_home/.ssh/known_hosts

# ── NGINX (HTTP → HTTPS → Jenkins container) ──────────────────
apt install -y nginx
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/jenkins <<EOF
server {
    listen 80;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;

    ssl_certificate     $CERT_DIR/${tailscale_hostname}.${tailscale_domain}.crt;
    ssl_certificate_key $CERT_DIR/${tailscale_hostname}.${tailscale_domain}.key;

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 90s;
    }
}
EOF

ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
systemctl reload nginx
