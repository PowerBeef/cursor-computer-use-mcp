# Benchmark sample baseline

Placeholder p50/p95 targets for `cursor-computer-use` smoke runs. Re-run after runtime changes:

```bash
BENCHMARK_TRIALS=3 npm run benchmark
```

| Scenario | p50 (ms) | p95 (ms) | Notes |
|----------|----------|----------|-------|
| `cold_start` | 420 | 680 | MCP spawn + `tools/list` (9 tools) |
| `screenshot_latency` | 850 | 1400 | SoM PNG via MCP resource + AX tree |
| `textedit_type` | 2100 | 3200 | `type_text` round-trip in TextEdit |

Update this table from `benchmarks/report.ts` output after each major phase.
