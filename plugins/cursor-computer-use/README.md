# Cursor Computer Use plugin

MCP plugin for **Cursor** on **macOS 26 (Tahoe)+**.

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

Copy [`.mcp.json`](.mcp.json) into your project or run `open-computer-use install-cursor-mcp` — see **[docs/CURSOR.md](../../docs/CURSOR.md)** for install, permissions, and Composer workflow.

## Docs

- [docs/CURSOR.md](../../docs/CURSOR.md) — canonical setup and workflow
- [docs/macOS-26.md](../../docs/macOS-26.md) — Tahoe notes
- [skills/cursor-computer-use/SKILL.md](../../skills/cursor-computer-use/SKILL.md) — agent skill
