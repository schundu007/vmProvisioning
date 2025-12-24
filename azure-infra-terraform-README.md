# Azure Infrastructure Terraform Modules

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Provider%204.x-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Production-ready Terraform modules for deploying Azure infrastructure including networking, compute, monitoring, and identity resources.

---

## 📁 Project Structure

```
azure-infra-terraform/
├── modules/
│   └── azure/
│       ├── compute/
│       │   └── linux-vm/          # Linux VM with backup & recovery
│       ├── network/
│       │   ├── vnet/              # Virtual Network & Subnets
│       │   ├── nsg/               # Network Security Groups
│       │   ├── nat-gateway/       # NAT Gateway
│       │   └── routetable/        # Route Tables
│       ├── monitoring/
│       │   ├── log-analytics/     # Log Analytics Workspace
│       │   └── app-insights/      # Application Insights
│       └── identity/
│           └── ad-application/    # Azure AD Applications
├── environments/
│   ├── dev/                       # Development environment
│   └── prod/                      # Production environment
├── scripts/
│   ├── init-backend.sh            # Initialize Terraform backend
│   └── deploy.sh                  # Deployment helper script
└── examples/
    └── complete/                  # Complete deployment example
```

---

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) >= 2.50
- Azure subscription with Contributor access

### 1. Clone & Configure

```bash
git clone https://github.com/yourusername/azure-infra-terraform.git
cd azure-infra-terraform

# Login to Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Initialize Backend

```bash
# Create Terraform state backend
./scripts/init-backend.sh -s YOUR_SUBSCRIPTION_ID -e dev -p myproject
```

### 3. Deploy Infrastructure

```bash
cd environments/dev

# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=myproject-tfstate-rg" \
  -backend-config="storage_account_name=myprojecttfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"

# Plan and Apply
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## 📦 Modules

### Network Module

Deploys VNet with public/private subnets, NSG, NAT Gateway, and route tables.

```hcl
module "network" {
  source = "../../modules/azure/network"

  prefix              = "myapp"
  environment         = "dev"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = "10.0.0.0/16"

  create_public_subnets   = true
  create_private_subnets  = true
  create_nat_gateway      = true
  num_public_subnets      = 2
  num_private_subnets     = 2

  tags = var.tags
}
```

### Linux VM Module

Deploys Ubuntu/RHEL VM with managed disks, backup, and AAD authentication.

```hcl
module "linux_vm" {
  source = "../../modules/azure/compute/linux-vm"

  name                = "app-server"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  subnet_id           = module.network.private_subnet_ids[0]

  vm_size             = "Standard_D4s_v5"
  admin_username      = "azureadmin"
  os_disk_size_gb     = 128
  data_disk_size_gb   = 256

  enable_backup       = true
  enable_aad_login    = true

  tags = var.tags
}
```

### Monitoring Module

Deploys Log Analytics and Application Insights.

```hcl
module "monitoring" {
  source = "../../modules/azure/monitoring/log-analytics"

  name                = "myapp-logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  retention_in_days   = 30

  tags = var.tags
}
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `prefix` | Resource naming prefix | `myapp` |
| `environment` | Environment name | `dev`, `prod` |
| `location` | Azure region | `eastus` |
| `address_space` | VNet CIDR | `10.0.0.0/16` |

### Sample terraform.tfvars

```hcl
prefix        = "myapp"
environment   = "dev"
location      = "eastus"
address_space = "10.0.0.0/16"

tags = {
  Environment = "dev"
  Project     = "MyProject"
  ManagedBy   = "Terraform"
}
```

---

## 🔐 Security Features

- **Azure AD Authentication** - SSH login via Azure AD for Linux VMs
- **Managed Identity** - System-assigned identity for VMs
- **Network Security Groups** - Pre-configured NSG rules
- **Key Vault Integration** - Secrets stored in Azure Key Vault
- **Backup & Recovery** - Automated VM backups with retention policies
- **Private Endpoints** - Optional private connectivity

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Resource Group                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │                 Virtual Network                  │   │
│  │  ┌─────────────┐      ┌─────────────┐          │   │
│  │  │  Public     │      │  Private    │          │   │
│  │  │  Subnets    │      │  Subnets    │          │   │
│  │  │  (NAT GW)   │      │  (VMs)      │          │   │
│  │  └─────────────┘      └─────────────┘          │   │
│  └─────────────────────────────────────────────────┘   │
│                         │                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Linux VM │  │ Key Vault│  │ Log      │             │
│  │ + Backup │  │          │  │ Analytics│             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Module Outputs

### Network Module

| Output | Description |
|--------|-------------|
| `vnet_id` | Virtual Network ID |
| `vnet_name` | Virtual Network name |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nsg_id` | Network Security Group ID |

### Linux VM Module

| Output | Description |
|--------|-------------|
| `vm_id` | Virtual Machine ID |
| `vm_name` | Virtual Machine name |
| `private_ip` | Private IP address |
| `public_ip` | Public IP address (if enabled) |
| `identity_principal_id` | Managed Identity principal ID |

---

## 🔧 Customization

### Adding Custom NSG Rules

```hcl
custom_nsg_rules = [
  {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
```

### VM Cloud-Init

```hcl
custom_data = base64encode(<<-EOF
  #!/bin/bash
  apt-get update
  apt-get install -y docker.io
  systemctl enable docker
  systemctl start docker
EOF
)
```

---

## 🧪 Testing

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Security scan
tfsec .

# Cost estimation
infracost breakdown --path .
```

---

## 📝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-module`)
3. Commit changes (`git commit -am 'Add new module'`)
4. Push to branch (`git push origin feature/new-module`)
5. Open Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 👤 Author

**Sudhakar Chundu**

- GitHub: [@schundu007](https://github.com/schundu007)
- LinkedIn: [Sudhakar Chundu](https://linkedin.com/in/sudhakar-chundu)
