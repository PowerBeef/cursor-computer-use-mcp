---
name: cursor-computer-use
description: Operate macOS 26+ desktop apps via Cursor Computer Use MCP (9 Codex-style tools through open-computer-use). Use for GUI tasks Composer cannot solve with terminal or cursor-ide-browser alone.
---

# Cursor Computer Use

## When to use

- Reproduce or verify bugs in Simulator, Xcode, or other desktop apps
- Change settings only available in a GUI
- Operate apps without a structured MCP integration

**Do not use** for local web apps you are building — prefer **cursor-ide-browser** first.

## Setup

1. **macOS 26 (Tahoe)+** required for the native macOS build
2. `npm run npm:build` in this repo, or `npm i -g open-computer-use`
3. Grant **Accessibility** and **Screen Recording** to **Open Computer Use.app** (`open-computer-use doctor`)
4. `open-computer-use install-cursor-mcp` (or project `.cursor/mcp.json`)
5. Enable MCP server `cursor-computer-use` in Cursor (9 tools)
6. Optional: `.cursor/computer-use-policy.json` from `.cursor/computer-use-policy.example.json`

Tahoe-specific notes: [docs/macOS-26.md](../../docs/macOS-26.md)

## Composer workflow

1. `list_apps` — pick target app
2. `get_app_state` — **once per assistant turn** before other actions; read `element_index` values
3. Act with `click` / `set_value` / `type_text` / `scroll` using **element_index** when possible
4. `get_app_state` again to verify when UI may have changed
5. Hosts with turn notifications: send `notifications/turn-ended` or run `open-computer-use turn-ended`

For rare AppleScript-friendly one-offs (Mail, Finder scripts), use the **shell** — do not expect a dedicated MCP AppleScript tool.

## Rules

- One clear app per task
- Password managers are blocked by default policy
- Ask before send/purchase/delete/upload actions
- Prefer `set_value` and keyboard shortcuts over blind coordinate clicks

## Troubleshooting

- Permissions → `open-computer-use doctor` (grant **Open Computer Use.app**)
- Wrong tool count → disable legacy `computer-use-mcp`; use only `cursor-computer-use`
- Tahoe capture issues → [docs/macOS-26.md](../../docs/macOS-26.md)
- Docs → [docs/CURSOR.md](../../docs/CURSOR.md)
