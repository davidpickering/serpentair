# The Snowflake service user that runs the environment roots (infra/envs/*): locally through
# infra/tf.sh now, and from GitHub Actions in #9 (private key in a GitHub environment secret).
#
# TYPE = SERVICE: no password, no MFA, no Snowsight login; key-pair auth only.
# Only the public key lives here; the private key never enters the repo or Terraform state.

locals {
  # Snowflake wants the public key body on one line, without the BEGIN/END header and trailer.
  ci_public_key = join("", [
    for line in split("\n", replace(file(var.ci_public_key_path), "\r", "")) :
    line if line != "" && !startswith(line, "-----")
  ])
}

resource "snowflake_service_user" "terraform_ci" {
  name           = var.ci_user_name
  comment        = "Runs Terraform for infra/envs/* (managed by infra/bootstrap)."
  rsa_public_key = local.ci_public_key
  default_role   = "SYSADMIN"

  # New users get ALL secondary roles by default, which would quietly add ACCOUNTADMIN's
  # privileges to every SYSADMIN session. NONE keeps each session to the one role Terraform
  # asks for, so ACCOUNTADMIN is only in play where a provider alias explicitly uses it.
  default_secondary_roles_option = "NONE"
}

# SYSADMIN creates objects (databases, schemas); SECURITYADMIN creates roles and grants;
# ACCOUNTADMIN is needed only because Snowflake reserves resource monitors (and attaching them
# to warehouses) for it.
resource "snowflake_grant_account_role" "terraform_ci" {
  for_each  = toset(["SYSADMIN", "SECURITYADMIN", "ACCOUNTADMIN"])
  role_name = each.key
  user_name = snowflake_service_user.terraform_ci.name
}
