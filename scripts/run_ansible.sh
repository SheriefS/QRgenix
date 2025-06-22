#!/bin/bash
set -e

# Setup virtual environment
VENV_DIR="$HOME/ansible-venv"
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip ansible kubernetes

# Run the given playbook
cd ansible
ansible-playbook -i inventory/hosts.ini "$@"
