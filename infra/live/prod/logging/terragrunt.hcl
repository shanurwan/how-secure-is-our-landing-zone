include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/logging"
}

inputs = {
  enable_trail = true
}
