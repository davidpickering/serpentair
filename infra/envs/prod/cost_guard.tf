# The $15/month ceiling (ADR 0001), enforced by Snowflake itself.
#
# Standard edition on demand in AWS US East (Ohio) costs $2.00/credit, so 6 credits ≈ $12 of
# compute. The rest of the ceiling covers what a resource monitor can't see: storage
# ($23/TB-month) and serverless features such as Snowpipe.
#
# This one monitor is shared: every Terraform-managed warehouse (prod, local-dev, and qa's in
# #10) is attached to it, so the quota caps the account's total warehouse spend, not each one.
# Usage resets on the first of each calendar month (Snowflake's default when no frequency or
# start time is set; setting them explicitly would make `plan` drift).

resource "snowflake_resource_monitor" "monthly" {
  provider = snowflake.accountadmin

  name         = "SERPENTAIR_MONTHLY"
  credit_quota = var.monthly_credit_quota

  notify_triggers           = [50, 75, 90] # email at these % of the quota
  suspend_trigger           = 100          # suspend; let running queries finish
  suspend_immediate_trigger = 110          # suspend and cancel running queries

  # Receives the emails. The user needs a verified email address in Snowsight.
  notify_users = [var.snowflake_admin_user]
}
