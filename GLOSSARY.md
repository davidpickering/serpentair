# Home-environment data portfolio

Canonical language for the user's portfolio program: a shareable, work-relevant data project built on their own household energy, air-quality, and weather data.

## Language

**Portfolio program**:
The overall household data project built to showcase the user's skills to colleagues, covering ingestion, warehouse, dbt, and charts.
_Avoid_: The talk project, the demo

**Portfolio monorepo**:
The public, data-free repository holding all portfolio program work, segmented by tooling/concern.
_Avoid_: Talk repo

**Talk repo**:
A separate public repository for a meetup talk, holding a dbt slice and data extract harvested from the portfolio program.
_Avoid_: Portfolio monorepo

**Landing zone**:
The S3 location where every source's raw files arrive, unchanged, before being loaded into Snowflake.
_Avoid_: Staging (reserved for dbt staging models)

**Polled source**:
A source whose API returns only current values, so history accumulates only by polling it on a schedule (Airthings); owned by a Lambda.
_Avoid_: Device ingestion, real-time source

**History source**:
A source whose API serves past data for a requested time range, so it can be pulled in batches and backfilled (Emporia, Open-Meteo); owned by Prefect.
_Avoid_: Batch source, ETL

**Environment**:
One of three tiers the project runs in: local-dev (a developer's personal schema), qa (validates that infrastructure and code still work), and prod (the only tier with scheduled, automated activity).
_Avoid_: Dev (as a shared tier; the portfolio has none), stage

**Gold record**:
The raw data in prod, the only authoritative copy of source data, which dbt reads in every environment.
_Avoid_: QA data, dev data, golden dataset

**Deploy trigger**:
The event of code or infrastructure being merged into qa or prod, which applies infrastructure and then runs dbt in that environment.
_Avoid_: Release, CI run

**Data trigger**:
The event of fresh source data having landed, which should start a dbt run on the new data.
_Avoid_: Schedule (a schedule is time-based, not data-based)

**Run log**:
The record of success/failure events from every process, collected as JSON in the landing zone and loaded into Snowflake.
_Avoid_: Audit log, alerts

**Daily digest**:
The once-a-day email summarizing the run log's successes and failures.
_Avoid_: Alert (an alert is a single failure notification)

**Backfill**:
A deliberate pull of a history source over a past date range.
_Avoid_: Reload, catch-up

**Charts experiment**:
The comparison of dbt Charts built from one plain-English spec three ways: AI unaided (V1), AI with refinement rounds (V2), and one hour by hand (V3).
_Avoid_: Dashboard project

**Daily analytical grain**:
The day-level resolution of an analytical result, not necessarily the resolution of its source observations.
_Avoid_: Raw data grain when referring only to daily outputs
