include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/baseline/scp"
}

# Option A: attach to OUs (recommended; new accounts inherit automatically)
# Use your real OU IDs from your earlier output:
#   Security: ou-cxl6-ybrornna
#   Sandbox : ou-cxl6-uulzjw06
#   Dev     : ou-cxl6-xbbb7rzu
#   Stage   : ou-cxl6-hf8ttxbf
#   Prod    : ou-cxl6-umyc9z77

inputs = {
  policies = { baseline = file("${get_terragrunt_dir()}/baseline.json") }
  targets = [
    "ou-cxl6-ybrornna", # Security
    "ou-cxl6-uulzjw06", # Sandbox
    "ou-cxl6-xbbb7rzu", # Dev
    "ou-cxl6-hf8ttxbf", # Stage
    "ou-cxl6-umyc9z77"  # Prod
  ]
}

# Option B (alternative): attach directly to accounts (won't affect mgmt)
# targets = ["431092647169","362479991297","085854995222"]
