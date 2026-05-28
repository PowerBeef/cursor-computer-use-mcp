<!-- Scope Cursor-specific commits as cursor: / macOS26: per AGENTS.md. -->

## Summary

- What changed and why.

## Test plan

- [ ] `swift build && swift test`
- [ ] `./scripts/run-tool-smoke-tests.sh` (if behaviour changes)
- [ ] `make check-docs`
- [ ] `make check-repo`
- [ ] `node --test scripts/install-config-helper.test.mjs` (if install scripts changed)
- [ ] `BENCHMARK_TRIALS=1 CAIRN_DISABLE_APP_AGENT_PROXY=1 npm run benchmark` (if MCP surface changed)

## Doc / history sync

- [ ] Updated relevant `docs/` files (canonical: `docs/CURSOR.md`, `docs/ARCHITECTURE.md`).
- [ ] Added a `docs/histories/YYYY-MM/<slug>.md` entry when [HISTORY_GUIDE.md](../docs/HISTORY_GUIDE.md) calls for it.
- [ ] Skill / plugin manifests stay in sync with `CairnVersion.swift`.

## Notes for reviewers

- Permissions, MCP behaviour, or Composer workflow changes worth calling out.
