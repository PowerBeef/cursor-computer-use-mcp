# Cursor Computer Use deep overhaul

## User request

Implement the five-phase deep overhaul plan: vision quality (SoM, stable indices, YAML tree), Cursor integration (schemas, doctor --cursor, install checklist, plugin manifest), Apple Vision OCR, runtime efficiency (cache, MCP resources, dedup), and docs/benchmark hygiene.

## Changes

### Vision & snapshots

- Set-of-Mark PNG overlays (`SetOfMarkRenderer`), per-line `Frame:` coords, stable `id:…` element IDs, YAML `format`, screenshot scale header.
- Action tools default to text-only; `include_screenshot` opt-in.
- `OCRPipeline` (Vision) with `ocr` param and `OPEN_COMPUTER_USE_OCR_DEFAULT`.
- Off-screen pruning, truncation footer, O(N) AX child dedup, attributed text excerpts for web/text areas.
- Window recovery uses AX visibility polling instead of a fixed 700ms sleep.

### Cursor integration

- Tool schemas without duplicated Composer workflow in each tool; `doctor --cursor` preflight (`CursorDoctorDiagnostics`).
- Install helper post-install checklist, legacy `computer-use-mcp` warnings, PATH check.
- `plugins/cursor-computer-use/.cursor-plugin/plugin.json`; `.cursor/hooks/turn-ended.example.json`.
- Richer `ComputerUsePolicy` denial messages with policy file paths.

### MCP

- `resources/list` + `resources/read` for latest screenshot URI.
- `notifications/turn-ended` clears snapshot caches.

### Docs & packaging

- Updated `docs/CURSOR.md`, `docs/ARCHITECTURE.md`, `docs/macOS-26.md`, `README.md`.
- `benchmarks/results/sample-report.md` baseline placeholder; `artifacts/` gitignore hygiene.
- `scripts/package-skill.sh` packages both `open-computer-use` and `cursor-computer-use` skills.

## Key files

- `packages/OpenComputerUseKit/Sources/OpenComputerUseKit/AccessibilitySnapshot.swift`
- `packages/OpenComputerUseKit/Sources/OpenComputerUseKit/SnapshotPresentation.swift`
- `packages/OpenComputerUseKit/Sources/OpenComputerUseKit/ComputerUseService.swift`
- `packages/OpenComputerUseKit/Sources/OpenComputerUseKit/MCPServer.swift`
- `packages/OpenComputerUseKit/Sources/OpenComputerUseKit/ToolDefinitions.swift`
- `scripts/install-config-helper.mjs`

## Notes

- Foundation Models `describe_screen` remains out of scope.
- Full `ComputerUseService` actor isolation and AXObserver partial invalidation are deferred; in-process cache + turn-ended invalidation shipped instead.
