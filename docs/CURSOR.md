# Cairn

Cairn provides install helpers, policy files, Composer-tuned MCP tool descriptions, and a `cairn` skill pack for the native `cairn` MCP server.

**macOS requirement:** build and run the native macOS `.app` / CLI on **macOS 26 (Tahoe) or later**. See [macOS-26.md](macOS-26.md) for Tahoe-specific capture and permission notes.

## Quick start

1. Build or install the CLI:

```bash
npm run npm:build
# or
npm install -g cairn-computer-use
```

2. macOS permissions:

```bash
cairn doctor
cairn doctor --cursor   # macOS 26, PATH, ~/.cursor/mcp.json preflight
```

Grant **Accessibility** and **Screen Recording** to **Cairn.app** (not Terminal/Cursor) when prompted.

3. Install MCP into Cursor:

```bash
cairn install-cursor-mcp
# project-only:
cairn install-cursor-mcp --scope project
```

Or copy [`.cursor/mcp.json`](../.cursor/mcp.json) into your project.

Project installs set `CAIRN_PROJECT_ROOT` in the MCP server `env` so `.cursor/cairn-policy.json` and project `.cursor/mcp.json` resolve when Cursor’s cwd is not the repo root.

4. In **Cursor → Settings → MCP**, enable `cairn`. You should see **9 tools** (`list_apps`, `get_app_state`, `click`, …), not a single `computer` tool.

5. Optional policy file:

```bash
cp .cursor/cairn-policy.example.json .cursor/cairn-policy.json
```

## Composer workflow

1. `list_apps` — choose the target app.
2. `get_app_state` — **once per assistant turn** before other actions; read `element_index` values from the accessibility tree (numbered **Set-of-Mark** boxes on the screenshot). Screenshots are exposed via MCP `resources/read` by default; pass `inline_image: true` to embed PNG in the tool result.
3. Act with `click`, `set_value`, `type_text`, `scroll`, etc. Prefer **element_index** over coordinates.
4. Call `get_app_state` again to verify when the UI may have changed.

For **local web apps** you are building, prefer **cursor-ide-browser** when it is enabled. Use Computer Use for native macOS desktop UI.

After each assistant turn, hosts that support MCP may send `notifications/turn-ended`, or you can run:

```bash
cairn turn-ended
```

Example Cursor hook (copy to `.cursor/hooks.json` or merge with your hooks config): see [`.cursor/hooks/turn-ended.example.json`](../.cursor/hooks/turn-ended.example.json).

### `get_app_state` options

| Parameter | Purpose |
|-----------|---------|
| `format` | `text` (default) or `yaml` compact tree |
| `ocr` | Run Apple Vision OCR and merge text (default off; env `CAIRN_OCR_DEFAULT=1`) |
| `inline_image` | Embed PNG in tool result instead of MCP resource URI |

Action tools accept `include_screenshot: true` when you need a fresh annotated PNG after a click/type; default is text-only for token efficiency.

## Cursor 3.5 agents

- **Automations** and **no-repo tasks** can use the same MCP server if `cairn` is on `PATH` and permissions are granted for the session user.
- Keep one Computer Use MCP enabled at a time; disable legacy `computer-use-mcp` (single `computer` tool) to avoid confusion.

## Environment variables

| Variable | Purpose |
|----------|---------|
| `CAIRN_MAX_TEXT_CHARS` | Truncate large text in MCP responses (default `24000`, suffix `[truncated]`) |
| `CAIRN_ALLOW_GLOBAL_POINTER_FALLBACKS` | Diagnostic physical-pointer fallback (macOS) |
| `CAIRN_OCR_DEFAULT` | When `1`/`true`, default `get_app_state` OCR to on |

## Skill pack

Copy or install `skills/cairn/` into your Cursor skills directory, or use the packaged skill after publish.

## Merging automation updates

When pulling in changes from the upstream automation project, use your `upstream` remote and rebase. See [ATTRIBUTION.md](../ATTRIBUTION.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).
