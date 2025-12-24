variable "aad_client_id" {
  description = "Existing Application AppId."
  type        = string
  default     = ""
}

variable "display_name" {
  type        = string
  description = "The display name of the application"
}

variable "homepage_url" {
  type        = string
  default     = ""
  description = "(Optional) Home page or landing page of the application."
}

variable "redirect_uris" {
  type        = list(string)
  default     = []
  description = "(Optional) A set of URLs where user tokens are sent for sign-in, or the redirect URIs where OAuth 2.0 authorization codes and access tokens are sent. Must be a valid https or ms-appx-web URL."
}

variable "identifier_uris" {
  type        = list(string)
  default     = []
  description = "List of unique URIs that Azure AD can use for the application."
}

variable "sign_in_audience" {
  type        = string
  default     = "AzureADMyOrg"
  description = "(Optional) The Microsoft account types that are supported for the current application. Must be one of AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount or PersonalMicrosoftAccount. Defaults to AzureADMyOrg."
}

variable "access_token_issuance_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether this web application can request an access token using OAuth 2.0 implicit flow."
}

variable "group_membership_claims" {
  type        = list(string)
  default     = ["SecurityGroup"]
  description = "Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects."
}

variable "password" {
  type        = string
  default     = ""
  description = "The application password (aka client secret)."
}

variable "end_date" {
  type        = string
  default     = "2Y"
  description = "The RFC3339 date after which credentials expire."
}

variable "api_permissions" {
  type        = any
  default     = []
  description = "List of API permissions."
}

variable "app_roles" {
  type        = any
  default     = []
  description = "List of App roles."
}

variable "native" {
  type        = bool
  default     = false
  description = "Whether the application can be installed on a user's device or computer."
}

variable "known_client_applications" {
  description = "(Optional) A set of application IDs (client IDs), used for bundling consent if you have a solution that contains two parts: a client app and a custom web API app."
  type        = list(string)
  default     = []
}

variable "oauth2_permission_scopes" {
  type        = any
  default     = []
  description = "List of Oauth scope permissions."
}

locals {
  homepage_url = format("https://%s", var.display_name)

  type = var.native ? "native" : "webapp/api"

  fallback_public_client_enabled = var.native ? true : false

  default_identifier_uris = [format("api://%s", var.display_name)]

  identifier_uris = var.native ? [] : coalescelist(var.identifier_uris, local.default_identifier_uris)

  api_permissions = [
    for p in var.api_permissions : merge({
      id                       = ""
      name                     = ""
      app_roles                = []
      oauth2_permission_scopes = []
    }, p)
  ]

  api_names = local.api_permissions[*].name

  service_principals = {
    for s in data.azuread_service_principal.main : s.display_name => {
      application_id           = s.application_id
      display_name             = s.display_name
      app_roles                = { for p in s.app_roles : p.value => p.id }
      oauth2_permission_scopes = { for p in s.oauth2_permission_scopes : p.value => p.id }
    }
  }

  required_resource_access = var.aad_client_id != "" ? [] : [
    for a in local.api_permissions : {
      resource_app_id = local.service_principals[a.name].application_id
      resource_access = concat(
        [for p in a.oauth2_permission_scopes : {
          id   = local.service_principals[a.name].oauth2_permission_scopes[p]
          type = "Scope"
        }],
        [for p in a.app_roles : {
          id   = local.service_principals[a.name].app_roles[p]
          type = "Role"
        }]
      )
    }
  ]

  app_roles = [
    for r in var.app_roles : merge({
      name         = ""
      description  = ""
      member_types = []
      enabled      = true
      value        = ""
    }, r)
  ]

  oauth2_permission_scopes = [
    for p in var.oauth2_permission_scopes : merge({
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", var.display_name)
      admin_consent_display_name = format("Access %s", var.display_name)
      enabled                    = true
      id                         = ""
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", var.display_name)
      user_consent_display_name  = format("Access %s", var.display_name)
      value                      = "user_impersonation"
    }, p)
  ]

  date = regexall("^(?:(\\d{4})-(\\d{2})-(\\d{2}))[Tt]?(?:(\\d{2}):(\\d{2})(?::(\\d{2}))?(?:\\.(\\d+))?)?([Zz]|[\\+|\\-]\\d{2}:\\d{2})?$", var.end_date)

  duration = regexall("^(?:(\\d+)Y)?(?:(\\d+)M)?(?:(\\d+)W)?(?:(\\d+)D)?(?:(\\d+)h)?(?:(\\d+)m)?(?:(\\d+)s)?$", var.end_date)

  end_date_relative = length(local.duration) > 0 ? format(
    "%dh",
    (
      (coalesce(local.duration[0][0], 0) * 24 * 365) +
      (coalesce(local.duration[0][1], 0) * 24 * 30) +
      (coalesce(local.duration[0][2], 0) * 24 * 7) +
      (coalesce(local.duration[0][3], 0) * 24) +
      coalesce(local.duration[0][4], 0)
    )
  ) : null

  end_date = length(local.date) > 0 ? format(
    "%02d-%02d-%02dT%02d:%02d:%02d.%02d%s",
    local.date[0][0],
    local.date[0][1],
    local.date[0][2],
    coalesce(local.date[0][3], "23"),
    coalesce(local.date[0][4], "59"),
    coalesce(local.date[0][5], "00"),
    coalesce(local.date[0][6], "00"),
    coalesce(local.date[0][7], "Z")
  ) : null
}
