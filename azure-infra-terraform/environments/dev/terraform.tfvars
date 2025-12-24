#===============================================================================
# Development Environment Configuration
# Customize these values for your deployment
#===============================================================================

# General Settings
prefix      = "myapp"
environment = "dev"
location    = "eastus"

# Network Configuration
address_space           = "10.0.0.0/16"
create_private_subnets  = true
create_database_subnets = false
create_nat_gateway      = false
num_public_subnets      = 2
num_private_subnets     = 2

# Disaster Recovery (Optional)
enable_dr        = false
dr_location      = "westus"
dr_address_space = "10.1.0.0/16"

# Compute (Optional)
deploy_vm         = false
vm_size           = "Standard_D4s_v5"
vm_subnet_cidr    = "10.0.10.0/24"
admin_username    = "azureadmin"
os_disk_size_gb   = 128
data_disk_size_gb = 256
enable_public_ip  = true
enable_backup     = true
enable_aad_login  = true
allowed_ssh_cidrs = []  # Add your IP: ["YOUR_IP/32"]

# Monitoring
enable_monitoring  = true
log_retention_days = 30

# Resource Tags
tags = {
  Environment = "Development"
  Project     = "MyProject"
  Owner       = "Platform Team"
  CostCenter  = "Engineering"
}
