# Cairn plugin

MCP plugin for **Cursor** on **macOS 26 (Tahoe)+**.

## MCP config

```json
{
  "mcpServers": {
    "cairn": {
      "command": "cairn",
      "args": ["mcp"]
    }
  }
}
```

Copy [`.mcp.json`](.mcp.json) into your project or run `cairn install-cursor-mcp` — see **[docs/CURSOR.md](../../docs/CURSOR.md)** for install, permissions, and Composer workflow.

## Docs

- [docs/CURSOR.md](../../docs/CURSOR.md) — canonical setup and workflow
- [docs/macOS-26.md](../../docs/macOS-26.md) — Tahoe notes
- [skills/cairn/SKILL.md](../../skills/cairn/SKILL.md) — agent skill
