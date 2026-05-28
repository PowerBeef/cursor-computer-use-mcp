# macOS 26 (Tahoe) notes

This fork’s **macOS native build requires macOS 26 (Tahoe)+**. Linux and Windows npm runtimes are unchanged.

## Permissions

Grant **Accessibility** and **Screen Recording** to **Cairn.app**, not Terminal or Cursor.

```bash
cairn doctor
cairn doctor --cursor
```

## Vision (OCR + presentation)

- **Set-of-Mark**: annotated PNG overlays use each indexed control's window-relative frame.
- **Apple Vision OCR** (`VNRecognizeTextRequest`): opt-in via `get_app_state` `ocr: true` or `CAIRN_OCR_DEFAULT=1`.
- **Attributed text**: web areas and text fields may expose `AXAttributedStringForTextMarkerRange` excerpts when plain `AXValue` is empty.

If permissions look granted but capture still fails, quit and reopen the app that launched MCP, then rerun `doctor`.

## ScreenCaptureKit on Tahoe

Tahoe can return stale `SCShareableContent` after sleep, display hotplug, or external monitors. This fork:

1. Captures with `SCContentFilter(desktopIndependentWindow:)` first (works across displays).
2. Refreshes shareable content and retries once on failure.
3. Falls back to display-level capture + crop when window mapping fails.

Enable debug logging:

```bash
export CAIRN_DEBUG_INPUT_FALLBACKS=1
cairn call get_app_state --args '{"app":"TextEdit"}'
```

## System Settings

Query aliases include **System Settings** → `com.apple.systempreferences` (and `com.apple.settings` when present).

Composer prompt example:

```
cairn call get_app_state --args '{"app":"System Settings"}'
```

## Known limitations

- **Apple VMs / virtualization**: window compositor may not include app windows in captures (ecosystem limitation; not fixable in-app).
- **Notarized builds**: frequent ScreenCaptureKit reconfiguration triggers expensive TCC checks; this fork reuses configuration per capture attempt only.

## Troubleshooting

| Symptom | Action |
|---------|--------|
| Screenshot shows desktop only | Rerun `doctor`; wake display; retry `get_app_state`; check debug logs |
| Blank MCP tools | Ensure `cairn` on PATH; disable legacy `computer-use-mcp` |
| Wrong app blocked | Edit `.cursor/cairn-policy.json` |

See also [CURSOR.md](CURSOR.md) and [BENCHMARK.md](BENCHMARK.md).
