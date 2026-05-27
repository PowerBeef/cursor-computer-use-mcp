# Architecture overview

> **Cursor Computer Use:** Native macOS builds in this repository require **macOS 26 (Tahoe)+**. Cursor install, policy (`ComputerUsePolicy`), and Composer workflow are documented in [FORK.md](FORK.md) and [CURSOR.md](CURSOR.md)—not repeated here.

This repository is a local `computer-use` project. The main line is a Swift macOS automation MCP server, with experimental Windows and Linux runtimes that expose the same nine Computer Use tools via separate Go binaries.

## Repository layout

- `apps/OpenComputerUse`  
  Main entry: `mcp`, `doctor`, `list-apps`, `snapshot`, `call`, `turn-ended`, and global `-h` / `--help` / `-v` / `--version`. Launching without arguments checks permissions first; missing permissions open a headless agent-style onboarding window. `doctor` only raises that UI when permissions are missing.
- `apps/OpenComputerUseFixture`  
  Local GUI fixture for low-risk, predictable click/input/scroll/drag validation.
- `apps/OpenComputerUseSmokeSuite`  
  End-to-end smoke runner: fixture + MCP server, real JSON-RPC for all nine tools; optional visual cursor idle smoke via cross-process observation file (anchored tip + tiny rotate wobble, not lateral drift).
- `apps/OpenComputerUseWindows`  
  Experimental Windows runtime: Go CLI/MCP embeds a PowerShell UI Automation bridge; artifact `open-computer-use.exe` in npm `dist/windows/<arch>/`.
- `apps/OpenComputerUseLinux`  
  Experimental Linux runtime: Go CLI/MCP embeds a Python AT-SPI bridge; artifact `open-computer-use` in npm `dist/linux/<arch>/`.
- `packages/OpenComputerUseKit`  
  Core library: MCP stdio transport and tool registry, app discovery, Accessibility/window snapshot, input simulation, software cursor overlay, fixture test bridge, and **ComputerUsePolicy** (Cursor fork).
- `experiments/CursorMotion`  
  Standalone Swift cursor motion lab (`Bezier + arc + spring`, tuning UI, rendering)—not coupled to the main MCP runtime.
- `experiments/StandaloneCursor`  
  Standalone Swift cursor viewer using paths/scores from `scripts/cursor-motion-re/official_cursor_motion.py` for binary-lift comparison.
- `scripts/`  
  Smoke tests, `.app` packaging, Windows/Linux builds, npm distribution, and `scripts/computer-use-cli/` for probing official bundled `computer-use`.
- `skills/`  
  Agent-installable skills. `skills/open-computer-use/SKILL.md` is a light entry; details live in `references/`. `scripts/package-skill.sh` builds `.zip` / `.skill` artifacts. **Cursor:** `skills/cursor-computer-use/`.
- `docs/`  
  Reverse engineering, execution plans, histories, and project constraints. Index: [README.md](README.md).

## Runtime layers

### 1. App mode

- Default app mode runs `PermissionOnboardingApp`.
- The bundle runs as an `LSUIElement` agent (no Dock icon by default) but can show permission windows.
- On macOS, CLI commands (`mcp`, `doctor`, `call`, `snapshot`, `list-apps`) start the same `.app` agent via LaunchServices and a Unix domain socket under the user temp directory. Accessibility, ScreenCaptureKit, and tool execution run inside **Open Computer Use.app**, not Terminal/Cursor/Node.
- The main window covers Accessibility and Screen Recording cards, Allow/Done, and relaunch convergence; it closes automatically when both are granted.
- Drag panels deep-link into System Settings with spring/curved motion; panels stay above the settings window without scanning `+/-` rows. TCC grants merge persistent records with runtime preflight (`AXIsProcessTrusted`, `CGPreflightScreenCaptureAccess`). Release builds use CI-produced `Open Computer Use.app`; local debug builds use `Open Computer Use (Dev).app` when present.

### 2. MCP layer

- External transport is **stdio**; macOS CLI-to-app uses an extra Unix socket proxy so automation runs under the app bundle identity.
- When `OPEN_COMPUTER_USE_VISUAL_CURSOR` is not disabled, `mcp` spins a minimal AppKit runtime (overlay on main thread, stdio server on a background thread).
- Framing: one JSON-RPC message per line.
- Methods: `initialize`, `notifications/initialized`, `notifications/turn-ended`, `ping`, `tools/list`, `tools/call`.
- `notifications/turn-ended` clears the visual cursor overlay; CLI `open-computer-use turn-ended` can notify a running AppKit MCP process (Codex legacy hook).

### 3. Tool service

- `ComputerUseService` maps tool requests to local capabilities; `ComputerUseToolDispatcher` shares parsing between MCP and `open-computer-use call`.
- `list_apps`: Spotlight metadata + `NSWorkspace` for running and recently used apps.
- `get_app_state`: real AX/window capture when possible; requires non-minimized `AXWindow` and on-screen `CGWindow`. Best-effort unhide/activate before `cgWindowNotFound`. Fixture apps use synthetic state. Tree rendering compresses noise and deep Electron/WebView trees; open panels and Finder column views include visible file items.
- MCP `tools/list` descriptions/schemas align with official `computer-use` nine tools.
- `open-computer-use call` supports single tools and `--calls` JSON arrays with shared in-process element index state; default 1s sleep between successful steps (`--sleep` override); stops on first `isError`.
- Password-manager denylist via `AppSafetyPolicy` / `ComputerUsePolicy`; optional `.cursor/computer-use-policy.json` allow/deny lists (fork).
- Element frames are window-relative for screenshot alignment.
- `click` / `set_value` drive `SoftwareCursorOverlay` with heading-driven motion, visual dynamics, click pulse vs settle idle, 30s idle cleanup, immediate cleanup on `turn-ended`.
- Overlay style prefers `official-software-cursor-window-252.png`; procedural fallback with neutral heading `-3π/4`; coordinate conversion between y-down AX/CG and AppKit global space; z-order follows target window.
- Path selection uses heading-driven candidates (`direct` / `turn` / `brake` / `orbit`) and spring progress (~1.43s default move); visual dynamics separate path from visible pose.
- **Non-intrusive first:** AX actions, settable checks for `set_value`, semantic click fallbacks, coordinate hit-test, `CGEvent.postToPid` for keys/scroll; global pointer fallbacks only with `OPEN_COMPUTER_USE_ALLOW_GLOBAL_POINTER_FALLBACKS=1`.

### 4. Fixture bridge

- `OpenComputerUseFixture` writes window/element state to a temp JSON file.
- `FixtureBridge` serves deterministic smoke paths only—not a general third-party app API.
- Synthetic bundle id for bare SwiftPM fixture so `list_apps` smoke still works.

### 5. Cursor lab

- `StandaloneCursor`: `swift run StandaloneCursor`—Python-reconstructed paths/scores/spring timeline without speculative wall-clock mapping.
- `CursorMotion`: `swift run CursorMotion`—motion model experiments; does not write back to production overlay.

### 6. Windows runtime

- `apps/OpenComputerUseWindows`: Go CLI, MCP, embedded `runtime.ps1`, UIA patterns with Win32 message fallbacks.
- Opt-in: `OPEN_COMPUTER_USE_WINDOWS_ALLOW_APP_LAUNCH`, `ALLOW_FOCUS_ACTIONS`, `ALLOW_UIA_TEXT_FALLBACK`.
- Same nine tools as macOS; requires an interactive desktop session.
- First functional version: no overlay, installer, or signing. See completed plan `docs/exec-plans/completed/20260422-windows-computer-use-runtime.md` if present, or histories under `docs/histories/`.

### 7. Linux runtime

- `apps/OpenComputerUseLinux`: Go CLI, embedded `runtime.py`, AT-SPI2 via GObject introspection.
- Deep GTK trees (depth 64); GDK screenshot with black-frame detection on Wayland.
- Same nine tools; needs logged-in desktop session and D-Bus/display env (auto-discovery when possible).
- First functional version: no overlay or desktop entry. See completed plan `docs/exec-plans/completed/20260422-linux-computer-use-runtime.md` if present, or histories.

## Key boundaries

- Open source does not replicate official caller signing, private IPC, full overlay choreography, or plugin self-install.
- Official bundled `computer-use` may be killed by launch constraints; use normal Codex chains for official tools, `open-computer-use mcp` for this project.
- Permission onboarding and visual cursor are close but not identical to official embedded choreography.
- Screenshots: ScreenCaptureKit → MCP `image` PNG (size-capped), not repo temp files; coordinate tools map pixel size to window points.
- Session state is in-process (latest snapshot + element index per app).

## Verification

- Unit tests: `swift test`
- Standalone cursor: `swift build --product StandaloneCursor`
- Cursor lab: `swift build --product CursorMotion`
- E2E smoke: `./scripts/run-tool-smoke-tests.sh`
- App package: `./scripts/build-open-computer-use-app.sh debug`
- Permission E2E: `./scripts/run-permission-onboarding-e2e.sh`
- npm staging: `node ./scripts/npm/build-packages.mjs`
- Release tgz: `./scripts/release-package.sh`
- Skill package: `npm run package:skill`
- Windows: `(cd apps/OpenComputerUseWindows && go test ./...)`, `./scripts/build-open-computer-use-windows.sh --arch arm64`
- Linux: `(cd apps/OpenComputerUseLinux && go test ./...)`, `./scripts/build-open-computer-use-linux.sh --arch arm64`
- Diagnostics: `open-computer-use doctor`, `snapshot`, `call list_apps`, `call --calls '[...]'`
- Fork benchmarks: `npm run benchmark` — see [BENCHMARK.md](BENCHMARK.md)
