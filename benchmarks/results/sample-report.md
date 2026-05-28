# Benchmark sample baseline

Placeholder p50/p95 targets for `cursor-computer-use` smoke runs. Re-run after runtime changes:

```bash
BENCHMARK_TRIALS=3 npm run benchmark
```

| Scenario | p50 (ms) | p95 (ms) | Notes |
|----------|----------|----------|-------|
| `cold_start` | — | — | First `get_app_state` after MCP spawn |
| `screenshot_latency` | — | — | Annotated PNG + tree |
| `textedit_type` | — | — | `type_text` round-trip |

Update this table from `benchmarks/report.ts` output after each major phase.
