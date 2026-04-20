output "app_node_public_ip" {
  description = "IP publik Application Node"
  value       = azurerm_public_ip.app_node.ip_address
}

output "app_node_private_ip" {
  description = "IP private Application Node"
  value       = azurerm_network_interface.app_node.private_ip_address
}

output "monitoring_node_public_ip" {
  description = "IP publik Monitoring Node"
  value       = azurerm_public_ip.monitoring_node.ip_address
}

output "monitoring_node_private_ip" {
  description = "IP private Monitoring Node"
  value       = azurerm_network_interface.monitoring_node.private_ip_address
}

output "grafana_url" {
  description = "URL akses Grafana"
  value       = "http://${azurerm_public_ip.monitoring_node.ip_address}:3000"
}

output "ssh_command_app_node" {
  description = "Command SSH ke Application Node"
  value       = "ssh -i ssh-key/devops-project.pem ${var.admin_username}@${azurerm_public_ip.app_node.ip_address}"
}

output "ssh_command_monitoring_node" {
  description = "Command SSH ke Monitoring Node"
  value       = "ssh -i ssh-key/devops-project.pem ${var.admin_username}@${azurerm_public_ip.monitoring_node.ip_address}"
}

output "resource_group_name" {
  description = "Nama Resource Group di Azure"
  value       = azurerm_resource_group.main.name
}