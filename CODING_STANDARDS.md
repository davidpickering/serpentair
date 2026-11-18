# Coding standards

How this repo writes code, read at review (`/code-review`). Judgement calls only: anything a tool can check lives in `.pre-commit-config.yaml` instead.

Each rule: one line stating it, then **Why** (the reason, so it can be weighed or retired). A rule is only in force once it has a Why.

## Terraform

Baseline: HashiCorp's [Terraform style guide](https://developer.hashicorp.com/terraform/language/style). Rules here add to it or record where this repo differs.

### How we structure our Terraform

Roots, modules, state, and what lives where.

<!-- To write up from #4:
- One root per environment (infra/envs/<env>), plus infra/bootstrap for what the roots depend on.
- What earns a module vs. stays in the root.
- Local-dev objects live in the prod root.
-->

### How we style our Terraform

Naming, file layout, comments, `for_each` vs `count`.

<!-- To write up from #4:
- Snowflake object names: UPPER_CASE with the environment prefix.
- for_each over a map, not count.
- Comments explain why, not what.
-->

### Providers, roles and credentials

Which identity runs what, and with how much privilege.

<!-- To write up from #4:
- Each statement runs as the least-privileged Snowflake role that can do it, chosen with a provider alias.
- ACCOUNTADMIN only for resource monitors.
-->

### Cost safeguards

<!-- To write up from #4:
- Every warehouse is attached to the SERPENTAIR_MONTHLY resource monitor.
-->

### Change safety

Keeping plans clean and applies unsurprising.

<!-- To write up from #4:
- No arguments that show as a change on every plan (perpetual drift).
- prevent_destroy on anything that holds state or data.
-->

## dbt

Baseline: dbt Labs' [best practices](https://docs.getdbt.com/best-practices). Record deviations here as the transform layer grows.
