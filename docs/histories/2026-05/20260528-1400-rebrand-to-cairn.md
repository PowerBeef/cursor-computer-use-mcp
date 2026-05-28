# 2026-05-28 14:00 — Rebrand to Cairn

## Why

The previous identity (working name *Cursor Computer Use*, binary `open-computer-use`, MCP server key `cursor-computer-use`) had three problems: descriptive-not-distinctive name, `Cursor` baked into identifiers that should be host-agnostic, and shared binary name with the upstream `iFurySt/open-codex-computer-use` project. We picked **Cairn** — short, distinctive, available on npm/GitHub — and rebranded the Cursor-flagship surface in one commit series.

Decision doc and migration notes: [docs/REBRAND.md](../../REBRAND.md).

## What changed

### Swift package and macOS app

- `packages/OpenComputerUseKit/` → `packages/CairnKit/` (Sources/, Tests/, target name)
- `apps/OpenComputerUse/`, `apps/OpenComputerUseFixture/`, `apps/OpenComputerUseSmokeSuite/` → `apps/Cairn/`, `apps/CairnFixture/`, `apps/CairnSmokeSuite/`
- `Package.swift`: product/target names updated (`Cairn`, `CairnKit`, `CairnFixture`, `CairnSmokeSuite`, `CairnKitTests`)
- Public Swift symbols: `ComputerUseService` → `CairnService`, `ComputerUsePolicy` → `CairnPolicy`, `ComputerUseToolDispatcher` → `CairnToolDispatcher`, `ComputerUseError` → `CairnError`, `OpenComputerUseCLICommand` → `CairnCLICommand`, `OpenComputerUseCallSpec` → `CairnCallSpec`, `openComputerUseVersion` → `cairnVersion`, `openComputerUseTurnEndedNotificationName` → `cairnTurnEndedNotificationName`, etc.
- Renamed Swift files: `OpenComputerUseVersion.swift` → `CairnVersion.swift`, `OpenComputerUseCLI.swift` → `CairnCLI.swift`, `ComputerUseService.swift` → `CairnService.swift`, `ComputerUsePolicy.swift` → `CairnPolicy.swift`, `ComputerUseToolDispatcher.swift` → `CairnToolDispatcher.swift`, `OpenComputerUseKitTests.swift` → `CairnKitTests.swift`, `OpenComputerUseMain.swift` → `CairnMain.swift`
- macOS bundle: `Open Computer Use.app` → `Cairn.app`, bundle id `com.ifuryst.opencomputeruse` → `com.powerbeef.cairn`, executable name `OpenComputerUse` → `Cairn`, dev variant `com.powerbeef.cairn.dev`, Info.plist key `OpenComputerUseAppVariant` → `CairnAppVariant`
- Notification name: `com.ifuryst.opencomputeruse.turn-ended` → `com.powerbeef.cairn.turn-ended`
- Fixture bundle id: `dev.opencodex.opencomputeruse.fixture` → `com.powerbeef.cairn.fixture`
- Build script: `scripts/build-open-computer-use-app.sh` → `scripts/build-cairn-app.sh`; version source switched from upstream Codex plugin manifest to `plugins/cairn/.cursor-plugin/plugin.json`
- Icon asset: `assets/app-icons/open-computer-use-1024.png` → `cairn-1024.png`

### CLI / MCP / env vars

- CLI binary: `open-computer-use` → `cairn` (npm bin map + all references in active scripts and Swift help text)
- MCP server key: `cursor-computer-use` → `cairn`
- Resource URI: `computer-use://screenshot/latest` → `cairn://screenshot/latest`
- Env var prefix: `OPEN_COMPUTER_USE_*` → `CAIRN_*` (codesigning vars, visual cursor controls, OCR default, etc.)
- Policy file: `.cursor/computer-use-policy.json` → `.cursor/cairn-policy.json` (and `.example.json`); `CairnPolicy` now reads the new path

### Cursor plugin and skill

- `plugins/cursor-computer-use/` → `plugins/cairn/` (including nested `skills/cursor-computer-use/` → `skills/cairn/`)
- `skills/cursor-computer-use/` → `skills/cairn/`
- Manifests and `.mcp.json` updated to use server key `cairn`, GitHub URL `PowerBeef/cairn-computer-use`
- Plugin `displayName` → `Cairn`, longDescription updated with the new tagline

### `.cursor/` configs

- `.cursor/computer-use-policy.example.json` → `.cursor/cairn-policy.example.json`
- `.cursor/mcp.json` template uses `cairn` server with `cairn mcp`
- `.cursor/hooks/turn-ended.example.json` uses `cairn turn-ended`

### Scripts, workflows, benchmarks

- `scripts/install-cursor-mcp.sh`, `scripts/install-config-helper.{mjs,test.mjs}`: server name + command name + post-install checklist updated; tests still pass
- `scripts/run-tool-smoke-tests.sh`: binary path → `.build/debug/CairnSmokeSuite`, env var `CAIRN_VISUAL_CURSOR`
- `scripts/npm/build-packages.mjs`: `appBundleName = "Cairn.app"`, executable name `Cairn`, npm package set `cairn-computer-use` + `cairn-mcp` (dropped bare `cairn` since it's taken on npm and dropped `open-codex-computer-use-mcp` alias from new builds), homepage/repo URLs → PowerBeef/cairn-computer-use
- `scripts/install-codex-plugin.sh`: build script path updated to `build-cairn-app.sh`
- `.github/workflows/release.yml`: signing step renamed; secret env vars already on the `CAIRN_*` prefix
- `.github/workflows/{ci,docs-check,repo-hygiene}.yml`, `.github/ISSUE_TEMPLATE/*`, `.github/PULL_REQUEST_TEMPLATE.md`: updated where applicable
- `benchmarks/lib/*.ts`, `benchmarks/tasks/*.ts`, `benchmarks/run.ts`, `benchmarks/calibrate.ts`, `benchmarks/README.md`, `composer-prompts.md`, `composer-rubric.md`, `results/sample-report.md`
- Root `package.json` name → `cairn-computer-use-repo-tools`
- `Makefile`: `app` target now invokes `build-cairn-app.sh`

### Docs

- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `ATTRIBUTION.md`
- `docs/{CURSOR,ARCHITECTURE,FORK,macOS-26,SECURITY,BENCHMARK,RELIABILITY,REPO_COLLAB_GUIDE,HISTORY_GUIDE,CICD}.md`
- `docs/README.md` index (added `REBRAND.md` entry)
- `docs/releases/RELEASE_GUIDE.md`, `docs/releases/feature-release-notes.md`
- New: `docs/REBRAND.md`

## What was preserved (out of scope)

- `docs/histories/**` and `docs/references/**` — immutable; describe past tooling state.
- `docs/exec-plans/completed/**` — completed plans.
- `apps/OpenComputerUseLinux/`, `apps/OpenComputerUseWindows/` — Go runtime ports tracked from upstream; binary stays `open-computer-use` for clean rebases.
- `plugins/open-computer-use/` — upstream Codex plugin.
- `scripts/install-{codex,gemini,opencode,claude}-mcp.sh`, `scripts/computer-use-cli/`, `scripts/cursor-motion-re/`, `scripts/build-open-computer-use-{linux,windows}.sh`, `scripts/run-isolated-codex-exec.sh`, `scripts/check-github-fork-status.sh` — upstream tools / research / detach helpers.
- `experiments/**` — research code.

## Verification

- `swift build` ✔
- `swift test` ✔ 139/139
- `./scripts/run-tool-smoke-tests.sh`: all 10 tool smoke tests pass; the cursor-idle observation test remains the known pre-existing flake noted in `20260528-1200-verification-fixes.md` (not a rebrand regression — failure mode matches before/after the symbol rename).
- `./scripts/check-repo-hygiene.sh` ✔
- `./scripts/check-docs.sh` ✔
- `node --test scripts/install-config-helper.test.mjs` ✔ 2/2

## Followups

1. Local working directory rename (`cursor_computer_use/` → `cairn-computer-use/`). Defer until session-close so the editor doesn't lose context.
2. GitHub repository rename via `gh repo rename PowerBeef/cairn-computer-use`. GitHub auto-redirects old URLs.
3. npm publish: register `cairn-computer-use`, set up trusted publishing, ship `0.2.0` under the new name.
4. Domain registration (`cairnmcp.com`).
5. macOS app code signing for `com.powerbeef.cairn` (today ad-hoc only).
6. Decide whether to rebrand the Linux/Windows binary too (today only macOS is `cairn`; Linux/Windows ports keep `open-computer-use` to merge cleanly from upstream).

## TCC migration note

The bundle identifier changed from `com.ifuryst.opencomputeruse` to `com.powerbeef.cairn`. macOS TCC keys grants by bundle id, so users with prior `Open Computer Use.app` installs need to grant Accessibility and Screen Recording fresh to `Cairn.app`. `cairn doctor` will detect missing permissions and open the onboarding window.
