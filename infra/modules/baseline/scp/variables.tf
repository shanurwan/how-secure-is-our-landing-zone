variable "policies" {
  description = "Map of policy_name => policy JSON string"
  type        = map(string)
}

variable "targets" {
  description = "List of target IDs (ROOT or OU or ACCOUNT IDs) to attach policies to"
  type        = list(string)
}
