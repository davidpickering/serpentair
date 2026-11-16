# ingestion

Code that pulls source data into the S3 landing zone, unchanged, as JSON:

- **Polled sources** (Airthings): a scheduled Lambda (#5).
- **History sources** (Emporia, Open-Meteo): Prefect flows on Prefect Cloud (#6, #7).

The infrastructure these run on is in `infra/`.
