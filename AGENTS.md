# Cairn

MCP server for native macOS desktop automation. Cursor-first but host-agnostic. Native automation lives in **CairnKit** (Swift) and **Cairn.app**; Cursor integration is install helpers, policy, Composer-tuned MCP hints, skills, and docs — **not** a parallel Node MCP server.

`AGENTS.md` stays short: navigation only. Detailed rules live under `docs/` and `skills/`.

If a change makes documentation stale, update the relevant doc in the same task.

## Start here

- [docs/README.md](docs/README.md) — full documentation map.
- [docs/CURSOR.md](docs/CURSOR.md) — install MCP, permissions, Composer workflow (canonical).
- [docs/REBRAND.md](docs/REBRAND.md) — Cairn naming decision and migration notes.
- [docs/FORK.md](docs/FORK.md) — project specifics (policy, macOS 26, MCP naming).
- [docs/macOS-26.md](docs/macOS-26.md) — macOS 26 (Tahoe) capture and permission notes.
- [skills/cairn/SKILL.md](skills/cairn/SKILL.md) — when/how to use Cairn in Cursor.

Legal and third-party notices: [ATTRIBUTION.md](ATTRIBUTION.md).

## Repository layout

- `packages/CairnKit/` — MCP tools, AX snapshot, ScreenCaptureKit, input, policy (`CairnPolicy.swift`).
- `apps/Cairn/` — CLI (`mcp`, `doctor`, `call`, …) and macOS app agent.
- `scripts/install-cursor-mcp.sh` — writes Cursor `mcp.json`.
- `plugins/cairn/` — Cursor plugin stub + `.mcp.json`.
- `benchmarks/` — MCP benchmark harness (`npm run benchmark`); do **not** commit `benchmarks/results/`.
- `.cursor/` — project MCP template and policy example JSON.

Upstream-tracked surfaces still use the historical `OpenComputerUse`/`open-computer-use` naming:

- `apps/OpenComputerUseLinux/`, `apps/OpenComputerUseWindows/` — Go runtime ports.
- `plugins/open-computer-use/` — upstream Codex plugin.
- `scripts/install-{codex,gemini,opencode}-mcp.sh` — installers for non-Cursor hosts.

Do not rename these during routine work; they merge cleanly from upstream.

## Agent workflow (Cairn MCP)

1. Enable **`cairn`** only (9 tools). Disable legacy **`computer-use-mcp`** (single `computer` tool) and any old **`cursor-computer-use`** entry.
2. `list_apps` → `get_app_state` **once per turn** → act via **`element_index`** → verify with another `get_app_state` if needed.
3. Prefer **cursor-ide-browser** for local web apps; use Cairn for native macOS UI.
4. Grant permissions to **Cairn.app**, not Terminal/Cursor (`cairn doctor`).
5. Never target password managers or **Passwords** (`com.apple.Passwords`); policy tests use denylisted bundle IDs only.
6. Ask before send, delete, purchase, or other externally visible actions.

## Build and test

```bash
swift build && swift test
./scripts/run-tool-smoke-tests.sh
npm run npm:build          # macOS .app + npm package
BENCHMARK_TRIALS=1 npm run benchmark
```

macOS native build minimum: **macOS 26 (Tahoe)+** (`Package.swift`).

## Core documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — runtime layers, tool behavior, overlay.
- [docs/REPO_COLLAB_GUIDE.md](docs/REPO_COLLAB_GUIDE.md) — collaboration, commits, doc sync.
- [docs/HISTORY_GUIDE.md](docs/HISTORY_GUIDE.md) — when to write `docs/histories/`.
- [CONTRIBUTING.md](CONTRIBUTING.md) — PR checks.

When merging automation changes from the upstream open-codex-computer-use project:

```bash
git fetch upstream
git rebase upstream/main
```

Scope Cairn-specific commits clearly (`cairn: …`, `macOS26: …`).

## Working rules

- Do not reintroduce a TypeScript/Node MCP wrapper; use native `cairn mcp`.
- Minimize diff scope; match existing Swift and script conventions.
- Reply in the language the user uses for that turn.
- Record non-trivial code changes in `docs/histories/` when the repo guide calls for it.
