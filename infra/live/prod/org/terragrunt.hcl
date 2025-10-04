include "root" {
  path = "../../../terragrunt.hcl" # include root directly
}

locals {
  environment = "prod"
}

terraform {
  source = "../../../modules/org"
}

inputs = {
  ou_names = ["Security", "Sandbox", "Dev", "Stage", "Prod"]
  accounts = [
    { name = "log-archive", email = "aws+log-archive-20251004@example.com", ou = "Security" },
    { name = "security", email = "aws+security@example.com", ou = "Security" },
    { name = "shared-svc", email = "aws+shared@example.com", ou = "Prod" }
  ]
}
