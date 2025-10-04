variable "ou_names" {
  description = "List of Organizational Unit names to create under the root."
  type        = list(string)
}

variable "accounts" {
  description = "Accounts to create and place into OUs."
  type = list(object({
    name      = string
    email     = string
    ou        = string
    role_name = optional(string)
    tags      = optional(map(string), {})
  }))
}
