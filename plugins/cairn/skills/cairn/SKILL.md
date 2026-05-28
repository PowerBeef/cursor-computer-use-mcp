---
name: cairn
description: Operate macOS 26+ desktop apps via Cairn MCP (9 Codex-style tools through cairn). Use for GUI tasks Composer cannot solve with terminal or cursor-ide-browser alone.
---

# Cairn

## When to use

- Reproduce or verify bugs in Simulator, Xcode, or other desktop apps
- Change settings only available in a GUI
- Operate apps without a structured MCP integration

**Do not use** for local web apps you are building — prefer **cursor-ide-browser** first.

## Setup

1. Install: `cairn install-cursor-mcp` (or enable this plugin’s MCP entry).
2. Grant Accessibility + Screen Recording to **Cairn.app** (not Terminal/Cursor).
3. Run: `cairn doctor --cursor`
4. Optional policy: copy `.cursor/cairn-policy.example.json` to `.cursor/cairn-policy.json` in your project.

Repository docs: https://github.com/PowerBeef/cairn-computer-use/blob/main/docs/CURSOR.md

## Composer workflow

1. `list_apps` — pick target app
2. `get_app_state` — **once per assistant turn** before other actions; read `element_index` values
3. Act with `click` / `set_value` / `type_text` / `scroll` using **element_index** when possible
4. `get_app_state` again to verify when UI may have changed
5. Hosts with turn notifications: send `notifications/turn-ended` or run `cairn turn-ended`

Screenshots default to MCP resource `cairn://screenshot/latest`; pass `inline_image: true` on `get_app_state` when the client cannot read resources.

## Rules

- Enable **`cairn`** only (9 tools); disable legacy **`computer-use-mcp`**
- One clear app per task
- Never target **Passwords** (`com.apple.Passwords`) or other denylisted apps
- Ask before send/purchase/delete/upload actions
- Prefer `set_value` and keyboard shortcuts over blind coordinate clicks

## Troubleshooting

- `cairn doctor --cursor` — MCP config, PATH, permissions
- macOS 26 capture: https://github.com/PowerBeef/cairn-computer-use/blob/main/docs/macOS-26.md
