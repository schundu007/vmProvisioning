#!/usr/bin/env bash
#===============================================================================
# Initialize Terraform Backend in Azure
# Creates: Resource Group, Storage Account, Container for state files
#===============================================================================
set -euo pipefail

#-------------------------------------------------------------------------------
# Colors
#-------------------------------------------------------------------------------
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' N='\033[0m'
log()  { echo -e "${C}[INFO]${N} $*"; }
ok()   { echo -e "${G}[OK]${N} $*"; }
err()  { echo -e "${R}[ERROR]${N} $*" >&2; }

#-------------------------------------------------------------------------------
# Usage
#-------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $0 -s SUBSCRIPTION_ID -e ENVIRONMENT -p PREFIX [-l LOCATION]

Initialize Terraform backend storage in Azure.

Required:
  -s    Azure Subscription ID
  -e    Environment name (dev, prod, etc.)
  -p    Project prefix for naming

Optional:
  -l    Azure region (default: eastus)
  -h    Show this help

Example:
  $0 -s "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -e dev -p myproject
EOF
    exit 1
}

#-------------------------------------------------------------------------------
# Parse Arguments
#-------------------------------------------------------------------------------
SUBSCRIPTION_ID=""
ENVIRONMENT=""
PREFIX=""
LOCATION="eastus"

while getopts "s:e:p:l:h" opt; do
    case $opt in
        s) SUBSCRIPTION_ID="$OPTARG" ;;
        e) ENVIRONMENT="$OPTARG" ;;
        p) PREFIX="$OPTARG" ;;
        l) LOCATION="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

[[ -z "$SUBSCRIPTION_ID" ]] && { err "Subscription ID required"; usage; }
[[ -z "$ENVIRONMENT" ]] && { err "Environment required"; usage; }
[[ -z "$PREFIX" ]] && { err "Prefix required"; usage; }

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
RESOURCE_GROUP="${PREFIX}-tfstate-rg"
# Storage account name: lowercase, no hyphens, max 24 chars
STORAGE_ACCOUNT=$(echo "${PREFIX}tfstate${ENVIRONMENT}" | tr -d '-' | tr '[:upper:]' '[:lower:]' | cut -c1-24)
CONTAINER_NAME="tfstate"

log "Configuration:"
echo "  Subscription:     $SUBSCRIPTION_ID"
echo "  Environment:      $ENVIRONMENT"
echo "  Location:         $LOCATION"
echo "  Resource Group:   $RESOURCE_GROUP"
echo "  Storage Account:  $STORAGE_ACCOUNT"
echo "  Container:        $CONTAINER_NAME"
echo ""

#-------------------------------------------------------------------------------
# Azure Login Check
#-------------------------------------------------------------------------------
log "Checking Azure login..."
if ! az account show &>/dev/null; then
    log "Logging into Azure..."
    az login --output none
fi

az account set --subscription "$SUBSCRIPTION_ID"
ok "Using subscription: $(az account show --query name -o tsv)"

#-------------------------------------------------------------------------------
# Create Resource Group
#-------------------------------------------------------------------------------
log "Creating resource group: $RESOURCE_GROUP"
if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    ok "Resource group already exists"
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    ok "Resource group created"
fi

#-------------------------------------------------------------------------------
# Create Storage Account
#-------------------------------------------------------------------------------
log "Creating storage account: $STORAGE_ACCOUNT"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    ok "Storage account already exists"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --output none
    ok "Storage account created"
fi

#-------------------------------------------------------------------------------
# Enable Versioning
#-------------------------------------------------------------------------------
log "Enabling blob versioning..."
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --enable-versioning true \
    --output none
ok "Versioning enabled"

#-------------------------------------------------------------------------------
# Create Container
#-------------------------------------------------------------------------------
log "Creating container: $CONTAINER_NAME"
ACCOUNT_KEY=$(az storage account keys list \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query '[0].value' -o tsv)

if az storage container show --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY" &>/dev/null; then
    ok "Container already exists"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$ACCOUNT_KEY" \
        --output none
    ok "Container created"
fi

#-------------------------------------------------------------------------------
# Output Configuration
#-------------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${G}Terraform Backend Configuration${N}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Add to your backend.tf or use with terraform init:"
echo ""
cat << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP"
    storage_account_name = "$STORAGE_ACCOUNT"
    container_name       = "$CONTAINER_NAME"
    key                  = "${ENVIRONMENT}.terraform.tfstate"
  }
}
EOF
echo ""
echo "Or initialize with:"
echo ""
echo "terraform init \\"
echo "  -backend-config=\"resource_group_name=$RESOURCE_GROUP\" \\"
echo "  -backend-config=\"storage_account_name=$STORAGE_ACCOUNT\" \\"
echo "  -backend-config=\"container_name=$CONTAINER_NAME\" \\"
echo "  -backend-config=\"key=${ENVIRONMENT}.terraform.tfstate\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
