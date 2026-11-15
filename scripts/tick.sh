#!/usr/bin/env bash
# Tick one checklist item on a GitHub issue, optionally appending a note.
#   scripts/tick.sh <issue> "<start of the item's text>" ["note appended in parentheses"] [--dry-run]
# Fails (exit 1) unless exactly one UNticked item starts with that text, so a typo never passes silently.
set -euo pipefail

dry=0; args=()
for a in "$@"; do [[ "$a" == "--dry-run" ]] && dry=1 || args+=("$a"); done
[[ ${#args[@]} -ge 2 ]] || { echo "usage: $0 <issue> \"<item text prefix>\" [\"note\"] [--dry-run]" >&2; exit 2; }
issue="${args[0]}"; prefix="${args[1]}"; note="${args[2]:-}"

body=$(gh issue view "$issue" --json body --jq .body)
new=$(PREFIX="$prefix" NOTE="$note" python -c '
import os, sys
body, prefix, note = sys.stdin.read(), os.environ["PREFIX"], os.environ["NOTE"]
lines = body.split("\n")
hits = [i for i, l in enumerate(lines) if l.startswith("- [ ] " + prefix)]
if len(hits) != 1:
    done = [l for l in lines if l.startswith("- [x] " + prefix)]
    why = "already ticked" if done and not hits else f"{len(hits)} unticked matches"
    sys.exit(f"tick: expected exactly 1 unticked item starting with {prefix!r}; found {why}")
i = hits[0]
lines[i] = "- [x] " + lines[i][6:] + (f" ({note})" if note else "")
print(lines[i], file=sys.stderr)
sys.stdout.write("\n".join(lines))
' <<< "$body")

if (( dry )); then echo "dry run: issue #$issue not changed"; exit 0; fi
printf '%s' "$new" | gh issue edit "$issue" --body-file - >/dev/null
echo "ticked on #$issue"
