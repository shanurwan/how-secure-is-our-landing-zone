# Use an alias provider pinned to the SSO home region
provider "aws" {
  alias  = "sso"
  region = var.sso_region
}

# Discover your Identity Center instance (in the home region)
data "aws_ssoadmin_instances" "this" {
  provider = aws.sso
}

locals {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  identity_store_id  = data.aws_ssoadmin_instances.this.identity_store_ids[0]
}

# ----- Permission sets (NO inline block here) -----
resource "aws_ssoadmin_permission_set" "ps" {
  provider          = aws.sso
  for_each          = var.permission_sets

  instance_arn     = local.instance_arn
  name             = each.value.name
  session_duration = each.value.session_duration
}

# ----- Inline policy (optional) via dedicated resource -----
# Create only when inline_policy_json is provided (non-null)
resource "aws_ssoadmin_permission_set_inline_policy" "inline" {
  provider = aws.sso
  for_each = {
    for k, v in var.permission_sets :
    k => v if try(v.inline_policy_json, null) != null
  }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ps[each.key].arn
  inline_policy      = each.value.inline_policy_json
}

# ----- Attach ALL managed policies per permission set -----
locals {
  ps_policy_pairs = flatten([
    for k, ps in var.permission_sets : [
      for p in ps.managed_policies_arn : {
        key        = "${k}|${p}"
        ps_key     = k
        policy_arn = p
      }
    ]
  ])
}

resource "aws_ssoadmin_managed_policy_attachment" "mp" {
  provider           = aws.sso
  for_each           = { for pair in local.ps_policy_pairs : pair.key => pair }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ps[each.value.ps_key].arn
  managed_policy_arn = each.value.policy_arn
}

resource "aws_ssoadmin_account_assignment" "assign" {
  provider           = aws.sso
  for_each           = { for i, a in var.assignments : i => a }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ps[each.value.permission_set].arn
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
  target_id          = each.value.account_id
  target_type        = "AWS_ACCOUNT"

  # Ensure the permission set + all managed policies exist before assignments
  depends_on = [
    aws_ssoadmin_managed_policy_attachment.mp
  ]

  # First-time orgs can take a while; 20m is safe
  timeouts {
    create = "20m"
    delete = "20m"
  }
}


output "permission_set_arns" {
  value = { for k, v in aws_ssoadmin_permission_set.ps : k => v.arn }
}
