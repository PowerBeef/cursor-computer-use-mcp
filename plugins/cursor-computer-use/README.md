# Cursor Computer Use plugin

MCP plugin for **Cursor** on **macOS 26 (Tahoe)+**.

## Requirements

- macOS 26 (Tahoe) or later
- `open-computer-use` on `PATH` (`npm run npm:build` in this repo, or global install)
- **Accessibility** and **Screen Recording** granted to **Open Computer Use.app**

## Install

```bash
open-computer-use install-cursor-mcp
# or project-only:
open-computer-use install-cursor-mcp --scope project
```

Or copy [`.mcp.json`](.mcp.json) into your project or merge into `~/.cursor/mcp.json`.

## MCP config

```json
{
  "mcpServers": {
    "cursor-computer-use": {
      "command": "open-computer-use",
      "args": ["mcp"]
    }
  }
}
```

Enable **cursor-computer-use** in Cursor → Settings → MCP. Expect **9 tools** (`list_apps`, `get_app_state`, `click`, …).

Disable legacy **computer-use-mcp** (single `computer` tool) to avoid confusion.

## Docs

- [docs/CURSOR.md](../../docs/CURSOR.md) — Composer workflow
- [docs/macOS-26.md](../../docs/macOS-26.md) — Tahoe capture and permissions
- [skills/cursor-computer-use/SKILL.md](../../skills/cursor-computer-use/SKILL.md) — agent skill
