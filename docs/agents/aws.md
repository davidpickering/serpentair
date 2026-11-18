# AWS

How agents work with this repo's AWS project. Trimmed from the AWS Agent Toolkit's starter rules (the "new AWS experience" variant) to what applies here; project rules come first and win on conflict.

## Access

- **CLI profile:** `serpentair`: project `Portfolio-2026-November`, **Free** plan, selected Region **`us-east-2`**. Sign in with `aws login --profile serpentair`; credentials last 12 hours, renewable for 90 days without the browser.
- **Read-only for agents.** The signed-in role (`AccountFullAccessRole`) can change anything, so use the CLI and the `aws-mcp` server only to read state and documentation. Every create, change or delete goes through Terraform (and CI once it exists). `aws-mcp` runs with `--read-only`; the CLI has no such guard.
- **Help level: HIGH** (set 2026-11-14): before each AWS step, explain what it does and why, suggest better alternatives, flag best practices and trade-offs, then follow the user's choice.

## Before AWS work

For any AWS task (building, configuring, debugging, writing SDK or Terraform code, or explaining a service), first call the `aws-mcp` tool `aws___search_documentation` with topic `agent_skills` and load the matching skill with `aws___retrieve_skill`; prefer its guidance over training knowledge. The installed global AWS skills cover IAM, serverless (Lambda, EventBridge), storage (S3), messaging (SNS/SQS), observability (CloudWatch), billing, the Python SDK, investigation and sign-in.

## Project-experience constraints

- **One Region.** Create every Regional resource in `us-east-2`. The only exception is CloudWatch Logs or WAF resources a global service needs in `us-east-1`; when inventorying resources, check both. No multi-Region or cross-Region features (replication, multi-Region KMS keys, StackSets).
- **Terminology:** say *project* (not account), *team member* (not IAM user), *AWS Settings* (settings.aws.com: billing, spend limits, team members), *selected Region* (not home Region).
- **Managed IAM.** Human access is AWS-managed (no IAM users; don't assign roles to team members). Service roles and policies are still written in IAM via Terraform. Managed SCPs/RCPs apply: [SCPs and RCPs for projects](https://docs.aws.amazon.com/accounts/latest/reference/scps-and-rcps-for-projects.html). They **deny `iam:*Provider*`**, so no OIDC or SAML identity provider can be created (no GitHub OIDC for CI; see BRIEF.md → "Step 2 findings").
- **Service availability.** If a service call fails as unavailable: run `aws freetier get-account-plan-state --profile serpentair`, then check the [Free](https://docs.aws.amazon.com/accounts/latest/reference/supported-services-sign-up-new.html#supported-services-free-tier) or [Paid](https://docs.aws.amazon.com/accounts/latest/reference/supported-services-sign-up-new.html#supported-services-paid-plan) list, then the [not-supported](https://docs.aws.amazon.com/accounts/latest/reference/supported-services-sign-up-new.html#unsupported-services) list (those need "advanced features" activated).
- **Spend limits.** Sudden `AccessDenied` on calls that used to work may mean a spend limit paused the project (paid plan only): ask the user, and point them to AWS Settings → Billing. Budgets and cost analysis live in the Billing and Cost Management console.
- **Cleanup.** After creating resources outside the normal Terraform flow, ask whether to keep or remove them.

## Re-running the toolkit

`aws configure agent-toolkit` (step 7 of AWS's setup) appends its rules block to `AGENTS.md` between `<!-- BEGIN AWS Agent Toolkit rules -->` markers. If that happens, merge anything new into this file and delete the block from `AGENTS.md`.
