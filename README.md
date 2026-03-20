# QRgenix

A full-stack QR code generation web application with a production-grade DevOps pipeline built on AWS. The application itself is straightforward — the engineering focus is the infrastructure: immutable deployments, zero manual credentials, and a fully automated path from commit to running container.

**Stack:** Django · React · K3s · Jenkins · Terraform · Ansible · AWS

---

## Architecture

Two EC2 instances (`t3.medium`, Ubuntu 24.04 LTS), connected via Tailscale VPN:

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│         Jenkins EC2             │     │           K3s EC2               │
│                                 │     │                                 │
│  ┌───────────────────────────┐  │     │  ┌───────────────────────────┐  │
│  │    Jenkins (Docker)       │  │     │  │  K3s (Lightweight K8s)    │  │
│  │    CI/CD Pipeline         │──┼─────┼─▶│  Traefik Ingress          │  │
│  │    Docker Build Agents    │  │     │  │  backend · frontend pods  │  │
│  └───────────────────────────┘  │     │  └───────────────────────────┘  │
│                                 │     │                                 │
│  IAM Role → Secrets Manager     │     │  IAM Role → Secrets Manager     │
└─────────────────────────────────┘     └─────────────────────────────────┘
          │                                           │
          └─────────────── Tailscale VPN ─────────────┘
```

- **Jenkins EC2** — runs Jenkins in Docker, uses ephemeral Docker agents for builds and tests, connects to the K3s cluster over Tailscale to apply manifests and trigger rollouts
- **K3s EC2** — runs K3s with Traefik as the ingress controller (Helm-installed), serves the application over HTTPS via DuckDNS + Let's Encrypt
- All secrets (GHCR token, Slack webhook, Tailscale auth key, kubeconfig) are stored in **AWS Secrets Manager** and fetched at runtime via IAM instance roles — no secrets stored in Jenkins or Ansible

---

## Tech Stack

| Category | Tools |
|---|---|
| **Application** | Python 3.12, Django 6, React 19, TypeScript, Tailwind CSS 4 |
| **Testing** | Pytest, Vitest, Testing Library |
| **Containerization** | Docker, Docker Compose, GHCR |
| **Orchestration** | Kubernetes (K3s), Traefik, Helm |
| **CI/CD** | Jenkins (Declarative Pipeline), Groovy |
| **Infrastructure** | Terraform, Ansible |
| **Cloud** | AWS EC2, AWS Secrets Manager, IAM |
| **Networking** | Tailscale VPN, DuckDNS, Let's Encrypt TLS |
| **Version Control** | Git, GitHub |

---

## Infrastructure Setup

### Prerequisites

- AWS account with CLI configured (`aws configure`)
- Terraform >= 1.0
- Ansible >= 2.14
- Docker (for the Ansible controller container)
- Tailscale auth key stored in Secrets Manager as `tailscale/jenkins-auth-key`

### 1. Provision EC2 Instances (Terraform)

```bash
cd terraform/jenkins-ec2-terraform
cp terraform.tfvars.example terraform.tfvars   # fill in region, AMI, key names
terraform init
terraform apply
```

This creates:
- Jenkins EC2 (`t3.medium`, 20GB gp3) with IAM role scoped to `tailscale/*` and `qrgenix/*` secrets
- K3s EC2 (`t3.medium`, 20GB gp3) with IAM role scoped to `tailscale/*` and `qrgenix/*` secrets
- Security groups for HTTP/HTTPS/SSH on both instances, plus port 6443 (K8s API) on the K3s instance
- User-data scripts that install Tailscale and join both instances to your tailnet at boot

### 2. Provision K3s Instance (Ansible)

```bash
cd scripts
./run_provision.sh
```

This runs the Ansible playbook in a Docker container against the K3s EC2 host, applying these roles in order:

| Role | What it does |
|---|---|
| `common` | System packages, unattended upgrades |
| `duckdns` | Registers the K3s public IP with DuckDNS for DNS-based TLS |
| `docker` | Installs Docker Engine |
| `k3s` | Installs K3s, writes kubeconfig to Secrets Manager as `qrgenix/kubeconfig` |
| `helm` | Installs Helm via official binary installer |
| `traefik` | Disables K3s built-in Traefik, installs Helm chart with Let's Encrypt TLS |

After provisioning, the K3s kubeconfig (with the cluster's private IP) is automatically pushed to `qrgenix/kubeconfig` in Secrets Manager. Jenkins fetches this at pipeline runtime — no manual kubeconfig management.

---

## CI/CD Pipeline

The Jenkins pipeline (`Jenkinsfile`) is change-aware: it detects which parts of the repository changed and skips stages that aren't relevant.

### Change Detection

| Flag | Trigger |
|---|---|
| `BACKEND_CHANGED` | Any file under `backend-django/` |
| `FRONTEND_CHANGED` | Any file under `frontend-vite/` |
| `K8S_CHANGED` | Any file under `k8s/` |
| `PIPELINE_CHANGED` | `Jenkinsfile` or `docker-compose*` |
| `RUN_FULL` | On `main` branch, or when `PIPELINE_CHANGED` is true |
| `TEST_FULL` | On feature branches, or when `PIPELINE_CHANGED` is true |

### Pipeline Stages

```
Load Secrets          → Fetch GHCR token + Slack webhook from Secrets Manager
README-only guard     → Abort early if only README.md changed
Detect Changes        → Set BACKEND/FRONTEND/K8S/PIPELINE_CHANGED flags
│
├── [Feature branches] Unit Tests
│     Frontend unit tests  (node:22-alpine, Vitest)    when FRONTEND_CHANGED
│     Backend unit tests   (python:3.12-slim, Pytest)  when BACKEND_CHANGED
│
└── [main / PIPELINE_CHANGED] Full Build & Deploy
      Init image tags
      Build + test backend CI      → docker compose CI build + run
      Build + test frontend CI     → docker compose CI build + run
      Backend prod build           → docker compose staging build
      Frontend prod build          → docker compose staging build
      Init Docker Config           → isolated temp dir for docker auth
      Docker Login                 → GHCR login (token never echoed to logs)
      Push images                  → tag :VERSION + :latest, push to GHCR
      Sync image pull secret       → create/update ghcr-secret in K8s namespace
      Apply manifests              → namespace first, then recursive apply
      Rollout deployments          → kubectl rollout restart backend/frontend
```

### Two-Layer Testing

- **Feature branches:** lightweight unit tests run directly in Docker agent containers (fast feedback)
- **main:** full CI Docker Compose build + test run (validates the actual container image), followed by a production image build

### Kubeconfig Flow

The pipeline never stores a kubeconfig file in Jenkins. On each deploy:

1. `fetchKubeconfig()` calls Secrets Manager via the Jenkins EC2's IAM role
2. Writes the kubeconfig to a build-scoped temp file (`/var/jenkins_home/tmp/kubeconfig-<BUILD_NUMBER>.yaml`)
3. Mounts it into `bitnami/kubectl` containers as read-only
4. Deleted in the `post { always }` block regardless of outcome

---

## Security Highlights

- **Zero stored credentials in Jenkins** — the only secret Jenkins holds is the GitHub PAT for SCM checkout. Everything else (GHCR token, Slack webhook, kubeconfig) is fetched from Secrets Manager at runtime using the EC2 instance's IAM role
- **Least-privilege IAM** — Jenkins IAM role is scoped to `qrgenix/*` and `tailscale/jenkins-auth-key*` only; K3s IAM role is scoped to `tailscale/*` and `qrgenix/*`
- **Token masking** — Docker Login wraps the `echo "$GHCR_TOKEN" | docker login` call in `set +x` to prevent the token appearing in build logs
- **Isolated Docker config** — each build creates a temp directory for Docker auth (`DOCKER_CONFIG`), deleted after the build regardless of outcome
- **Private IP kubeconfig** — the kubeconfig stored in Secrets Manager uses the K3s cluster's private IP (which is in the TLS certificate SANs), avoiding x509 SAN mismatch errors
- **Dependency CVE management** — backend pinned to Django 6, Pillow 12, sqlparse 0.5.5; frontend kept current via `npm audit fix`

---

## Repository Structure

```
QRgenix/
├── backend-django/          # Django REST API
│   ├── generator/           # QR code generation app + tests
│   ├── qrgenix/             # Django project settings
│   ├── Dockerfile           # Production image
│   └── requirements.txt     # Direct dependencies only (pip resolves transitive)
│
├── frontend-vite/           # React + TypeScript SPA
│   ├── src/                 # Components, pages, utils
│   ├── Dockerfile           # Production image (nginx)
│   └── Dockerfile.ci        # CI test image
│
├── k8s/staging/             # Kubernetes manifests
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-service.yaml
│   ├── ingress-http.yaml    # HTTP → HTTPS redirect
│   └── ingress-https.yaml   # TLS termination via Traefik
│
├── terraform/
│   └── jenkins-ec2-terraform/
│       ├── main.tf                # EC2, IAM roles, security groups
│       ├── variables.tf
│       ├── outputs.tf
│       ├── user-data.sh.tpl       # Jenkins instance bootstrap
│       └── k3s-user-data.sh.tpl   # K3s instance bootstrap
│
├── ansible/
│   ├── playbooks/site.yaml  # Main provisioning playbook
│   └── roles/               # common, duckdns, docker, k3s, helm, traefik
│
├── helm/
│   └── traefik-values.yaml  # Traefik Helm chart overrides
│
├── jenkins/
│   └── Provision.Jenkinsfile  # Jenkins job for running Ansible provisioning
│
├── scripts/                     # EC2 lifecycle + provisioning helpers
├── docker-compose.ci.yml        # CI build + test compose
├── docker-compose.staging.yaml  # Production image build compose
└── Jenkinsfile                  # Main CI/CD pipeline
```
