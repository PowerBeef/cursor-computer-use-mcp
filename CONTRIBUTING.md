# Contributing

This repository is set up for agent-first development. These rules apply to humans and agents alike.

## Cairn

When your change affects Cursor install, policy, Composer workflow, macOS 26 behavior, or benchmarks, update [docs/CURSOR.md](docs/CURSOR.md), [docs/FORK.md](docs/FORK.md), [docs/BENCHMARK.md](docs/BENCHMARK.md), and [AGENTS.md](AGENTS.md) in the same PR. See [docs/README.md](docs/README.md) for the full map.

## How we work

- Start from [AGENTS.md](AGENTS.md), then read task-specific docs.
- Keep repository knowledge in versioned files, not only in chat or tickets.
- When behavior changes, update code, docs, tests, and release/history records together.
- For large, risky, or multi-session work, add an execution plan under `docs/exec-plans/active/` first.

## Before opening a pull request

- Run `make check-docs` (and `make check-repo` when you change repo hygiene).
- For code or process changes, add or update the matching history under `docs/histories/`.
- For user-visible changes, add a release note when appropriate.
- Confirm examples, scripts, and docs match the implementation.

## Review expectations

- Prefer small, focused PRs.
- Call out risks, migration impact, and follow-ups explicitly.
- Link to the relevant plan, spec, or history when context is non-obvious.
