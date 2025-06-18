# Ansible Playbooks for Infrastructure Automation

This directory contains Ansible configuration to automate server setup and environment provisioning.

## Structure

ansible/
├── inventory/
│ └── hosts.ini # Static inventory listing target hosts
├── site.yaml # Main playbook for provisioning
└── roles/ # (Optional) Modular task structure


## Usage

Run the playbook against the server defined in `inventory/hosts.ini`:

```bash
ansible-playbook -i inventory/hosts.ini site.yaml
```
Prerequisites

    Ansible installed locally (pip install ansible)
    SSH access to the server with a valid key file
    Remote host added to hosts.ini (e.g., via DuckDNS)

Notes

    Uses become: true to run tasks with sudo privileges
    Playbook includes basic tasks like installing NGINX and Docker
    Future roles (e.g., for Kubernetes setup, Jenkins agents, etc.) can go under the roles/ directory