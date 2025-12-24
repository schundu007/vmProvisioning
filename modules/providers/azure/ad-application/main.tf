resource "random_uuid" "app_role_id" {}

data "azuread_service_principal" "main" {
  count        = var.aad_client_id != "" ? 0 : length(local.api_names)
  display_name = local.api_names[count.index]
}

resource "azuread_application" "main" {
  count                          = var.aad_client_id != "" ? 0 : 1
  display_name                   = var.display_name
  identifier_uris                = local.identifier_uris
  sign_in_audience               = var.sign_in_audience
  fallback_public_client_enabled = local.fallback_public_client_enabled
  group_membership_claims        = var.group_membership_claims

  dynamic "required_resource_access" {
    for_each = local.required_resource_access

    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access

        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  dynamic "app_role" {
    for_each = local.app_roles

    content {
      allowed_member_types = app_role.value.member_types
      display_name         = app_role.value.display_name
      description          = app_role.value.description
      value                = coalesce(app_role.value.value, app_role.value.name)
      enabled              = app_role.value.enabled
      id                   = random_uuid.app_role_id.result
    }
  }

  api {
    mapped_claims_enabled          = false
    requested_access_token_version = 1

    known_client_applications = var.known_client_applications

    dynamic "oauth2_permission_scope" {
      for_each = local.oauth2_permission_scopes
      content {
        admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
        admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
        enabled                    = oauth2_permission_scope.value.enabled
        id                         = oauth2_permission_scope.value.id
        type                       = oauth2_permission_scope.value.type
        user_consent_description   = oauth2_permission_scope.value.user_consent_description
        user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
        value                      = oauth2_permission_scope.value.value
      }
    }
  }

  web {
    homepage_url  = coalesce(var.homepage_url, local.homepage_url)
    redirect_uris = var.redirect_uris
    implicit_grant {
      access_token_issuance_enabled = var.access_token_issuance_enabled
      id_token_issuance_enabled     = true
    }
  }
}

resource "random_password" "main" {
  count   = var.aad_client_id == "" && var.password == "" ? 1 : 0
  length  = 32
  special = false
}

resource "azuread_application_password" "main" {
  count          = var.aad_client_id == "" && var.password != null ? 1 : 0
  application_id = var.aad_client_id != "" ? null : azuread_application.main[0].id

  end_date          = local.end_date
  end_date_relative = local.end_date_relative

  lifecycle {
    ignore_changes = all
  }
}
