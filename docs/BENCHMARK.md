# Benchmarks (OCU-native)

Headless harness under `benchmarks/` measures the native `open-computer-use mcp` server. An optional legacy comparison against `npx computer-use-mcp` is available.

## Prerequisites

- **macOS 26 (Tahoe)+** for this fork’s native macOS build
- Accessibility + Screen Recording granted for **Open Computer Use.app**
- `open-computer-use` on `PATH` (from `npm run npm:build` or `npm i -g open-computer-use`)
- TextEdit available for typing tasks

## macOS 26 validation (2026-05-27)

Validated on Tahoe host (darwin/arm64, global `open-computer-use`):

| Check | Result |
|-------|--------|
| `swift test` | 132 passed |
| `./scripts/run-tool-smoke-tests.sh` | 9-tool smoke passed |
| `BENCHMARK_TRIALS=1 npm run benchmark` | All OCU tasks 100% (cold_start, screenshot_latency, textedit_type, policy) |

Example report (local, not committed): `benchmarks/results/2026-05-27T17-14-09-450Z/report.md`. The `benchmarks/results/` directory is gitignored.

See [macOS-26.md](macOS-26.md) for Tahoe capture troubleshooting.

## Run

```bash
# Calibrate legacy coordinate click (only if BENCHMARK_LEGACY=1)
npm run benchmark:calibrate

# Primary: OCU only (3 trials per task)
BENCHMARK_TRIALS=1 npm run benchmark

# Optional legacy comparison
BENCHMARK_LEGACY=1 BENCHMARK_TRIALS=1 npm run benchmark
```

Results land in `benchmarks/results/<timestamp>/report.md` with JSON per variant (`ocu.json`, optional `legacy.json`). Do not commit `benchmarks/results/`.

## Tasks

| Task | What it measures |
|------|------------------|
| `cold_start` | MCP spawn + `tools/list` (expects 9 OCU tools) |
| `screenshot_latency` | `get_app_state` capture latency + screenshot bytes (inline `image` or `resources/read` on `computer-use://screenshot/latest`) |
| `textedit_type` | Type unique marker into TextEdit and verify via AppleScript |
| `policy` | Denylisted password-manager bundle blocked without launching any app |

## Composer rubric (manual)

See [benchmarks/composer-prompts.md](../benchmarks/composer-prompts.md), [benchmarks/composer-rubric.md](../benchmarks/composer-rubric.md), and templates `composer-ocu.csv` / `composer-legacy.csv` under [benchmarks/templates/](../benchmarks/templates/).

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `BENCHMARK_TRIALS` | `3` | Repetitions per variant |
| `BENCHMARK_LEGACY` | unset | Also run `npx -y computer-use-mcp` |
| `BENCHMARK_OCU_COMMAND` | `open-computer-use` | Override OCU binary path |
