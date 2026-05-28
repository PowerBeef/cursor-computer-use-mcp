# Verification fixes rollout

## Summary

Addressed findings from the post-overhaul verification pass: install helper ESM crash, live AX focus for `type_text`, project-root policy/doctor paths, SoM/OCR coordinate scaling, snapshot cache and screenshot resource lifecycle, benchmark resource reads, plugin-bundled skill, docs, and minimal GitHub CI.

## Changes

- **Install helper**: `serverName` in post-install checklist, ESM `execFileSync`, checklist on idempotent reinstall, `OPEN_COMPUTER_USE_PROJECT_ROOT` in Cursor MCP `env`, Node tests.
- **ComputerUseService**: Live focused-element resolution, post-click text focus promotion, session-wide `resetAllSessionCaches()`, `SnapshotAXCache` store on refresh.
- **Presentation**: SoM boxes scaled by capture scale; OCR frames converted to window coordinates.
- **MCP**: Turn-ended clears screenshot resource store; benchmark reads resource when inline image absent.
- **App agent**: Turn-ended resets session caches and AX cache (mirrors stdio MCP).
- **Plugin**: Self-contained skill under `plugins/cursor-computer-use/skills/`, version `0.1.51`.
- **CI**: `.github/workflows/ci.yml` on `macos-26`.

## Verification

```bash
swift build && swift test
node --test scripts/install-config-helper.test.mjs
./scripts/run-tool-smoke-tests.sh
make check-docs
npm run package:skill
```
