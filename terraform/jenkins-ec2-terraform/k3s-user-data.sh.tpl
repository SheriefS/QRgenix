#!/bin/bash
set -e

# ── System update ─────────────────────────────────────────────
apt update && apt upgrade -y

# ── AWS CLI v2 ────────────────────────────────────────────────
apt install -y unzip
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# ── Tailscale ─────────────────────────────────────────────────
# Reads the shared reusable auth key from Secrets Manager via the instance's IAM role.
TAILSCALE_AUTH_KEY=$(aws secretsmanager get-secret-value \
  --secret-id tailscale/jenkins-auth-key \
  --query SecretString \
  --output text \
  --region ${aws_region})

curl -fsSL https://tailscale.com/install.sh | sh
tailscale up \
  --authkey="$TAILSCALE_AUTH_KEY" \
  --hostname=${k3s_tailscale_hostname} \
  --accept-routes
