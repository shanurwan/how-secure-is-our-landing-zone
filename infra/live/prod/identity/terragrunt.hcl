include "root" { path = find_in_parent_folders() }

terraform {
  source = "../../../modules/identity" # live/prod/identity -> modules/identity
}

inputs = {
  # Your SSO home region (where the instance exists)
  sso_region = "ap-southeast-5"

  permission_sets = {
    admin = {
      name                 = "AdministratorAccess"
      session_duration     = "PT4H"
      managed_policies_arn = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    read_only = {
      name                 = "ReadOnlyAccess"
      session_duration     = "PT4H"
      managed_policies_arn = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  # Assign the GROUP "landing" (recommended) to your accounts
  assignments = [
    # admin on security
    { principal_type = "GROUP", principal_id = "c53d1598-9001-7084-4fe3-027eb45c8846", permission_set = "admin", account_id = "362479991297" },

    # read-only everywhere (adjust to taste)
    { principal_type = "GROUP", principal_id = "c53d1598-9001-7084-4fe3-027eb45c8846", permission_set = "read_only", account_id = "431092647169" }, # log-archive
    { principal_type = "GROUP", principal_id = "c53d1598-9001-7084-4fe3-027eb45c8846", permission_set = "read_only", account_id = "085854995222" }  # shared-svc
  ]
}
