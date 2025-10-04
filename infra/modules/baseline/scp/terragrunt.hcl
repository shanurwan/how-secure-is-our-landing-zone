include "root" { path = find_in_parent_folders() }

terraform {
  source = "../../../../modules/baseline/scp"
}

inputs = {
  policies = {
    baseline = file("${get_terragrunt_dir()}/baseline.json")
  }
  targets = [
    "431092647169",  # log-archive
    "362479991297",  # security
    "085854995222"   # shared-svc
  ]
}