# Cairn — rebrand decision (2026-05-28)

> *Cairn — native macOS control for AI agents through MCP.*

This document records the rebrand from the working name **Cursor Computer Use / open-computer-use** to **Cairn**, the final naming shape, and the migration / followup surface.

## Why rebrand

The previous identity carried three problems:

1. **Generic + colliding name.** "Computer Use" is descriptive, not distinctive. Searching for "computer-use" surfaces unrelated tools and Anthropic's own product naming.
2. **Mixed signals.** "Cursor Computer Use" baked the IDE name into the binary, the MCP server key (`cursor-computer-use`), and the npm package. That made the project look Cursor-locked even though the MCP server runs against any host that speaks stdio MCP.
3. **Upstream confusion.** The macOS-native code lives in **this** fork; the original `iFurySt/open-codex-computer-use` ships Codex/Linux/Windows variants. Sharing the binary name `open-computer-use` made it impossible to tell which project's docs / installer / `.app` you were touching.

"Cairn" — a small stack of stones marking the path — is short, pronounceable, distinctive on npm/GitHub, and metaphorically right: the MCP server marks the trail an AI agent should follow through a real macOS UI.

## Final shape

| Surface | Value |
|---|---|
| Brand | **Cairn** |
| Tagline | *Cairn — native macOS control for AI agents through MCP.* |
| GitHub repository | `PowerBeef/cairn-computer-use` |
| npm package | `cairn-computer-use` (binary `cairn`, alias `cairn-mcp`) |
| CLI binary | `cairn` |
| MCP server key | `cairn` |
| Resource URI scheme | `cairn://screenshot/latest` |
| Env var prefix | `CAIRN_…` (was `OPEN_COMPUTER_USE_…`) |
| Swift package | `CairnKit` (library) + `Cairn` (executable) |
| macOS bundle | `Cairn.app`, bundle id `com.powerbeef.cairn` (`com.powerbeef.cairn.dev` for debug builds) |
| Cursor plugin id | `cairn` under `plugins/cairn/` |
| Cursor skill | `skills/cairn/SKILL.md` |
| Project domain | `cairnmcp.com` (reserved, not yet registered) |

The npm package keeps `cairn-computer-use` (rather than the bare `cairn`, which is taken on npm) so the global install command stays concrete: `npm install -g cairn-computer-use` installs the `cairn` binary. This mirrors the `kubectl` / `kubernetes-client` pattern.

## What changed in this commit series

### Code

- `packages/OpenComputerUseKit/` → `packages/CairnKit/`
- `apps/OpenComputerUse/` → `apps/Cairn/`, similarly `*Fixture` and `*SmokeSuite`
- Swift package targets, products, and module names in `Package.swift`
- Public Swift symbols: `ComputerUseService` → `CairnService`, `ComputerUsePolicy` → `CairnPolicy`, `ComputerUseToolDispatcher` → `CairnToolDispatcher`, `ComputerUseError` → `CairnError`, `OpenComputerUseCLI*` → `CairnCLI*`, `openComputerUseVersion` → `cairnVersion`, notification name → `com.powerbeef.cairn.turn-ended`, etc.
- Build script `scripts/build-open-computer-use-app.sh` → `scripts/build-cairn-app.sh` (writes `Cairn.app` with bundle id `com.powerbeef.cairn`)
- macOS icon asset: `assets/app-icons/open-computer-use-1024.png` → `assets/app-icons/cairn-1024.png`
- Policy file lookup paths: `~/.cursor/computer-use-policy.json` → `~/.cursor/cairn-policy.json`

### Configs and plugin

- `plugins/cursor-computer-use/` → `plugins/cairn/` (Cursor plugin manifest, `.mcp.json`, README, embedded skill)
- `skills/cursor-computer-use/` → `skills/cairn/`
- `.cursor/computer-use-policy.example.json` → `.cursor/cairn-policy.example.json`
- `.cursor/mcp.json` and `.cursor/hooks/turn-ended.example.json` now reference the `cairn` server / `cairn turn-ended` command

### Scripts, workflows, benchmarks

- `scripts/install-cursor-mcp.sh`, `scripts/install-config-helper.{mjs,test.mjs}` — server name and binary name updated
- `scripts/run-tool-smoke-tests.sh` and the npm build scripts — updated to the new binary and `.app` bundle name; npm metadata points at `PowerBeef/cairn-computer-use`
- `.github/workflows/*.yml`, `.github/ISSUE_TEMPLATE/*`, `.github/PULL_REQUEST_TEMPLATE.md`
- `benchmarks/lib/*.ts`, `benchmarks/tasks/*.ts`, `benchmarks/run.ts`, `benchmarks/calibrate.ts`, `benchmarks/README.md`
- Root `package.json` name → `cairn-computer-use-repo-tools`

### Docs

- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `ATTRIBUTION.md`
- All `docs/*.md` (except `docs/histories/**` and `docs/references/**`, which are preserved as immutable historical / upstream-research records)

## What was preserved (out of scope)

These surfaces still carry the historical `OpenComputerUse` / `open-computer-use` naming because they are upstream-tracked or immutable:

- `docs/histories/**` — change log; the new history entry for this rebrand sits alongside.
- `docs/references/codex-computer-use-reverse-engineering/**` — research on upstream.
- `docs/exec-plans/completed/**` — completed plans.
- `apps/OpenComputerUseLinux/`, `apps/OpenComputerUseWindows/` — Go runtime ports.
- `plugins/open-computer-use/` — upstream Codex plugin (separate from our Cursor plugin).
- `scripts/install-{codex,gemini,opencode}-mcp.sh`, `scripts/build-open-computer-use-{linux,windows}.sh`, `scripts/computer-use-cli/`, `scripts/cursor-motion-re/` — upstream tools and research.
- `experiments/**` — research code.

The npm cross-platform package keeps the upstream Linux/Windows binary name (`open-computer-use`) inside the runtime archive so the upstream rebases stay trivial; only the macOS flagship is the rebranded `cairn`. Renaming the cross-platform binary is a deferred decision.

## Permissions impact

Bundle id changed from `com.ifuryst.opencomputeruse` (upstream) → `com.powerbeef.cairn`. macOS TCC keys grants by bundle id, so any prior install of `Open Computer Use.app` will have **separate** Accessibility / Screen Recording grants from `Cairn.app`. Run `cairn doctor` after the first install; if prompted, grant both permissions to `Cairn.app` (you can remove the old `Open Computer Use.app` grants under  → System Settings → Privacy & Security).

## Followups (not in this commit series)

1. **Local working directory rename.** This workspace is still `cursor_computer_use/` on disk. Rename after closing the current Cursor session so the editor doesn't lose its workspace context. Suggested: `~/Coding_Projects/cairn-computer-use/`.
2. **GitHub repository rename.** From `PowerBeef/cursor-computer-use-mcp` (or wherever it currently lives) to `PowerBeef/cairn-computer-use`. Use `gh repo rename`; GitHub preserves issue / PR URLs and redirects clones.
3. **npm publish.** Register `cairn-computer-use` on npm, set up trusted publishing from the existing release workflow, and tag a `0.2.0` release that ships under the new name. The old `open-codex-computer-use-mcp` alias is dropped from the bin map in this commit; if you need a deprecation alias, add a new commit that re-introduces it pointing at the same launcher.
4. **Domain registration.** Reserve `cairnmcp.com` and wire it to the GitHub Pages / docs site once a marketing surface exists. Until then, the canonical URL is the GitHub repo.
5. **macOS app signing.** `com.powerbeef.cairn` needs a Developer ID-signed build before TestFlight-style distribution. Today the build script falls back to ad-hoc signing.
6. **Linux / Windows rebrand decision.** If we want a single binary name across platforms, fork the upstream Go ports here and rename them too. Until then, only macOS is `cairn`.
