#===============================================================================
# Production Environment Configuration
# Customize these values for your deployment
#===============================================================================

# General Settings
prefix      = "myapp"
environment = "prod"
location    = "eastus"

# Network Configuration
address_space           = "10.0.0.0/16"
create_private_subnets  = true
create_database_subnets = true
create_nat_gateway      = true
num_public_subnets      = 3
num_private_subnets     = 3
num_database_subnets    = 2

# Disaster Recovery
enable_dr        = true
dr_location      = "westus"
dr_address_space = "10.1.0.0/16"

# Compute
deploy_vm         = true
vm_size           = "Standard_D8s_v5"
vm_subnet_cidr    = "10.0.10.0/24"
admin_username    = "azureadmin"
os_disk_size_gb   = 256
data_disk_size_gb = 512
enable_public_ip  = false
enable_backup     = true
enable_aad_login  = true
allowed_ssh_cidrs = []  # Add your bastion/VPN IP

# Monitoring
enable_monitoring  = true
log_retention_days = 90

# Resource Tags
tags = {
  Environment = "Production"
  Project     = "MyProject"
  Owner       = "Platform Team"
  CostCenter  = "Engineering"
  Compliance  = "Required"
}
