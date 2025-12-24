#-------------------------------
# General Variables
#-------------------------------

variable "resource_group_location" {
  description = "(Required) The Azure region where all resources in this template should be created."
  type        = string
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = ""
}

variable "create_network_watcher" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = true
}

variable "env" {
  type = string
}

variable "prefix" {
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 3
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

variable "remote_state_account" {
  description = "Remote Terraform State Azure storage account name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "remote_state_container" {
  description = "Remote Terraform State Azure storage container name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "central_resources_workspace_name" {
  description = "(Required) The workspace name for the central_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "backup_address_space" {
  description = "Address Space For Backup vNet"
  type = string
  default = ""
}