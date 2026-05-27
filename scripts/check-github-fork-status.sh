#!/usr/bin/env bash
# Exit 0 when PowerBeef/cursor-computer-use-mcp is no longer a GitHub fork.
set -euo pipefail

repo="${1:-PowerBeef/cursor-computer-use-mcp}"
is_fork="$(gh repo view "$repo" --json isFork --jq '.isFork')"

if [[ "$is_fork" == "false" ]]; then
  echo "OK: $repo is a standalone repository (not a fork)."
  gh repo view "$repo" --json name,parent,isFork
  exit 0
fi

parent="$(gh repo view "$repo" --json parent --jq '.parent.full_name // .parent.nameWithOwner // "unknown"')"
echo "Still a fork of: $parent"
echo "Detach via: https://github.com/PowerBeef/cursor-computer-use-mcp/settings (Danger Zone → Leave fork network)"
echo "See docs/DETACH_FORK.md"
exit 1
