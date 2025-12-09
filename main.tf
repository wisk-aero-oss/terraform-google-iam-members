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
 * - Organization
 * - Project
 * - Storage bucket roles
 * - BigQuery dataset roles
 * - BigQuery table roles
 * - Cloud Run jobs
 * - Secrets
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
#   google_cloud_run_service_iam_member
#   google_folder_iam_member
#   google_secret_manager_secret_iam_member - for single secret
#   google_service_account_iam_member - allow principal to impersonate service account
#   more as needed
# TODO
# Role format: sa:[org|project|]-<role>:<serviceAccount>
#resource "google_service_account_iam_member" "self" {}

# TODO: ?? update to be 1 of project, org, or billing required
resource "null_resource" "org_proj_precondition_validation" {
  lifecycle {
    precondition {
      condition     = (var.project_id != "" && var.organization_id == "") || (var.project_id == "" && var.organization_id != "")
      error_message = "Only organization_id or project_id can be specified and one must be specified."
    }
  }
}
locals {
  target_id = var.project_id != "" ? var.project_id : var.organization_id
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


# Role format: bigquery-dataset:[org|project|]-<role>:datasetId
resource "google_bigquery_dataset_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && startswith(member.resource, "bigquery-dataset:") }

  dataset_id = split(":", each.value.resource)[1]
  member     = startswith(each.value.member, "principal") ? "iamMember:${each.value.member}" : each.value.member
  project    = local.target_id
  role       = each.value.role
  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}

# Role format: bigquery-table:[org|project|]-<role>:datasetId:tableId
resource "google_bigquery_table_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && startswith(member.resource, "bigquery-table:") }

  dataset_id = split(":", each.value.resource)[1]
  member     = each.value.member
  project    = local.target_id
  role       = each.value.role
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
  member             = each.value.member
  role               = "roles/${split(":", each.value.role)[1]}"
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

# Role format: storage:[org|project|]-<role>:<bucket>
resource "google_storage_bucket_iam_member" "self" {
  for_each = { for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
  if var.project_id != "" && startswith(member.resource, "storage:") }

  bucket = split(":", each.value.resource)[1]
  member = each.value.member
  role   = each.value.role
  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}


# Role format: cloud-run-job:[org|project|]-<role>:job-name
resource "google_cloud_run_v2_job_iam_member" "self" {
  for_each = {
    for member in local.members : "${member.member}-${member.role}-${member.resource}" => member
    if var.project_id != "" && startswith(member.resource, "cloud-run-job:")
  }

  name     = split(":", each.value.resource)[1]
  member   = each.value.member
  project  = local.target_id
  location = each.value.location
  role     = each.value.role
  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      description = condition.value.description
      expression  = condition.value.expression
      title       = condition.value.title
    }
  }
}
