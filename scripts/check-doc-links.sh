#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docs_to_check=(
  "AGENTS.md"
  "README.md"
  "CONTRIBUTING.md"
  "ATTRIBUTION.md"
  "docs/README.md"
  "docs/FORK.md"
  "docs/CURSOR.md"
  "docs/macOS-26.md"
  "docs/BENCHMARK.md"
  "benchmarks/README.md"
)

failed=0

resolve_link() {
  local base_file="$1"
  local link="$2"
  local base_dir
  base_dir="$(cd "$(dirname "${repo_root}/${base_file}")" && pwd)"

  link="${link%%#*}"
  link="${link%%\?*}"

  if [[ -z "${link}" ]]; then
    return 0
  fi

  if [[ "${link}" =~ ^https?:// ]] || [[ "${link}" =~ ^mailto: ]]; then
    return 0
  fi

  local target
  if [[ "${link}" == /* ]]; then
    target="${repo_root}${link}"
  else
    target="${base_dir}/${link}"
  fi

  if [[ ! -e "${target}" ]]; then
    echo "Broken link in ${base_file}: ${link} (resolved ${target})"
    failed=1
  fi
}

for doc in "${docs_to_check[@]}"; do
  path="${repo_root}/${doc}"
  if [[ ! -f "${path}" ]]; then
    echo "Missing doc for link check: ${doc}"
    failed=1
    continue
  fi

  while IFS= read -r link; do
    resolve_link "${doc}" "${link}"
  done < <(grep -oE '\]\([^)]+\)' "${path}" | sed -E 's/^\]\(//;s/\)$//' || true)
done

if [[ "${failed}" -ne 0 ]]; then
  exit 1
fi

echo "Documentation link check passed"
