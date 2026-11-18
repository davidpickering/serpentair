#!/usr/bin/env bash
# Run Terraform locally against one root, with the right credentials for that root.
#
#   infra/tf.sh bootstrap plan
#   infra/tf.sh prod plan
#   infra/tf.sh prod apply
#
# Credentials come from the git-ignored .env (see .env.example) and the AWS CLI profile:
#   - bootstrap   runs as YOU (your Snowflake user, ACCOUNTADMIN). It creates the CI user,
#                 so it can't run as the CI user.
#   - envs/<name> runs as the Snowflake CI service user, exactly as GitHub Actions will (#9),
#                 so a local apply also proves the CI user has the permissions it needs.
# CI sets the same SNOWFLAKE_* variables from GitHub environment secrets instead of .env.
set -euo pipefail

usage() { echo "usage: infra/tf.sh <bootstrap|prod|qa> <terraform args...>" >&2; exit 2; }
[[ $# -ge 2 ]] || usage

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$1"; shift

case "$target" in
  bootstrap) root_dir="$repo_root/infra/bootstrap" ;;
  prod|qa)   root_dir="$repo_root/infra/envs/$target" ;;
  *)         usage ;;
esac

# Read only the keys we need from .env, literally (no `source`: other values may contain `$` etc.).
env_file="$repo_root/.env"
[[ -f "$env_file" ]] || { echo "missing $env_file (copy .env.example)" >&2; exit 1; }
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  [[ "$line" =~ ^(SNOWFLAKE_[A-Z_]+)=(.*)$ ]] || continue
  key="${BASH_REMATCH[1]}"; value="${BASH_REMATCH[2]}"
  # Undo the quotes the setup wizard writes (KEY='value') or a plain "value".
  if [[ "$value" =~ ^\'(.*)\'$ || "$value" =~ ^\"(.*)\"$ ]]; then value="${BASH_REMATCH[1]}"; fi
  export "$key=$value"
done < "$env_file"

require() { for v in "$@"; do [[ -n "${!v:-}" ]] || { echo "set $v in .env" >&2; exit 1; }; done; }
require SNOWFLAKE_ORGANIZATION_NAME SNOWFLAKE_ACCOUNT_NAME SNOWFLAKE_ADMIN_USER

if [[ "$target" == "bootstrap" ]]; then
  require SNOWFLAKE_ADMIN_PRIVATE_KEY_PATH
  export SNOWFLAKE_USER="$SNOWFLAKE_ADMIN_USER"
  key_path="$SNOWFLAKE_ADMIN_PRIVATE_KEY_PATH"
else
  require SNOWFLAKE_CI_USER SNOWFLAKE_CI_PRIVATE_KEY_PATH
  export SNOWFLAKE_USER="$SNOWFLAKE_CI_USER"
  key_path="$SNOWFLAKE_CI_PRIVATE_KEY_PATH"
fi
key_path="${key_path/#\~/$HOME}"
[[ -f "$key_path" ]] || { echo "private key not found: $key_path" >&2; exit 1; }

export SNOWFLAKE_AUTHENTICATOR=SNOWFLAKE_JWT
SNOWFLAKE_PRIVATE_KEY="$(cat "$key_path")"
export SNOWFLAKE_PRIVATE_KEY
export TF_VAR_snowflake_admin_user="$SNOWFLAKE_ADMIN_USER"
export AWS_PROFILE="${AWS_PROFILE:-serpentair}"

# Terraform from PATH, or winget's install location on Windows if the shell predates the install.
tf="$(command -v terraform || true)"
if [[ -z "$tf" && -n "${LOCALAPPDATA:-}" ]]; then
  winget_dir="$(cygpath -u "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")/Microsoft/WinGet/Packages"
  tf="$(ls "$winget_dir"/Hashicorp.Terraform_*/terraform.exe 2>/dev/null | head -1 || true)"
fi
[[ -n "$tf" ]] || { echo "terraform not found; install it (winget install Hashicorp.Terraform)" >&2; exit 1; }

exec "$tf" -chdir="$root_dir" "$@"
