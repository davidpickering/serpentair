# infra

Terraform for everything the portfolio runs on: AWS (state backend now; landing zone, Lambda and the rest from #5) and Snowflake.

## Layout

```
infra/
├── tf.sh                       run Terraform against one root with the right credentials
├── bootstrap/                  applied once, by hand, as the human admin
│   ├── state_bucket.tf         S3 bucket for every root's state (versioned, encrypted, TLS-only)
│   ├── snowflake_ci_user.tf    SVC_TERRAFORM_CI: key-pair service user that runs envs/*
│   └── keys/*.pub              public keys (safe to commit; private keys never are)
├── modules/                    the shared spec: qa and prod are built from the same modules
│   ├── snowflake_warehouse/    X-Small, 60 s auto-suspend, 1 h query timeout, on a resource monitor
│   └── snowflake_environment/  database, RAW + ANALYTICS schemas, loader/raw-reader/transformer roles
└── envs/
    └── prod/                   own state; applied by CI from #9 on
        ├── cost_guard.tf       resource monitor: 6 credits/month, notify 50/75/90%, suspend at 100%
        ├── main.tf             PROD_WH + SERPENTAIR_PROD
        └── local_dev.tf        SERPENTAIR_DEV + DEV_WH + DEVELOPER (local-dev has no root of its own)
```

## What prod creates

| Object | Purpose |
| --- | --- |
| `SERPENTAIR_MONTHLY` | Resource monitor shared by every Terraform-managed warehouse. 6 credits/month (≈ $12 at $2.00/credit), emails at 50/75/90 %, suspends at 100 %, cancels running queries at 110 %. |
| `PROD_WH`, `DEV_WH` | X-Small warehouses on that monitor. |
| `SERPENTAIR_PROD.RAW` | The **gold record**: landed source data, loaded only in prod (ADR 0002). |
| `SERPENTAIR_PROD.ANALYTICS` | Prod dbt models. |
| `SERPENTAIR_DEV` | Transient database for local-dev personal schemas (`dbt_<name>`). |

Roles (all roll up to `SYSADMIN`):

```
PROD_LOADER        writes PROD RAW
PROD_RAW_READER    reads PROD RAW ──┬──▶ PROD_TRANSFORMER   builds PROD ANALYTICS on PROD_WH
                                    └──▶ DEVELOPER          builds SERPENTAIR_DEV on DEV_WH
                                         (QA_TRANSFORMER joins here in #10)
```

### Who runs what, as which role

`infra/tf.sh` reads the Snowflake settings from `.env` and picks the identity:

- `infra/tf.sh bootstrap …` runs as **you** (`SNOWFLAKE_ADMIN_USER`, `ACCOUNTADMIN`). It creates the CI user, so it can't run as that user.
- `infra/tf.sh prod …` runs as **`SVC_TERRAFORM_CI`**, the same identity GitHub Actions will use (#9). That user holds `SYSADMIN`, `SECURITYADMIN` and `ACCOUNTADMIN`, but its secondary roles are off. Each resource uses one provider alias: `SYSADMIN` for databases and schemas, `SECURITYADMIN` for roles and grants, and `ACCOUNTADMIN` only for the resource monitor and warehouses. Snowflake reserves attaching a monitor to a warehouse for `ACCOUNTADMIN`.

AWS credentials come from the `serpentair` CLI profile (`aws login --profile serpentair`).

## Day to day

```bash
infra/tf.sh prod init     # once per clone
infra/tf.sh prod plan     # should say "No changes" when code and Snowflake agree
infra/tf.sh prod apply
```

From #9 on, prod is applied by CI on merge to `prod`; run `plan` locally, not `apply`.

## One-time bootstrap

Done once, in order. `scripts/setup-snowflake.sh` walks through the same steps interactively.

1. **Sign up for Snowflake:** Standard edition, AWS, US East (Ohio). Verify your email in Snowsight (profile menu) so the resource monitor can email you.
2. **Make two key pairs** (unencrypted PKCS#8, outside the repo):
   ```bash
   mkdir -p ~/.snowflake/keys && cd ~/.snowflake/keys
   openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out admin.p8
   openssl rsa -in admin.p8 -pubout -out admin.pub
   openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out svc_terraform_ci.p8
   openssl rsa -in svc_terraform_ci.p8 -pubout -out svc_terraform_ci.pub
   cp svc_terraform_ci.pub <repo>/infra/bootstrap/keys/
   ```
3. **Give your own user the admin public key** (Snowsight worksheet, as `ACCOUNTADMIN`):
   `ALTER USER <you> SET RSA_PUBLIC_KEY = '<admin.pub body without the BEGIN/END lines>';`
4. **Fill in the Snowflake section of `.env`** (see `.env.example`).
5. **Apply bootstrap on local state, then move the state into the bucket it created:**
   ```bash
   aws login --profile serpentair
   printf 'terraform {\n  backend "local" {}\n}\n' > infra/bootstrap/backend_override.tf
   infra/tf.sh bootstrap init
   infra/tf.sh bootstrap apply
   rm infra/bootstrap/backend_override.tf
   infra/tf.sh bootstrap init -migrate-state   # answer "yes"
   infra/tf.sh bootstrap state list            # resources listed = state now read from S3
   rm infra/bootstrap/terraform.tfstate*       # only after the line above works
   ```
   The override file exists because the bucket that should hold this root's state doesn't exist until this root creates it. `*_override.tf` files are git-ignored.
6. **Apply prod:** `infra/tf.sh prod init && infra/tf.sh prod apply`, then `infra/tf.sh prod plan` must report no changes.
7. **Remove unmonitored warehouses.** New accounts come with `COMPUTE_WH` (and sometimes others) that no resource monitor covers. In Snowsight: `SHOW WAREHOUSES;` then `DROP WAREHOUSE <name>;` for any that aren't `PROD_WH` or `DEV_WH`. Use `DEV_WH` for worksheets.

## Not here yet

- **AWS CI role.** The plan was GitHub OIDC federation, but this AWS project's managed SCP denies `iam:*Provider*`, so the OIDC identity provider can't be created. Decided in #9 (see BRIEF.md → "Step 2 findings").
- AWS resources for ingestion (#5), qa root (#10), dbt platform service user (#8).
