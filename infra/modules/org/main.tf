# AWS Organizations must be managed from the management (payer) account.
resource "aws_organizations_organization" "this" {
  feature_set    = "ALL"
  lifecycle {
    prevent_destroy = true # avoid accidental teardown
  }
}

# Create OUs under the (single) root
locals {
  ou_map = { for n in var.ou_names : n => n }
}

resource "aws_organizations_organizational_unit" "ou" {
  for_each  = local.ou_map
  name      = each.key
  parent_id = aws_organizations_organization.this.roots[0].id
}

# Create accounts and place in OUs
# Note: account creation is eventually consistent and can take minutes.
resource "aws_organizations_account" "acct" {
  for_each  = { for a in var.accounts : a.name => a }

  name      = each.value.name
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.ou[each.value.ou].id

  # Default AWS creates OrganizationAccountAccessRole in the child account
  role_name = coalesce(try(each.value.role_name, null), "OrganizationAccountAccessRole")

  #  tag the account resource in Organizations (not the whole account)
  tags = coalesce(try(each.value.tags, null), {})

  # Once the account exists, AWS may not allow role_name to be changed
  lifecycle {
    ignore_changes = [role_name]
  }
}

output "account_ids" {
  description = "Map of account name to account ID."
  value       = { for k, v in aws_organizations_account.acct : k => v.id }
}
