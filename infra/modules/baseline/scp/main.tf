# Create all SCPs passed in via var.policies
resource "aws_organizations_policy" "scp" {
  for_each    = var.policies
  name        = each.key
  description = "Baseline SCP: ${each.key}"
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value
}

# Build policy×target pairs for attachments
locals {
  pairs = {
    for p_t in setproduct(keys(var.policies), var.targets) :
    "${p_t[0]}|${p_t[1]}" => {
      policy = p_t[0]
      target = p_t[1]
    }
  }
}

resource "aws_organizations_policy_attachment" "attach" {
  for_each  = local.pairs
  policy_id = aws_organizations_policy.scp[each.value.policy].id
  target_id = each.value.target
}
