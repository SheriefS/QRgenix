#!/usr/bin/env bash
# run_provision.sh <playbook>
#
# Runs an Ansible playbook against the K3s instance.
# All credentials fetched at runtime — nothing sensitive in the repo:
#   qrgenix/vault-password     → decrypts the vault
#   qrgenix/ansible-vault-file → the encrypted vault file itself
#   k3s_ssh_key                → extracted from the vault

set -euo pipefail

PLAYBOOK="${1:?Usage: run_provision.sh <playbook.yaml>}"

REPO_ROOT=$(git rev-parse --show-toplevel)
ANSIBLE_DIR="$REPO_ROOT/ansible"
ANSIBLE_IMAGE="qrgenix-ansible:local"

# ------------------------------------------------------------------
# 1) Build the Ansible image from ansible/Dockerfile
# ------------------------------------------------------------------
docker build -t "$ANSIBLE_IMAGE" "$ANSIBLE_DIR"

# ------------------------------------------------------------------
# 2) Fetch vault password and vault file from Secrets Manager
#    --network host avoids IMDSv2 hop-limit issues with Docker bridge
# ------------------------------------------------------------------
_aws_secret() {
  docker run --rm --network host amazon/aws-cli \
    secretsmanager get-secret-value \
    --secret-id "$1" \
    --query SecretString \
    --output text
}

mkdir -p /var/jenkins_home/tmp

VAULT_PASS_FILE="/var/jenkins_home/tmp/ansible-vault-pass-$$.txt"
_aws_secret qrgenix/vault-password | tr -d '\n' > "$VAULT_PASS_FILE"
chmod 600 "$VAULT_PASS_FILE"

VAULT_CONTENT_FILE="/var/jenkins_home/tmp/ansible-vault-content-$$.txt"
_aws_secret qrgenix/ansible-vault-file > "$VAULT_CONTENT_FILE"
chmod 600 "$VAULT_CONTENT_FILE"

# ------------------------------------------------------------------
# 3) Extract the SSH key from the vault
# ------------------------------------------------------------------
SSH_KEY_PATH="/var/jenkins_home/tmp/ansible-ssh-key-$$.txt"
docker run --rm \
  -v "$VAULT_CONTENT_FILE:/ansible/group_vars/qrgenix/vault.yml:ro" \
  -v "$VAULT_PASS_FILE:$VAULT_PASS_FILE:ro" \
  --entrypoint python3 \
  "$ANSIBLE_IMAGE" \
  -c "
import yaml, subprocess, sys

result = subprocess.run(
    ['ansible-vault', 'view',
     '/ansible/group_vars/qrgenix/vault.yml',
     '--vault-password-file', '$VAULT_PASS_FILE'],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

if result.returncode != 0:
    sys.stderr.write(result.stderr)
    sys.exit(result.returncode)

d = yaml.safe_load(result.stdout)
sys.stdout.write(d['k3s_ssh_key'])
" > "$SSH_KEY_PATH"
chmod 600 "$SSH_KEY_PATH"

# ------------------------------------------------------------------
# 4) Run the playbook
#    The vault file is mounted at the path Ansible expects so that
#    group_vars are available without it existing in the repo.
# ------------------------------------------------------------------
docker run --rm \
  -v "$SSH_KEY_PATH:/root/.ssh/k3s_key:ro" \
  -v "$ANSIBLE_DIR:/ansible:ro" \
  -v "$VAULT_CONTENT_FILE:/ansible/group_vars/qrgenix/vault.yml:ro" \
  -v "$VAULT_PASS_FILE:$VAULT_PASS_FILE:ro" \
  -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
  -e ANSIBLE_ROLES_PATH=/ansible/roles \
  "$ANSIBLE_IMAGE" \
    -i /ansible/inventory/hosts.ini \
    /ansible/playbooks/"$PLAYBOOK" \
    --vault-password-file "$VAULT_PASS_FILE" \
    --private-key /root/.ssh/k3s_key \
    -vv

# ------------------------------------------------------------------
# 5) Cleanup
# ------------------------------------------------------------------
rm -f "$VAULT_PASS_FILE" "$VAULT_CONTENT_FILE" "$SSH_KEY_PATH"
rmdir /var/jenkins_home/tmp 2>/dev/null || true
