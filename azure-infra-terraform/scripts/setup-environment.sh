#!/usr/bin/env bash
#===============================================================================
# Setup Environment Configuration
# Creates service principal and generates .envrc with all required values
#===============================================================================
set -euo pipefail

#-------------------------------------------------------------------------------
# Colors
#-------------------------------------------------------------------------------
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' N='\033[0m'
log()  { echo -e "${C}[INFO]${N} $*"; }
ok()   { echo -e "${G}[OK]${N} $*"; }
warn() { echo -e "${Y}[WARN]${N} $*"; }
err()  { echo -e "${R}[ERROR]${N} $*" >&2; }

#-------------------------------------------------------------------------------
# Usage
#-------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $0 -e ENVIRONMENT -p PREFIX [-l LOCATION]

Setup Terraform environment configuration.

Required:
  -e    Environment name (dev, staging, prod)
  -p    Project prefix for naming

Optional:
  -l    Azure region (default: eastus)
  -h    Show this help

Example:
  $0 -e dev -p myproject

This script will:
  1. Create a service principal for Terraform
  2. Create a storage account for Terraform state
  3. Generate .envrc with all required values
  4. Store secrets in Azure Key Vault (optional)
EOF
    exit 1
}

#-------------------------------------------------------------------------------
# Parse Arguments
#-------------------------------------------------------------------------------
ENVIRONMENT=""
PREFIX=""
LOCATION="eastus"

while getopts "e:p:l:h" opt; do
    case $opt in
        e) ENVIRONMENT="$OPTARG" ;;
        p) PREFIX="$OPTARG" ;;
        l) LOCATION="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

[[ -z "$ENVIRONMENT" ]] && { err "Environment required"; usage; }
[[ -z "$PREFIX" ]] && { err "Prefix required"; usage; }

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
UNIQUE="${PREFIX}-${ENVIRONMENT}"
SP_NAME="tf-${UNIQUE}"
RG_NAME="${PREFIX}-tfstate-rg"
STORAGE_NAME=$(echo "${PREFIX}tfstate${ENVIRONMENT}" | tr -d '-' | tr '[:upper:]' '[:lower:]' | cut -c1-24)
CONTAINER_NAME="tfstate"
KEYVAULT_NAME="${PREFIX}${ENVIRONMENT}kv"

#-------------------------------------------------------------------------------
# Check Azure Login
#-------------------------------------------------------------------------------
log "Checking Azure login..."
if ! az account show &>/dev/null; then
    log "Please login to Azure..."
    az login
fi

# Get current context
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo ""
log "Configuration:"
echo "  Subscription:     $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "  Tenant:           $TENANT_ID"
echo "  Environment:      $ENVIRONMENT"
echo "  Location:         $LOCATION"
echo "  Service Principal: $SP_NAME"
echo "  Storage Account:  $STORAGE_NAME"
echo ""

read -p "Continue with this configuration? (y/N) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

#-------------------------------------------------------------------------------
# Create Resource Group
#-------------------------------------------------------------------------------
log "Creating resource group: $RG_NAME"
if az group show --name "$RG_NAME" &>/dev/null; then
    ok "Resource group already exists"
else
    az group create --name "$RG_NAME" --location "$LOCATION" --output none
    ok "Resource group created"
fi

#-------------------------------------------------------------------------------
# Create Storage Account
#-------------------------------------------------------------------------------
log "Creating storage account: $STORAGE_NAME"
if az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" &>/dev/null; then
    ok "Storage account already exists"
else
    az storage account create \
        --name "$STORAGE_NAME" \
        --resource-group "$RG_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --output none
    ok "Storage account created"
fi

# Get storage key
STORAGE_KEY=$(az storage account keys list \
    --account-name "$STORAGE_NAME" \
    --resource-group "$RG_NAME" \
    --query '[0].value' -o tsv)

# Create container
log "Creating blob container: $CONTAINER_NAME"
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_NAME" \
    --account-key "$STORAGE_KEY" \
    --output none 2>/dev/null || true
ok "Container ready"

#-------------------------------------------------------------------------------
# Create Service Principal
#-------------------------------------------------------------------------------
log "Creating service principal: $SP_NAME"

# Check if SP already exists
EXISTING_SP=$(az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_SP" ]]; then
    warn "Service principal already exists: $EXISTING_SP"
    warn "Creating new credentials..."
    
    CLIENT_ID="$EXISTING_SP"
    CLIENT_SECRET=$(az ad sp credential reset \
        --id "$CLIENT_ID" \
        --query password -o tsv)
else
    # Create new SP
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role Contributor \
        --scopes "/subscriptions/${SUBSCRIPTION_ID}" \
        --query '{appId:appId, password:password}' -o json)
    
    CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
    CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r '.password')
    ok "Service principal created"
fi

#-------------------------------------------------------------------------------
# Generate .envrc
#-------------------------------------------------------------------------------
ENVRC_FILE=".envrc"
log "Generating $ENVRC_FILE..."

cat > "$ENVRC_FILE" << EOF
#!/usr/bin/env bash
#===============================================================================
# Environment: ${ENVIRONMENT^^}
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# 
# WARNING: This file contains secrets. Never commit to version control!
#===============================================================================

# Project
export ENVIRONMENT="${ENVIRONMENT}"
export PROJECT_PREFIX="${PREFIX}"
export UNIQUE="${UNIQUE}"

# Azure Authentication
export ARM_TENANT_ID="${TENANT_ID}"
export ARM_SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"
export ARM_CLIENT_ID="${CLIENT_ID}"
export ARM_CLIENT_SECRET="${CLIENT_SECRET}"

# Terraform State Backend
export TF_VAR_remote_state_account="${STORAGE_NAME}"
export TF_VAR_remote_state_container="${CONTAINER_NAME}"
export ARM_ACCESS_KEY="${STORAGE_KEY}"

# Resource Locations
export TF_VAR_resource_group_location="${LOCATION}"
export TF_VAR_secondary_location="westus"

# Workspace Names
export TF_VAR_central_resources_workspace_name="central-${ENVIRONMENT}"
export TF_VAR_network_workspace_name="network-${ENVIRONMENT}"
export TF_VAR_compute_workspace_name="compute-${ENVIRONMENT}"

# SSH Keys (generate with: ssh-keygen -t ed25519 -f ~/.ssh/${UNIQUE}-key)
export TF_VAR_ssh_public_key_file="\${HOME}/.ssh/${UNIQUE}-key.pub"
export TF_VAR_ssh_private_key_file="\${HOME}/.ssh/${UNIQUE}-key"
EOF

chmod 600 "$ENVRC_FILE"
ok "Generated $ENVRC_FILE"

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${G}Environment Setup Complete${N}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Resources Created:"
echo "  • Resource Group:    $RG_NAME"
echo "  • Storage Account:   $STORAGE_NAME"
echo "  • Service Principal: $SP_NAME (Client ID: $CLIENT_ID)"
echo ""
echo "Files Generated:"
echo "  • .envrc (contains secrets - DO NOT COMMIT)"
echo ""
echo "Next Steps:"
echo "  1. Install direnv: brew install direnv"
echo "  2. Allow this directory: direnv allow"
echo "  3. Generate SSH keys: ssh-keygen -t ed25519 -f ~/.ssh/${UNIQUE}-key"
echo "  4. Run Terraform: cd environments/${ENVIRONMENT} && terraform init"
echo ""
echo -e "${Y}⚠️  SECURITY WARNING${N}"
echo "  • .envrc contains secrets - ensure it's in .gitignore"
echo "  • Rotate credentials regularly"
echo "  • For production, use Azure Key Vault or managed identity"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
