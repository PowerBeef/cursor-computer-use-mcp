# Documentation index

English documentation hub for **Cursor Computer Use**. Start at [AGENTS.md](../AGENTS.md) for agent navigation.

## Getting started

| Doc | Purpose |
|-----|---------|
| [CURSOR.md](CURSOR.md) | **Canonical** install, permissions, Composer workflow, env vars |
| [macOS-26.md](macOS-26.md) | macOS 26 (Tahoe) capture and permission notes |
| [FORK.md](FORK.md) | Project specifics (policy, MCP name, no Node wrapper) |
| [BENCHMARK.md](BENCHMARK.md) | MCP benchmark harness |
| [../skills/cursor-computer-use/SKILL.md](../skills/cursor-computer-use/SKILL.md) | Cursor agent skill |
| [../plugins/cursor-computer-use/README.md](../plugins/cursor-computer-use/README.md) | Cursor plugin + `.mcp.json` |

Install and workflow details live in **CURSOR.md** only; other files link there.

Third-party notices: [../ATTRIBUTION.md](../ATTRIBUTION.md).

## Build and verify

```bash
swift build && swift test
./scripts/run-tool-smoke-tests.sh
npm run npm:build
BENCHMARK_TRIALS=1 npm run benchmark
```

Benchmark harness entry: [../benchmarks/README.md](../benchmarks/README.md). Do not commit `benchmarks/results/`.

## Core kit

| Doc | Purpose |
|-----|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Runtime layers, tools, overlay, cross-platform runtimes |
| [SECURITY.md](SECURITY.md) | Security expectations |
| [CICD.md](CICD.md) | CI/CD overview |
| [RELIABILITY.md](RELIABILITY.md) | Reliability practices |
| [SUPPLY_CHAIN_SECURITY.md](SUPPLY_CHAIN_SECURITY.md) | Supply chain |

## Contributing

| Doc | Purpose |
|-----|---------|
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | PR checklist |
| [REPO_COLLAB_GUIDE.md](REPO_COLLAB_GUIDE.md) | Collaboration defaults |
| [HISTORY_GUIDE.md](HISTORY_GUIDE.md) | When to write `docs/histories/` |
| [PLANS_GUIDE.md](PLANS_GUIDE.md) | Execution plans |
| [exec-plans/README.md](exec-plans/README.md) | Active vs completed plans |

When your change affects Cursor users, update **CURSOR.md**, **FORK.md**, **BENCHMARK.md**, and **AGENTS.md** in the same PR.

## Harness placeholders

Template stubs from the AI harness; fill in when the topic applies to this repo:

| Doc | Purpose |
|-----|---------|
| [DESIGN.md](DESIGN.md) | Product design principles |
| [FRONTEND.md](FRONTEND.md) | Frontend collaboration (when a UI exists) |
| [PRODUCT_SENSE.md](PRODUCT_SENSE.md) | Product sense notes |
| [QUALITY_SCORE.md](QUALITY_SCORE.md) | Quality scoring rubric |

## Research archive

Historical and reverse-engineering material (many notes remain in Chinese):

- [references/](references/) — Codex Computer Use RE, CLI notes
- [histories/](histories/) — Completed change logs by month

## Execution plans

- [exec-plans/active/](exec-plans/active/) — In progress or research backlog
- [exec-plans/completed/](exec-plans/completed/) — Finished plans

Cursor-overlay / cursor-lab plans in `active/` are research backlog unless you are actively working on overlay motion.

## Generated assets

- [generated/](generated/) — README images and generated artifacts
