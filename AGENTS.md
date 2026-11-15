# AGENTS.md

## Start here

- **`BRIEF.md`**: settled decisions and account findings. Read it before starting any ticket.
- **AWS work** (CLI, `aws-mcp`, Terraform for AWS): read `docs/agents/aws.md` first. Agents are read-only in AWS; changes go through Terraform.
- **Credentials** live in the git-ignored `.env`; `.env.example` lists every key and where it comes from. Read key names from `.env.example`, not `.env`.
- Run shell commands through bash where possible.

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues on `davidpickering/serpentair`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
