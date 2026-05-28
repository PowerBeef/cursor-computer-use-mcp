# Project specifics

Cairn layers Cursor integration and macOS 26 requirements on top of the native `cairn` automation stack. Third-party notices: [ATTRIBUTION.md](../ATTRIBUTION.md).

## What this repository adds

| Area | Location |
|------|----------|
| Cursor MCP install | `cairn install-cursor-mcp`, [scripts/install-cursor-mcp.sh](../scripts/install-cursor-mcp.sh) |
| MCP server name | `cairn` in Cursor (9 tools via `cairn mcp`) |
| Policy | [CairnPolicy.swift](../packages/CairnKit/Sources/CairnKit/CairnPolicy.swift), `.cursor/cairn-policy.json` |
| Composer tool hints | [ToolDefinitions.swift](../packages/CairnKit/Sources/CairnKit/ToolDefinitions.swift), [MCPServer.swift](../packages/CairnKit/Sources/CairnKit/MCPServer.swift) |
| Docs and skill | [CURSOR.md](CURSOR.md), [macOS-26.md](macOS-26.md), [skills/cairn/](../skills/cairn/) |
| Plugin stub | [plugins/cairn/](../plugins/cairn/) |
| Benchmarks | [benchmarks/](../benchmarks/), [BENCHMARK.md](BENCHMARK.md) |

## What this repository does not add

- No TypeScript/Node hybrid MCP wrapper (`dist/index.js` style). Use native `cairn mcp` only.
- Do not enable legacy **`computer-use-mcp`** (single `computer` tool) alongside **`cairn`** unless you are running an explicit legacy comparison.

## macOS 26 (Tahoe) minimum

The **native macOS Swift build** in this repository requires **macOS 26+** (`Package.swift` platform `.macOS(.v26)`). Linux and Windows npm runtimes remain cross-platform where published.

Tahoe-specific capture and permission notes: [macOS-26.md](macOS-26.md).

## Policy and safety

Policy files (optional):

- Project: `.cursor/cairn-policy.json` (see [cairn-policy.example.json](../.cursor/cairn-policy.example.json))
- User: `~/.cursor/cairn-policy.json`

Fields: `denyPasswordManagers`, `allowApps`, `denyBundleIds`.

Built-in denylist includes password managers and **`com.apple.Passwords`**. Agents and benchmarks must not target Passwords or other denylisted apps for policy checks.

## Merging upstream automation changes

```bash
git fetch upstream
git rebase upstream/main
```

Scope Cursor-specific commits clearly (`cursor: …`, `macOS26: …`). Core runtime behavior is documented in [ARCHITECTURE.md](ARCHITECTURE.md).
