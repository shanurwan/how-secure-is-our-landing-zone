
variable "sso_region" {
  description = "AWS region that hosts IAM Identity Center (home region)."
  type        = string
}

variable "permission_sets" {
  description = "Map of permission-set key => settings"
  type = map(object({
    name                 = string
    session_duration     = optional(string, "PT4H")
    managed_policies_arn = optional(list(string), [])
    inline_policy_json   = optional(string, null)
  }))
}

variable "assignments" {
  description = "List of account assignments"
  type = list(object({
    principal_type  = string   # GROUP or USER
    principal_id    = string   # GUID from Identity Store
    permission_set  = string   # key from permission_sets map
    account_id      = string   # 12-digit AWS account ID
  }))
}
