# --- Credentials Azure ---
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "31ae49f9-055d-42cb-a349-f5390dbe2659"
}

# --- Konfigurasi Umum ---
variable "location" {
  description = "Azure region untuk deploy semua resources"
  type        = string
  default     = "Southeast Asia"  # Region terdekat (Singapore)
}

variable "project_name" {
  description = "Nama project, dipakai sebagai prefix resource"
  type        = string
  default     = "devops-monitoring"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# --- Konfigurasi VM ---
variable "vm_size" {
  description = "Ukuran VM Azure"
  type        = string
  default     = "Standard_B2ps_v2"  
}

variable "admin_username" {
  description = "Username admin untuk login ke VM"
  type        = string
  default     = "azureuser"
}

# --- Konfigurasi Network ---
variable "vnet_address_space" {
  description = "CIDR block untuk Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR block untuk Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# --- IP Publik kamu untuk SSH (opsional tapi lebih aman) ---
# Isi dengan IP publik kamu, atau biarkan "0.0.0.0/0" untuk akses dari mana saja
variable "allowed_ssh_ip" {
  description = "IP yang diizinkan untuk SSH (format: x.x.x.x/32 atau 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}