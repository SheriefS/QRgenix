# QRgenix™

QRgenix is a cloud‑native, full‑lifecycle QR code generation application built to showcase end‑to‑end DevOps best practices:

## Overview & Goals

- Deliver a user‑friendly web app (Django REST API + React SPA) that dynamically generates high‑resolution QR codes.

- Automate every stage—from build and test through deployment and ongoing patching—to demonstrate modern CI/CD and infrastructure automation.

## Key Achievements

- Containerized CI/CD Toolchain: Migrated Jenkins and Ansible into Docker containers on AWS EC2, enabling a drop from T3.medium → T3.small (50% cost reduction) and 100% elimination of manual patching.

- Infrastructure as Code: Authored reusable Bash scripts and Ansible roles for provisioning K3s clusters, performing rolling updates, and automating zero‑downtime deployments.

- Helm‑Driven Ingress: Designed and published a custom Helm chart for Traefik, automating service routing, SSL termination, and port configuration within Kubernetes.

- Observability & Storage Planning: Integrated Prometheus and Grafana for metrics collection, and architected an S3‑backed media persistence strategy to support scalable storage of QR‑code assets.
  
- Performance & UX: Optimized backend generation pipeline to handle 100+ concurrent requests with < 200 ms average response time, and implemented React‑based preview and download components for seamless user experience.

## Tech Stack
- **Cloud & Infrastructure:** AWS EC2, K3s, Docker, Helm, Ansible, Terraform
- **Backend & Frontend:** Python (Django REST), JavaScript/TypeScript (React)
- **CI/CD & Automation:** Jenkins (Dockerized), Bash, GitHub Actions (tests)
- **Monitoring & Storage:** Prometheus, Grafana, AWS S3
