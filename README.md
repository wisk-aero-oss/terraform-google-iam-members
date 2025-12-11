
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# terraform-google-iam-members

[![Releases](https://img.shields.io/github/v/release/notablehealth/terraform-google-iam-members)](https://github.com/notablehealth/terraform-google-iam-members/releases)

[Terraform Module Registry](https://registry.terraform.io/modules/notablehealth/iam-members/google)

Terraform module for Google IAM memberships

Role parameters:
- Google roles
- Project custom roles
- Organization custom roles
- IAM Conditions

Resource bindings to:
- Organization
- Project
- Storage bucket roles
- BigQuery dataset roles
- BigQuery table roles
- Cloud Run jobs
- Secrets
- Service Accounts
- Artifact Registry Repositories

## Role formats

The role strings taken as input embed multiple identifiers for where the IAM binding is made, what role is bound, and to what resource. Custom project/org level roles require a prefix as well.

The general format is:
`<resource type>:[<org|project>-]<role name>:<resource type parameters: ...>`

### Resource type
A prefix/alias that controls what type of resource the binding is made on. Can be excluded, which will make the binding on the configured project/organization by default.

### Role name
The ID of the role to bind. For default roles, *do not* include the `roles/` prefix. For custom roles, it depends on where the role is configured. If in the project, prefix the ID with `project-`. If in the organization, prefix the ID with `org-`.

### Resource type parameters
An identifier for the resource the binding is made too. Usually a name/single ID, sometimes multiple colon-separated values. Depends on resource type, see below.

### Supported resource formats

| resource type | resource type | resource type params |
|---|---|---|
| project/org | null | null |
| storage bucket  |  storage | bucket name |
| bigquery dataset | bigquery-dataset | datasetId |
| bigquery table | bigquery-table | datasetId:tableId |
| cloud run jobs | cloud-run-job | job name |
| billing acct | billing | null |
| gcsm secrets | secret | secret name
| service accounts | service-account | service account name
| artifact registry repository | artifact-registry | repository name

## Required Inputs

organization\\_id XOR project\\_id MUST be specified

## Usage

Basic usage of this module is as follows:

```hcl
module "example" {
    source = "notablehealth/<module-name>/google"
    # Recommend pinning every module to a specific version
    # version = "x.x.x"
    # Required variables
        members =
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.12.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.12.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_bigquery_dataset_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | resource |
| [google_bigquery_table_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table_iam_member) | resource |
| [google_billing_account_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_account_iam_member) | resource |
| [google_cloud_run_v2_job_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job_iam_member) | resource |
| [google_organization_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket_iam_member.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [null_resource.org_proj_precondition_validation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [google_billing_account.self](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/billing_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_billing_account_name"></a> [billing\_account\_name](#input\_billing\_account\_name) | Billing account name. | `string` | `""` | no |
| <a name="input_default_location"></a> [default\_location](#input\_default\_location) | The default location | `string` | `null` | no |
| <a name="input_members"></a> [members](#input\_members) | List of members and roles to add them to. | <pre>list(object({<br/>    member = string<br/>    roles = list(object({<br/>      role     = string<br/>      resource = optional(string, "base")<br/>      location = optional(string)<br/>      condition = optional(object({<br/>        description = string<br/>        expression  = string<br/>        title       = string<br/>      }))<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Organization ID. | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID. | `string` | `""` | no |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
