variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for the selected region"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair Name (only needed if you want SSH access)"
  default     = "sheriefs-qrgenix"
}

variable "tailscale_hostname" {
  description = "Hostname to show in Tailscale admin"
  default     = "jenkins-server"
}

variable "tailscale_domain" {
  description = "Tailscale tailnet domain"
  default     = "ts.net"
}


variable "k3s_key_name" {
  description = "EC2 Key Pair name for the K3s instance"
  default     = "k3s-key"
}

variable "k3s_tailscale_hostname" {
  description = "Tailscale hostname for the K3s instance"
  default     = "k3s-server"
}

