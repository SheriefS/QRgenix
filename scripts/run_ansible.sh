#!/usr/bin/env bash
# run_ansible.sh <playbook-path-relative-to-ansible-dir>
# Example: scripts/run_ansible.sh playbooks/apply-manifests.yaml

set -euo pipefail

PLAYBOOK="$1"

REPO_ROOT=$(git rev-parse --show-toplevel)
ANSIBLE_DIR="$REPO_ROOT/ansible"

# ------------------------------------------------------------------
# 1) Create a one-off vault file from $VAULT_PASS (exported by Jenkins)
# ------------------------------------------------------------------
VAULT_FILE=$(mktemp /tmp/ansible-vault.XXXX)
echo "$VAULT_PASS" > "$VAULT_FILE"
chmod 600 "$VAULT_FILE"

# ------------------------------------------------------------------
# 2) Run the container
# ------------------------------------------------------------------
docker run --rm \
  -v "$SSH_KEY":/root/.ssh/id_rsa:ro \
  -v "$KUBECONFIG_FILE":/root/.kube/config:ro \
  -v "$ANSIBLE_DIR":/ansible:ro \
  -v "$REPO_ROOT/k8s/staging.tar.gz":/staging.tar.gz:ro \
  -v "$VAULT_FILE":/tmp/vault-pass.txt:ro \
  -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
  -e ANSIBLE_ROLES_PATH=/ansible/roles \
  --entrypoint ansible-playbook \
  -w /ansible \
  ghcr.io/${GITHUB_USER}/ansible-k8s:1.0 \
    playbooks/"$PLAYBOOK" \
    -i inventory/hosts.ini \
    --vault-password-file /tmp/vault-pass.txt \
    -vv  

# ------------------------------------------------------------------
# 3) Clean up
# ------------------------------------------------------------------
rm -f "$VAULT_FILE"
