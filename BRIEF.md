# Home-environment data portfolio: planning brief

Last updated: 2026-11-12.

## Status

Planning only. Split out of the dbt talk brief (`../dbt-2027/brief.md`) on 2026-11-11. No code, accounts, or infrastructure exist yet; implementation and provisioning need separate user authorization. Continue with grilling plus domain-modeling against this brief and `GLOSSARY.md`.

## Goal and timing

- A shareable portfolio piece colleagues can pass around to showcase the user's skills, weighted toward tools the user's workplace uses.
- Target: roughly one month (around mid-December 2026). Soft target, not a hard deadline.
- Comes first. The user will only sign up for the dbt talk (or another talk) once the portfolio work is done.

## Settled decisions

- **Repo:** new public monorepo at this directory, segmented at a high level by tooling/concern, mirroring the user's workplace setup. dbt-watts-up-duck is not the home for it.
- **License:** permissive (MIT or Apache) for code. Raw data is excluded and lives only in the warehouse.
- **Warehouse:** the user's own Snowflake account. See [ADR 0001](docs/adr/0001-snowflake-warehouse-and-separate-talk-repo.md).
- **Cost:** $15/month planning ceiling with safeguards from day one: resource monitor with a credit quota that suspends the warehouse, 60-second auto-suspend, X-Small only, daily (not hourly) dbt job.
- **Sources:** Emporia (energy) and Airthings (indoor air quality), plus weather data.
- **Ingestion ownership rule (2026-11-11):** a Lambda on a schedule polls sources whose API only returns current values (Airthings, about every 15 minutes; consumer API reportedly allows about 120 requests/hour). Prefect pulls sources whose API serves history (Emporia via PyEmVue, weather via Open-Meteo) daily, and runs their backfills. No read API: the read Lambda and API Gateway were dropped. AWS is not used for warehousing.
- **Landing (ELT):** every pull writes the unchanged API response as JSON to the S3 landing zone, organized by source and date; Snowpipe auto-ingest loads it into a semi-structured column; dbt staging models parse it. All Terraform-managed.
- **Core competency to demonstrate:** one Terraform spec, with CI/CD making qa and prod match it, updating infrastructure and source code in one operation.
- **CI/CD pattern (from the user's past dbt work):** feature-branch compile checks; merge to qa runs qa; merge to prod runs prod, plus a schedule. User is comfortable storing cloud credentials securely in GitHub/AWS for Actions.
- **Environments (2026-11-12):** local-dev (personal schema such as `dbt_dpickering`) → qa → prod. Only qa and prod are deployed by Terraform. The user's workplace also has a shared dev tier; the portfolio leaves it out because there is one developer (say so in the README).
- **Raw data exists only in prod** and is the gold record, mirroring the user's workplace. dbt in local-dev, qa, and prod all read prod RAW and build into their own schemas. Prod is the only environment with scheduled, automated activity; qa validates that infrastructure and code still work. See [ADR 0002](docs/adr/0002-gold-record-only-in-prod.md).
- **Qa ingestion smoke run:** Terraform deploys qa's ingestion infra with schedules off. On merge to qa, CI runs each ingester once (invoke the Lambda, trigger each Prefect deployment) into a qa landing zone; qa's Snowpipe loads a disposable qa raw area; a check confirms rows arrived. dbt never reads qa raw data.
- **Prod dbt schedule, V1:** time-based with a buffer after Prefect's daily pulls (the user expects builds around midnight; e.g. Prefect 00:15 local, after the previous day has completed, then dbt 01:00; exact times set during the build). Later: Prefect triggers dbt platform runs once data pulls finish.
- **Local-dev tooling:** VS Code with the full dbt v2 distribution and the dbt extension by default (same setup as the talk's Path 2). The user may also use dbt platform's IDE for small edits.
- **dbt platform free plan facts (confirmed from the pricing page 2026-11-12):** Developer plan has **no API access**; API access starts at Starter ($100/month/seat). Developer gets only the "Latest" release track. Run-on-job-completion chaining has been a Team/Enterprise feature.
- **Deploy trigger** (code/infra merged) is owned by GitHub Actions: on merge to qa/prod, `terraform apply` → qa ingestion smoke run (qa only) → **dbt v2 CLI run from GitHub Actions** against that environment. With no free API, GitHub Actions cannot trigger dbt platform jobs.
- **dbt platform** owns the prod daily schedule (also the talk's Path 3) and is available as an IDE. Number of deployment environments and merge jobs on the free plan remain unverified; check at step 1.
- **Data trigger** (fresh data landed) is owned by Prefect later. Calling the dbt platform API is blocked on the free plan, so this remains time-based in V1. The user notes data orchestrators running dbt builds is an established advanced pattern (layer-based or vertical builds), not an anti-pattern.
- **Branch model:** feature branches → PR into `qa` → PR from `qa` into `prod`; `prod` is protected.
- **Terraform layout:** shared modules, one root folder per deployed environment (`infra/envs/qa`, `infra/envs/prod`), separate state each. A small `infra/bootstrap` (state bucket, CI role, Snowflake CI user) is applied once by hand; everything after goes through CI.
- **CI auth:** GitHub OIDC federation into an AWS role (no stored AWS keys); Snowflake key-pair in GitHub environment secrets; `prod` environment requires the user's approval.
- **Prefect hosting:** Prefect Cloud Hobby (free forever) with a Prefect Serverless (managed) work pool. Confirmed from the pricing page 2026-11-11: 500 min/month Prefect Serverless, up to 5 deployments, 2 users, 7-day run retention. Research claims, to verify: Hobby cannot create push pools such as ECS; managed pool runs 1 flow at a time.
- **Emporia:** PyEmVue ([magico13/PyEmVue](https://github.com/magico13/PyEmVue), [API docs](https://github.com/magico13/PyEmVue/blob/master/api_docs.md)) for ongoing pulls (settled 2026-11-11). Unofficial, so document the risk. The emailed CSV export route was rejected.
- **Initial build is forward-looking:** get data flowing from now on. History is a later phase.
- **Backfill (later phase):** trigger backfills with Prefect commands over date ranges, as a learning goal (user knows the Airflow equivalent). Available history: energy since about August 2026, air quality about a year longer. Weather is backfilled to match the earliest device reading. Sources whose APIs only return current values would need their manual CSV exports instead.
- **Resolution:** raw data hourly for every source. Analysis mostly at daily grain or days within a month; hourly is kept for detail views (e.g. one day by circuit).
- **Secrets/auth:** Snowflake service users use key-pair auth; Lambda secrets in AWS Secrets Manager; flow secrets in Prefect blocks; nothing in the repo; Terraform state in an S3 backend.
- **Weather source:** Open-Meteo. Free API is non-commercial only (a personal portfolio qualifies), data is CC BY 4.0 with attribution and modification notice required, under 10,000 calls/day. Unverified: whether the historical archive is free.
- **Terraform scope:** both AWS (weather Lambda, its schedule, S3 landing zone, Snowpipe notifications, Secrets Manager, state backend) and Snowflake (warehouse, resource monitor, roles, database/schemas) via the Snowflake provider.
- **Monorepo layout:** `infra/` (Terraform), `ingestion/` (Prefect flows), `transform/` (dbt), `charts/` (dbt Charts + spec), `docs/` (brief, ADRs). To do: double-check folder naming and language against the user's workplace conventions.
- **Build order:** (1) Snowflake + cost safeguards; (2) Prefect ingesting raw Emporia, Airthings, weather; (3) dbt v2 on free platform plan with daily models + scheduled job; (4) Terraform/Lambdas; (5) Charts experiment + LinkedIn post. Steps 1–4 are the portfolio piece; step 5 may slip past the month.
- **Transformation:** dbt v2 on the free dbt platform plan against Snowflake. Unverified: whether v2 jobs run on the free plan; check first.
- **Charts experiment:** dbt Charts built from one plain-English spec three ways (V1 AI unaided; V2 AI with refinement rounds; V3 one hour by hand), written up as a LinkedIn post. Personal interest and relevant to a work prototyping effort.
- **Required for the portfolio:** Terraform/Lambda, Prefect, dbt, and Charts experiment are all in scope.

## Relationship to talks

- Talks harvest from this program: specific dbt slices plus raw data extracts exported from Snowflake into DuckDB, published in a separate talk repo after the user reviews the extract.
- A talk's minimum needs from here: Snowflake set up, raw Emporia/Airthings/weather data landed, and first dbt models to daily grain. Prefect, Terraform/Lambda, and Charts are not talk prerequisites.

- **Two dbt runners in prod, explained in the README:** prod deploy runs come from CI because the free plan has no job API; dbt platform runs the daily schedule.
- **dbt version in CI:** pin a specific dbt v2 version and bump it regularly (Dependabot/Renovate), accepting that dbt platform's "Latest" track may briefly run ahead; the PR compile check catches breaks.
- **README is the front door:** architecture diagram (sources → Lambda/Prefect → S3 landing zone → Snowpipe → gold record → dbt → qa/prod), environment and deploy flow, links to ADRs, monthly cost and safeguards, and a "differences from my workplace setup" section (no shared dev tier, free-plan workarounds). Include Open-Meteo CC BY 4.0 attribution and the PyEmVue unofficial-API caveat.

- **Orchestration confirmed as-is (2026-11-12):** Prefect manages its own ingestion schedule; GitHub Actions runs deploys; dbt platform runs the prod daily schedule. User is mildly concerned about keeping CI dbt runs and dbt platform runs in sync.

- **Keeping the prod dbt runners in sync:** both build from the `prod` branch. GitHub Actions uses a `profiles.yml` kept in the repo for automation; dbt platform's prod environment is configured by hand to match (the dbt platform Terraform provider needs the API, which the free plan lacks). No overlap guard: automated builds run around midnight, when the user isn't merging PRs.
- **Airthings Lambda trigger:** an EventBridge Scheduler schedule (`rate(15 minutes)`) defined in Terraform; enabled in prod, deployed disabled in qa, where CI invokes the Lambda directly for the smoke run.

## Failure alerting (settled 2026-11-12)

- **Phase 1 (part of V1, configured as each piece is built):** failed processes email the user, using each tool's built-in notifications, with AWS-side alarms through one SNS topic. No central alert router. Covered:
  - Prefect flow failures (Prefect Automations)
  - Lambda errors (CloudWatch alarm → SNS)
  - Snowpipe load errors (silent by default; Snowflake error notifications → SNS)
  - dbt platform job failures (job email notifications)
  - GitHub Actions failures (GitHub's default emails)
  - Cost: AWS Budgets alarm, plus the Snowflake resource monitor's notify threshold before it suspends
  - Stale sources: dbt source freshness checks fail the daily job when a source stops delivering new data
- **Phase 2 (after V1):** every process writes a small JSON status event to an `_events/` folder in the landing zone; Snowpipe loads these into a raw run-log table. dbt's `run_results.json` is uploaded the same way after each run.
- **Phase 3 (after V1, before or alongside the Charts experiment):** a daily digest email of successes and failures built from the run-log table. How it is sent is not yet decided.

## Open decision tree

Planning frontier closed 2026-11-12, pending user confirmation of shared understanding.

Deferred (revisit when the prerequisite exists):

- **Data trigger:** until V1 runs. User leans toward keeping things simple and concentrating orchestration in GitHub Actions rather than having Prefect run dbt.
- **Backfill phase:** Prefect-triggered backfills of history sources; Airthings history only via manual CSV export.
- **Charts experiment:** spec, judging criteria, post outline once daily marts exist. Ideas collect in `charts/IDEAS.md`.
- **Phase 3 digest sender:** for example a Snowflake alert sending email, a Lambda with SES, or a Prefect flow; decide when Phase 2 exists.
- **Workplace naming check:** compare folder names and terms against the user's workplace conventions.
- **dbt model design:** after seeing actual landed data.
- **Forecast** Morning, get weather data, do some kind of prediction. Or highlight "Hey, a lunch bike ride would be a real possibility today".

Verify at step 1 (account setup), before building: free dbt platform plan's deployment environments, merge jobs, and v2 support on "Latest"; Airthings consumer API history support and rate limit; Open-Meteo historical archive pricing; Prefect managed pool concurrency; Snowflake trial conversion terms and credit pricing.

## Verification boundaries

Product facts (dbt v2 adapter support, free plan entitlements, Snowflake pricing, AWS free plan terms) come from interview-time research, not tested setups. Recheck before provisioning.
