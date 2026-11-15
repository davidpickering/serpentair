# Raw data exists only in prod; every environment's dbt reads it

Authoritative raw data (the gold record) is collected only in prod, and dbt in local-dev, qa, and prod all read prod's raw data while building into their own schemas. This mirrors the user's workplace, keeps one true copy of household data, and makes prod the only environment with scheduled, automated activity. Qa still deploys the full ingestion stack with schedules off and smoke-runs each ingester on merge into a disposable qa raw area that dbt never reads, so broken ingestion is caught before prod.

## Considered Options

- **Full data stack per environment:** each environment collects its own raw data. Rejected: duplicates the gold record, and qa data would drift from prod.
- **Zero-copy clone of prod raw data into qa:** a reasonable later addition, not needed while dbt can read prod directly.

## Consequences

- dbt sources point at prod raw data in every environment, so local-dev and qa need read-only access to it.
- A qa ingestion smoke run proves the code and infrastructure work, not that its data is correct; data correctness is judged in prod.
