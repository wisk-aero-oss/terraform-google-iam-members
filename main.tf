/**
 * # terraform-google-iam-members
 *
 * [![Releases](https://img.shields.io/github/v/release/notablehealth/terraform-google-iam-members)](https://github.com/notablehealth/terraform-google-iam-members/releases)
 *
 * [Terraform Module Registry](https://registry.terraform.io/modules/notablehealth/iam-members/google)
 *
 * Terraform module for Google IAM memberships
 *
 * Role parameters:
 * - Google roles
 * - Project custom roles
 * - Organization custom roles
 * - IAM Conditions
 *
 * Resource bindings to:
 * - Folder
 * - Organization
 * - Project
 * - Storage bucket roles
 * - BigQuery dataset roles
 * - BigQuery table roles
 * - Cloud Run jobs
 * - Secrets
 * - Service Accounts
 * - Artifact Registry Repositories
 *
 * ## Role formats
 *
 * The role strings taken as input embed multiple identifiers for where the IAM binding is made, what role is bound, and to what resource. Custom project/org level roles require a prefix as well.
 *
 * The general format is:
 * `<resource type>:[<org|project>-]<role name>:<resource type parameters: ...>`
 *
 * ### Resource type
 * A prefix/alias that controls what type of resource the binding is made on. Can be excluded, which will make the binding on the configured project/organization by default.
 *
 * ### Role name
 * The ID of the role to bind. For default roles, *do not* include the `roles/` prefix. For custom roles, it depends on where the role is configured. If in the project, prefix the ID with `project-`. If in the organization, prefix the ID with `org-`.
 *
 * ### Resource type parameters
 * An identifier for the resource the binding is made too. Usually a name/single ID, sometimes multiple colon-separated values. Depends on resource type, see below.
 *
 * ### Supported resource formats
 *
 * | resource type | resource type | resource type params |
 * |---|---|---|
 * | project/org | null | null |
 * | storage bucket  |  storage | bucket name |
 * | bigquery dataset | bigquery-dataset | datasetId |
 * | bigquery table | bigquery-table | datasetId:tableId |
 * | cloud run jobs | cloud-run-job | job name |
 * | billing acct | billing | null |
 * | gcsm secrets | secret | secret name
 * | service accounts | service-account | service account name
 * | artifact registry repository | artifact-registry | repository name
 *
 * ## Required Inputs
 *
 * organization\_id XOR project\_id MUST be specified
 *
 */

# TODO:
#   constraint patterns ?
#     secret prefix
#       expression  = "resource.name.startsWith(${format("\"%s/%s/%s/%s%s\"","projects",var.project_number,"secrets",each.value.secrets_prefix,"__")})"
#   more as needed


# TODO: ?? update to support billing required. 1 of the 4 must be specified
resource "null_resource" "org_proj_precondition_validation" {
  lifecycle {
    precondition {
      condition = (
        (var.folder_id != "" ? 1 : 0) +
        (var.project_id != "" ? 1 : 0) +
        (var.organization_id != "" ? 1 : 0) == 1
      )
      error_message = "One and only one of the following must be specified: folder_id, project_id, organization_id"
    }
  }
}
locals {
  target_id = var.project_id != "" ? var.project_id : var.organization_id != "" ? var.organization_id : var.folder_id
  members = flatten(
    [
      for member in var.members :
      [
        for role in member.roles :
        {
          member   = member.member,
          resource = role.resource,
          role = (
            split(":", role.role)[0] == "project" ?
            "projects/${var.project_id}/roles/${split(":", role.role)[1]}"
            :
            split(":", role.role)[0] == "org" ?
            "organizations/${var.organization_id}/roles/${split(":", role.role)[1]}"
            :
            "roles/${role.role}"
          )
          # note lookup function doesn't work because in an object all keys are always present
          location  = role.location == null ? var.default_location : role.location,
          condition = role.condition
        }
      ]
  ])
}

resource "google_bigquery_dataset_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && startswith(member.resource, "bigquery-dataset:") }

  project = local.target_id
  role    = each.value.role
  member  = startswith(each.value.member, "principal") ? "iamMember:${each.value.member}" : each.value.member

  dataset_id = split(":", each.value.resource)[1]

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_bigquery_table_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && startswith(member.resource, "bigquery-table:") }

  project = local.target_id
  role    = each.value.role
  member  = each.value.member

  dataset_id = split(":", each.value.resource)[1]
  table_id   = split(":", each.value.resource)[2]

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_billing_account_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.billing_account_name != "" && startswith(member.resource, "billing:") }

  billing_account_id = data.google_billing_account.self[0].id
  role               = each.value.role
  member             = each.value.member
}

resource "google_folder_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.folder_id != "" && member.resource == "base" }
  folder = startswith(var.folder_id, "folder/") ? var.folder_id : "folder/${var.folder_id}"
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}
resource "google_organization_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.organization_id != "" && member.resource == "base" }

  org_id = local.target_id
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_project_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && member.resource == "base" }

  project = local.target_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_storage_bucket_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && startswith(member.resource, "storage:") }

  role   = each.value.role
  member = each.value.member

  bucket = split(":", each.value.resource)[1]

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_cloud_run_v2_job_iam_member" "self" {
  for_each = {
    for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
    if var.project_id != "" && startswith(member.resource, "cloud-run-job:")
  }

  project  = local.target_id
  location = each.value.location
  role     = each.value.role
  member   = each.value.member

  name = split(":", each.value.resource)[1]

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_secret_manager_secret_iam_member" "self" {
  for_each = {
    for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
    if var.project_id != "" && startswith(member.resource, "secret:")
  }

  project = local.target_id
  role    = each.value.role
  member  = each.value.member

  secret_id = "projects/${local.target_id}/secrets/${split(":", each.value.resource)[1]}"

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_service_account_iam_member" "self" {
  for_each = {
    for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
    if var.project_id != "" && startswith(member.resource, "service-account:")
  }

  role   = each.value.role
  member = each.value.member

  service_account_id = split(":", each.value.resource)[1]

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "self" {
  for_each = {
    for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
    if var.project_id != "" && startswith(member.resource, "artifact-registry:")
  }

  project  = local.target_id
  location = each.value.location
  role     = each.value.role
  member   = each.value.member

  repository = split(":", each.value.resource)[1]

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}
