# Composer 2.5 manual eval prompts

Run each prompt **twice** (once per MCP variant). Enable **only one** server at a time in Cursor → Tools & MCP.

| Variant | MCP server | Tools |
|---------|------------|-------|
| **ocu** | `cairn` | 9 tools via `cairn mcp` |
| **legacy** | `computer-use-mcp` (optional) | Single `computer` tool |

| # | Prompt |
|---|--------|
| 1 | Open TextEdit, type `Composer bench 1`, and confirm the text is visible in the document. |
| 2 | Open System Settings, go to General, and confirm that pane is showing. |
| 3 | Bring Simulator to the front (if installed) and confirm a device window is visible. |

Record scores using [composer-rubric.md](./composer-rubric.md) and CSV templates in `benchmarks/templates/` (`composer-ocu.csv`, `composer-legacy.csv`). Save filled CSVs under `benchmarks/results/` (gitignored).
