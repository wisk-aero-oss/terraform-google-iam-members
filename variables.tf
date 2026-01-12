
variable "billing_account_name" {
  description = "Billing account name."
  type        = string
  default     = ""
}
variable "folder_id" {
  description = "Folder numeric id. Can be either format: ########## or folder/##########"
  type        = string
  default     = ""
}
variable "organization_id" {
  description = "Organization ID."
  type        = string
  default     = ""
}
variable "project_id" {
  description = "Project ID."
  type        = string
  default     = ""
}

variable "default_location" {
  description = "The default location"
  type        = string
  default     = null
}

# Allow global condition for all member roles
variable "members" {
  description = "List of members and roles to add them to."
  type = list(object({
    member = string
    roles = list(object({
      role     = string
      resource = optional(string, "base")
      location = optional(string)
      condition = optional(object({
        description = string
        expression  = string
        title       = string
      }))
    }))
  }))
}
