# Home-environment data portfolio: planning brief

Last updated: 2026-11-15.

## Status

Building V1 (spec #2). Split out of the dbt talk brief (`../dbt-2027/brief.md`) on 2026-11-11. Accounts set up in #3; #4 adds the Terraform bootstrap and Snowflake prod (`infra/`). Provisioning still needs user authorization.

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
- **Terraform layout:** shared modules, one root folder per deployed environment (`infra/envs/qa`, `infra/envs/prod`), separate state each. A small `infra/bootstrap` (state bucket, Snowflake CI user; AWS CI role pending #9) is applied once by hand; everything after goes through CI.
- **CI auth:** GitHub OIDC federation into an AWS role (no stored AWS keys); Snowflake key-pair in GitHub environment secrets; `prod` environment requires the user's approval. **AWS half blocked (2026-11-15):** the project's managed SCP denies creating the OIDC provider; decision deferred to #9 (see "Step 2 findings").
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
- **Forecast (future expansion, noted 2026-11-14):** add Open-Meteo forecast data (free tier includes the Forecast API) as a new history-source-style pull. Two goals: (1) forecast household energy usage from the weather forecast plus past energy/weather data; (2) spot good weather windows for activities (e.g. "a lunch bike ride is a real possibility today") and give advance notice of bad weather (e.g., "Driving back from the Y might be dicey at 7:15"). Likely needs a morning pull and an alert/digest channel, so it fits after Phase 3 (daily digest). Not in V1.

Verify at step 1 (account setup), before building: free dbt platform plan's deployment environments, merge jobs, and v2 support on "Latest"; Airthings consumer API history support and rate limit; Open-Meteo historical archive pricing; Prefect managed pool concurrency; Snowflake trial conversion terms and credit pricing.

## Step 1 findings (ticket #3, 2026-11-14)

- **AWS:** project-first ("new AWS experience") project `Portfolio-2026-November`, **Free** plan, $120 credits expiring 2027-05-14. One Region only: **us-east-2**, so create the Snowflake account in **AWS US East (Ohio)** to keep S3 → Snowpipe in one Region. Everything the spec needs (Lambda, S3, SQS, SNS, EventBridge incl. Scheduler, Secrets Manager, CloudWatch, Budgets, IAM, STS) is on the Free list. No IAM users ("team members" instead); human access is AWS-managed. Unverified: whether the project's managed SCPs allow creating the GitHub OIDC identity provider (check in ticket #4). MFA on; AWS budget set at $100/month (consider an extra alert near $15). CLI profile `serpentair`; `aws-mcp` installed read-only.
- **Airthings consumer API:** client is created in the Airthings dashboard (accounts.airthings.com → My Applications → Create New Application), client-credentials auth. Serves **latest values only** per Airthings' help article, confirming it's a polled source. **Rate limit confirmed 2026-11-14 from response headers: 5,000 requests/hour** (`X-RateLimit-Limit: 5000`, reset about an hour after the call); the 120/hour community figure was wrong or outdated. 15-minute polling uses a handful of calls per hour, far inside it. Client `Portfolio-2026-Dec-AWS-Lambda` created (scope `read:device:current_values`, confidential, client credentials); credentials are in serpentair's git-ignored `.env` as `AIRTHINGS_CLIENT_ID` / `AIRTHINGS_CLIENT_SECRET` and verified (token + `GET /v1/accounts` → 200).
- **Open-Meteo:** free tier is non-commercial; 600/min, 5,000/hour, 10,000/day, 300,000/month; includes Forecast, Historical Weather and Historical Forecast APIs (so the archive is free). **Important:** the Historical Weather API's ERA5 data lags ~5 days. For the daily pull of yesterday's hourly weather, use the Forecast API with `past_days` (or the Historical Forecast API); use the ERA5 archive for backfills. Data is model output, not station observations.
- **Prefect Cloud Hobby:** 2 users, 1 workspace, up to 5 deployments, 500 min/month Prefect Serverless, 7-day run retention, up to 5 Automations. Managed pools must use an official Prefect image; extra packages (e.g. PyEmVue) install at runtime via `pip_packages`; code pulled from Git. Concurrency: official docs say non-Pro accounts get 1 concurrent flow run across managed pools (stagger the Emporia and weather schedules a few minutes apart). Custom/push pools on Hobby: unconfirmed.
  - **Account set up 2026-11-14** via `uvx prefect-cloud login` (GitHub/Google sign-in; automation uses an API key, not the login). `uvx prefect-cloud github setup` connected the Prefect GitHub integration to `davidpickering/serpentair` only. `PREFECT_API_URL` and `PREFECT_API_KEY` copied from `~/.prefect/profiles.toml` into `.env` and verified (work-pool and deployment filters return 200; both empty). Managed work pool `serpentair-managed` (`prefect:managed`) created by the user the same day; status READY, no pool-level concurrency limit. The plan-level managed concurrency (docs: 1 run for non-Pro) isn't exposed on the pool, so keep staggering the Emporia and weather schedules; observe it in tickets #6/#7.
- **dbt platform Developer (free):** 1 seat, 1 project, 3,000 successful models/month, job scheduling and monitoring, browser IDE, "CI checks on GitHub and GitLab", no API access (Starter, $100/user/month, adds it). Docs say v2 (Fusion) is free and is the default for new deployment environments on supported adapters. Still to confirm inside the account: deployment environment limits on the free plan and whether merge jobs exist.
  - **Account created 2026-11-14** at `hw909.us1.dbt.com` (account `70506183176426`), project `Portfolio-2026-Nov` (ID `70506183180118`, subdirectory `transform`, connected to GitHub `davidpickering/serpentair`; warehouse connection deferred to ticket #4). IDs are in `.env` as `DBT_ACCESS_URL`, `DBT_ACCOUNT_ID`, `DBT_PROJECT_ID`. Sign-up starts a **14-day Starter trial** (ends about 2026-11-28), not the Developer plan. During the trial, API access and Starter features work, so **don't build anything that depends on them**. Check what happens at trial end: whether it drops to Developer automatically or needs a manual downgrade, and that no card is charged. Judge free-plan limits (environments, merge jobs) only against the Developer plan.
- **Snowflake (not signed up yet):** trial is 30 days or $400 credits, whichever ends first; no card needed. Edition choice at sign-up can't be changed for that account. Credit price is about $2 (Standard) / $3 (Enterprise) per credit on demand, per third-party sources; check the official consumption table for AWS US East (Ohio). An X-Small warehouse uses 1 credit/hour while running.

- **Emporia (2026-11-14):** the account was created with Google/Apple sign-in, which PyEmVue can't use. Going through Emporia's create-account flow with the same email added an email + password login to the **same** account (devices visible). PyEmVue 0.18.9 password login verified: 7 devices: two Vue panels (`Main Panel (200A)` gid 625979 and `Garage` gid 668558, model VUE003) whose circuit channels sit under WAT001 sub-devices (17 and 18 channels), plus three smart plugs (SSO001: catpad, Garage/Wreath, Dehumidifier). Hourly kWh pull for today returned 24 points. Credentials are in `.env` as `EMPORIA_EMAIL` / `EMPORIA_PASSWORD`. Token-based login (id/access/refresh tokens from the web app's IndexedDB) also works as a fallback, but its refresh-token lifetime is unknown. Note: in PyEmVue 0.18.9 an empty username or password causes a misleading `'Auth' object has no attribute 'cognito'` error.
- **No finding contradicts a settled decision, so no new ADR.** Implementation changes to carry into tickets: Open-Meteo daily pull via Forecast API `past_days` (#7); stagger Prefect schedules (#6/#7); Snowflake in AWS US East (Ohio) (#4); check the GitHub OIDC provider is allowed under the project's SCPs (#4).

## Step 2 findings (ticket #4, 2026-11-15)

- **GitHub OIDC is blocked in this AWS project.** The managed SCP for project accounts, on both the Free and Paid plans, has a `DenyIAMRestrictedActions` statement that denies `iam:*Provider*` unconditionally ([SCPs and RCPs for projects](https://docs.aws.amazon.com/accounts/latest/reference/scps-and-rcps-for-projects.html)). That covers `CreateOpenIDConnectProvider` (and SAML providers). An explicit SCP deny beats any IAM permission, so no role in the project can create one. The only way to lift it is **activating advanced features**: upgrade to Paid first; irreversible; removes spend limits; you take over the AWS Organization ([docs](https://docs.aws.amazon.com/accounts/latest/reference/activate-advanced-features.html)).
  - **Decision (user, 2026-11-15): defer to #9.** Nothing in #4 needs CI to reach AWS, so the bootstrap creates only the state bucket and the Snowflake CI user; the AWS CI role waits.
  - **To do (user) before #9:** research best practices for CI-to-AWS auth in this situation, using guides the user has access to. Options seen so far: activate advanced features (OIDC as planned); stored access keys for a dedicated IAM user in GitHub environment secrets (reverses "no stored AWS keys"); or another route the research turns up. Whatever is chosen needs an ADR, because it changes a settled decision.
- **Snowflake edition: Standard** (user, 2026-11-15). Official on-demand price in AWS US East (Ohio): **$2.00/credit** Standard (Enterprise $3.00), storage $23/TB-month ([pricing guide](https://www.snowflake.com/pricing/pricing-guide/)). Resource monitor quota set at **6 credits/month** (≈ $12), leaving room under $15 for storage and serverless (Snowpipe), which monitors don't cover.
- **Resource monitors need ACCOUNTADMIN** (to create them and to attach them to warehouses). Decision (user): the Snowflake CI user is granted `ACCOUNTADMIN` alongside `SYSADMIN`/`SECURITYADMIN`, but its default secondary roles are `NONE` and the prod root uses a separate provider alias per role, so `ACCOUNTADMIN` is only used for the monitor and warehouses.
- **Local-dev lives in the prod root:** `SERPENTAIR_DEV` (transient database), `DEV_WH`, and a `DEVELOPER` role that inherits `PROD_RAW_READER` (ADR 0002). Local-dev has no Terraform root of its own.

## Verification boundaries

Product facts (dbt v2 adapter support, free plan entitlements, Snowflake pricing, AWS free plan terms) come from interview-time research, not tested setups. Recheck before provisioning.
