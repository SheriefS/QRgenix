output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  value = "https://${var.tailscale_hostname}.${var.tailscale_domain}"
}

output "k3s_public_ip" {
  value = aws_instance.k3s_server.public_ip
  description = "Use this IP to update your DuckDNS record and kubeconfig"
}

output "k3s_tailscale_url" {
  value = "https://${var.k3s_tailscale_hostname}.${var.tailscale_domain}"
}
