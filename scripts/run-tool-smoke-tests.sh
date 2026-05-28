#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${repo_root}"

swift build
CAIRN_VISUAL_CURSOR=0 ".build/debug/CairnSmokeSuite"
".build/debug/CairnSmokeSuite" --cursor-idle-only
