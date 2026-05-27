# Cursor Computer Use

Cursor Computer Use provides install helpers, policy files, Composer-tuned MCP tool descriptions, and a `cursor-computer-use` skill pack for the native `open-computer-use` MCP server.

**macOS requirement:** build and run the native macOS `.app` / CLI on **macOS 26 (Tahoe) or later**. See [macOS-26.md](macOS-26.md) for Tahoe-specific capture and permission notes.

## Quick start

1. Build or install the CLI:

```bash
npm run npm:build
# or
npm install -g open-computer-use
```

2. macOS permissions:

```bash
open-computer-use doctor
```

Grant **Accessibility** and **Screen Recording** to **Open Computer Use.app** (not Terminal/Cursor) when prompted.

3. Install MCP into Cursor:

```bash
open-computer-use install-cursor-mcp
# project-only:
open-computer-use install-cursor-mcp --scope project
```

Or copy [`.cursor/mcp.json`](../.cursor/mcp.json) into your project.

4. In **Cursor → Settings → MCP**, enable `cursor-computer-use`. You should see **9 tools** (`list_apps`, `get_app_state`, `click`, …), not a single `computer` tool.

5. Optional policy file:

```bash
cp .cursor/computer-use-policy.example.json .cursor/computer-use-policy.json
```

## Composer workflow

1. `list_apps` — choose the target app.
2. `get_app_state` — **once per assistant turn** before other actions; read `element_index` values from the accessibility tree.
3. Act with `click`, `set_value`, `type_text`, `scroll`, etc. Prefer **element_index** over coordinates.
4. Call `get_app_state` again to verify when the UI may have changed.

For **local web apps** you are building, prefer **cursor-ide-browser** when it is enabled. Use Computer Use for native macOS desktop UI.

After each assistant turn, hosts that support MCP may send `notifications/turn-ended`, or you can run:

```bash
open-computer-use turn-ended
```

## Cursor 3.5 agents

- **Automations** and **no-repo tasks** can use the same MCP server if `open-computer-use` is on `PATH` and permissions are granted for the session user.
- Keep one Computer Use MCP enabled at a time; disable legacy `computer-use-mcp` (single `computer` tool) to avoid confusion.

## Environment variables

| Variable | Purpose |
|----------|---------|
| `OPEN_COMPUTER_USE_MAX_TEXT_CHARS` | Truncate large text in MCP responses (default `24000`, suffix `[truncated]`) |
| `OPEN_COMPUTER_USE_ALLOW_GLOBAL_POINTER_FALLBACKS` | Diagnostic physical-pointer fallback (macOS) |

## Skill pack

Copy or install `skills/cursor-computer-use/` into your Cursor skills directory, or use the packaged skill after publish.

## Merging automation updates

When pulling in changes from the upstream automation project, use your `upstream` remote and rebase. See [ATTRIBUTION.md](../ATTRIBUTION.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).
