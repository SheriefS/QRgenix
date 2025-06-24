#!/bin/bash
set -e

# Path to virtualenv
VENV_DIR="ansible-venv"

# Create if missing
if [ ! -d "$VENV_DIR" ]; then
  echo "⚙️ Creating virtual environment..."
  python3 -m venv "$VENV_DIR"
  source "$VENV_DIR/bin/activate"
  echo "⬆️ Installing Ansible and K8s modules..."
  pip install --upgrade pip
  pip install ansible kubernetes
else
  echo "🐍 Activating virtual environment"
  source "$VENV_DIR/bin/activate"
fi

echo "🚀 Running Ansible playbook: $1"
ansible-playbook -i ansible/inventory/hosts.ini "ansible/$1" --vault-password-file /tmp/vault-pass.txt
