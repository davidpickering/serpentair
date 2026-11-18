#!/usr/bin/env bash
# `terraform validate` every root (bootstrap and each env). Run by the pre-commit hook and, in #9, CI.
# Needs no credentials: a root never initialised here gets `init -backend=false`, which installs
# providers and modules without touching remote state.
set -euo pipefail

command -v terraform >/dev/null || {
  echo "terraform not on PATH (winget installs it under %LOCALAPPDATA%\\Microsoft\\WinGet\\Packages\\Hashicorp.Terraform_*)" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
status=0
for root in "$repo_root"/infra/bootstrap "$repo_root"/infra/envs/*/; do
  root="${root%/}"
  compgen -G "$root/*.tf" >/dev/null || continue
  name="${root#"$repo_root"/}"
  if [[ ! -d "$root/.terraform" ]]; then
    terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly >/dev/null
  fi
  if out="$(terraform -chdir="$root" validate -no-color 2>&1)"; then
    echo "ok    $name"
  else
    echo "FAIL  $name"; echo "$out" | sed 's/^/      /'; status=1
  fi
done
exit "$status"
