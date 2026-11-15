# Snowflake as the warehouse, and talks get their own repo

The portfolio uses the user's own Snowflake account (trial converted to on-demand) as its only cloud data warehouse, because the user's workplace runs on Snowflake and the portfolio exists to show work-relevant skills; it also serves the dbt v2 managed-path demo in talks. Talk material lives in a separate public talk repo with a reviewed DuckDB extract, so this monorepo keeps a strict no-data rule and is not constrained by a talk's dbt Core v1.x compatibility.

## Considered Options

- **BigQuery:** ongoing free allowance and v2 support, and the original talk choice; rejected because it adds a warehouse the user's workplace doesn't use.
- **RDS/Aurora Postgres:** simplest database, but not listed as a dbt v2 adapter (as of 2026-11) and the AWS free plan's credits expire after about 6 months.
- **Redshift Serverless:** v2-supported, but overkill and pay-per-query with a poor user experience.
- **Talk as a `talk/` segment in this repo:** rejected because it would be the one place this repo holds data.

## Consequences

- Costs money beyond a trial. Planning ceiling is $15/month, guarded by a resource monitor that suspends the warehouse, 60-second auto-suspend, X-Small only, and a daily dbt job.
- max query timeout set to one hour
- AWS hosts the S3 landing zone and the Airthings polling Lambda, not the warehouse.
