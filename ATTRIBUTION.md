# Attribution

## This project

**Cursor Computer Use** is distributed in this repository. It provides Cursor-focused MCP integration, policy controls, Composer-tuned tool descriptions, macOS 26 (Tahoe) native builds, skills, benchmarks, and related documentation.

## Third-party software

Core desktop automation derives from **[open-codex-computer-use](https://github.com/iFurySt/open-codex-computer-use)** (MIT). That project implements the native Swift MCP server, cross-platform npm packaging, and the `open-computer-use` CLI used by this distribution.

Modifications and additions in this repository include:

- `install-cursor-mcp` and Cursor MCP configuration (`cursor-computer-use` server name)
- `ComputerUsePolicy` and `.cursor/computer-use-policy.json`
- macOS 26 minimum for the native macOS Swift build (`Package.swift`)
- Cursor skill pack under `skills/cursor-computer-use/`
- Documentation under `docs/` (see [docs/README.md](docs/README.md))

## License

This repository is released under the [MIT License](LICENSE). The MIT License from the upstream project applies to the portions derived from open-codex-computer-use; see the upstream repository for its copyright notice.
