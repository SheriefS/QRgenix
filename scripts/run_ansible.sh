#!/bin/bash
set -e

# Setup virtual environment
VENV_DIR="$HOME/ansible-venv"
VENV_ACTIVATE="$VENV_DIR/bin/activate"

# Ensure venv exists and is functional
if [ ! -f "$VENV_ACTIVATE" ]; then
  echo "⚙️  Creating new Python virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
echo "🐍 Activating virtual environment"
source "$VENV_ACTIVATE"

# Install required tools
echo "⬆️  Installing/upgrading Ansible and Kubernetes modules"
pip install --upgrade pip ansible kubernetes

# Run the given Ansible playbook
echo "🚀 Running Ansible playbook: $@"
cd ansible
ansible-playbook -i inventory/hosts.ini "$@"
