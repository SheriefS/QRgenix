#!/bin/bash
set -e

echo "🐍 Activating virtual environment"
source ansible-venv/bin/activate

echo "⬆️ Installing/upgrading Ansible and Kubernetes modules"
pip install --upgrade pip ansible kubernetes

echo "🚀 Running Ansible playbook: $1"

# Use vault password from Jenkins secret
ANSIBLE_VAULT_PASS=$(cat /tmp/vault-pass.txt)
echo "$ANSIBLE_VAULT_PASS" > /tmp/vault-pass.txt

ansible-playbook "$1" \
  --inventory ansible/inventory/hosts.ini \
  --vault-password-file /tmp/vault-pass.txt