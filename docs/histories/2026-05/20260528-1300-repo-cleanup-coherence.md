# Repo cleanup and coherence

## Summary

Brought the repo into compliance with `scripts/check-repo-hygiene.sh`, removed stale tracked artifacts, fixed a stale architecture note, and dropped one unnecessary Swift annotation. Supply-chain hygiene (`dependency-review-config.yml`, `supply-chain-security.yml`) is deferred.

## Changes

- **Tracked artifacts**: `git rm` the five files under `artifacts/tool-comparisons/20260417-focus-behavior/`. They contradicted `artifacts/README.md` (everything but the README is gitignored) and no docs reference them.
- **Swift warning**: Dropped the unused `nonisolated(unsafe)` on `SoftwareCursorGlyphRenderer.referenceImage`; `NSImage?` is already `Sendable`.
- **Docs**: Updated `docs/ARCHITECTURE.md` so the screenshot bullet reflects the resource-URI default (`computer-use://screenshot/latest`) with `inline_image: true` as the opt-in.
- **Root hygiene**: Added `.editorconfig` (UTF-8 / LF / 2-space, 4-space for Swift/Go/Python, tab for Makefiles) and `.markdownlint.json` (disable `MD013`/`MD033`/`MD041`/`MD040`, `MD024` siblings-only).
- **`.github/` templates**: Added `PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/bug_report.yml`, `ISSUE_TEMPLATE/feature_request.yml`, and `ISSUE_TEMPLATE/config.yml`. PR template mirrors the `make check-docs` / `make check-repo` workflow from `CONTRIBUTING.md`; bug template asks for `open-computer-use doctor --cursor` output.
- **Workflows**: Added `.github/workflows/docs-check.yml` (runs `make check-docs` when docs change) and `.github/workflows/repo-hygiene.yml` (runs the hygiene + action-pinning checks plus `bash -n` / `node --check` on scripts). All `uses:` references pinned by SHA to satisfy `scripts/check-action-pinning.sh`.
- **Hygiene checker**: Removed `.github/workflows/supply-chain-security.yml` and `.github/dependency-review-config.yml` from `required_files` in `scripts/check-repo-hygiene.sh`; reintroducing them is a deliberate follow-up.

## Verification

```bash
swift build && swift test
./scripts/run-tool-smoke-tests.sh
make check-docs
make check-repo
node --test scripts/install-config-helper.test.mjs
npm run package:skill
```

## Follow-ups

- Add `dependency-review-config.yml` and a `supply-chain-security.yml` workflow once we settle on a supply-chain policy; re-add them to `check-repo-hygiene.sh` at the same time.
