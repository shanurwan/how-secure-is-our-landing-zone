include "root" {
  path = find_in_parent_folders()
}

terraform {
  # Temporary placeholder module
  source = "tfr://registry.terraform.io/hashicorp/null//"
}
