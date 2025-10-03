locals {
  aws_region    = "ap-southeast-5"
  enable_config = false
  enable_gd     = false
  enable_trail  = true
}

remote_state {
  backend = "local"
  config = {
    path = "../.tfstate/${path_relative_to_include()}"
  }
}

inputs = {
  aws_region    = local.aws_region
  enable_config = local.enable_config
  enable_gd     = local.enable_gd
  enable_trail  = local.enable_trail
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {}
}
EOF
}
