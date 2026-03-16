#############################################
# main.tf
#############################################
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ── Jenkins IAM role + instance profile ──────────────────────
# Grants the Jenkins EC2 instance permission to read its Tailscale auth key
# from Secrets Manager at boot — no credentials needed in user-data or env files.
resource "aws_iam_role" "jenkins" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "jenkins_read_tailscale_secret" {
  name = "jenkins-read-tailscale-secret"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      # Trailing * is required — Secrets Manager appends a random suffix to the ARN
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:tailscale/jenkins-auth-key*"
    }]
  })
}

resource "aws_iam_role_policy" "jenkins_read_qrgenix_secrets" {
  name = "jenkins-read-qrgenix-secrets"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      # Covers qrgenix/slack-webhook, qrgenix/ghcr-token, and any future project secrets
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:qrgenix/*"
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins.name
}

# ── Jenkins instance ──────────────────────────────────────────
# t3.medium: 2 vCPU, 4GB RAM — runs Jenkins container + Docker build agents
resource "aws_instance" "jenkins_server" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = data.template_file.jenkins_user_data.rendered

  tags = {
    Name = "jenkins-server"
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow HTTP/HTTPS for Jenkins via NGINX"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "jenkins_user_data" {
  template = file("${path.module}/user-data.sh.tpl")

  vars = {
    tailscale_hostname = var.tailscale_hostname
    tailscale_domain   = var.tailscale_domain
    aws_region         = var.aws_region
  }
}

# ── K3s IAM role + instance profile ──────────────────────────
# Same shared secret as Jenkins — both use the same reusable Tailscale auth key.
resource "aws_iam_role" "k3s" {
  name = "k3s-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "k3s_read_tailscale_secret" {
  name = "k3s-read-tailscale-secret"
  role = aws_iam_role.k3s.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:tailscale/jenkins-auth-key*"
    }]
  })
}

resource "aws_iam_instance_profile" "k3s" {
  name = "k3s-ec2-profile"
  role = aws_iam_role.k3s.name
}

# ── K3s instance ──────────────────────────────────────────────
# t3.medium: 2 vCPU, 4GB RAM — runs k3s + traefik + backend + frontend pods
resource "aws_instance" "k3s_server" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  key_name                    = var.k3s_key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k3s.name

  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  user_data = data.template_file.k3s_user_data.rendered

  tags = {
    Name = "k3s-server"
  }
}

resource "aws_security_group" "k3s_sg" {
  name        = "k3s-sg"
  description = "K3s cluster: app traffic, API, and SSH"

  # HTTP — app traffic + Let's Encrypt ACME challenges
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS — app traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K3s API — kubeconfig access (Jenkins + local kubectl)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH — Ansible provisioning
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "k3s_user_data" {
  template = file("${path.module}/k3s-user-data.sh.tpl")

  vars = {
    k3s_tailscale_hostname = var.k3s_tailscale_hostname
    aws_region             = var.aws_region
  }
}
