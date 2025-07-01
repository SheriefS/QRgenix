#!/usr/bin/env bash

set -euo pipefail

PLAYBOOK="$1"

REPO_ROOT=$(git rev-parse --show-toplevel)
ANSIBLE_DIR="$REPO_ROOT/ansible"
SSH_KEY_PATH="${SSH_KEY:-}"
KNOWN_HOSTS_PATH="${KNOWN_HOSTS_PATH:-$PWD/known_hosts}"

# ------------------------------------------------------------------
# 1) Create a one-off vault file from $VAULT_PASS (exported by Jenkins)
# ------------------------------------------------------------------
VAULT_FILE=$(mktemp /tmp/ansible-vault.XXXX)
echo "$VAULT_PASS" > "$VAULT_FILE"
chmod 600 "$VAULT_FILE"

# ------------------------------------------------------------------
# 2) Run the container
# ------------------------------------------------------------------

docker run --rm --pull=always\
  -v "$SSH_KEY_PATH:/root/.ssh/k3s_key:ro" \
  -v "$KNOWN_HOSTS_PATH:/root/.ssh/known_hosts:ro" \
  -v "$KUBECONFIG_FILE:/root/.kube/config:ro" \
  -v "$ANSIBLE_DIR:/ansible:ro" \
  -v "$REPO_ROOT/k8s/staging:/workspace/k8s/staging:ro" \
  -v "$VAULT_FILE:/tmp/vault-pass.txt:ro" \
  -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
  -e ANSIBLE_ROLES_PATH=/ansible/roles \
  --entrypoint ansible-playbook \
  -w /ansible \
  ghcr.io/${GITHUB_USER}/ansible-k8s:latest \
    -i inventory/localhost.ini \
    -i inventory/hosts.ini \
    playbooks/"$PLAYBOOK" \
    -vv


# ------------------------------------------------------------------
# 3) Clean up
# ------------------------------------------------------------------
rm -f "$VAULT_FILE"
