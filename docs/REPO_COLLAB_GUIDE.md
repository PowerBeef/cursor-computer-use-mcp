# Repository collaboration guide

This document defines default collaboration for an agent-first repository. Stack-specific constraints belong in focused docs nearby; do not turn this file into a catch-all.

## Development principles

- Prefer simple, clear, observable solutions over hard-to-maintain complexity.
- Organize the repo so agents can read and execute it; knowledge that lives only in chat is effectively missing.
- Update code, docs, tests, config, and release records together when behavior changes.
- If agents repeatedly fail the same way, fix environment, scaffolding, or rules—not “try another prompt.”
- When fixing a bug, strengthen tests and docs so the same class of issue is less likely to recur.

## Documentation discipline

- [AGENTS.md](../AGENTS.md) is navigation only; do not pile rules there.
- [docs/](README.md) is the canonical source for repository knowledge.
- When behavior changes, update the relevant doc in the same change.
- Use relative paths for files, directories, scripts, and links—never machine-specific absolute paths.
- Prefer new, bounded docs over growing one giant document.

## Git and review

- Keep commits scoped and accurately described.
- Sync with the remote before `git push` so you do not push stale branch state.
- Before submit or PR, confirm docs, examples, scripts, and histories reflect the final state.
- For complex or high-risk work, add an execution plan under `docs/exec-plans/`.
- In review, cite repository files; do not rely on private context.

## Testing and validation

- Substantive code changes should leave the repo easier to verify than before.
- Prefer commands and scripts that anyone can run from the repo root.
- If the project has a UI, it should be startable and verifiable locally.
- If you rely on logs, metrics, or traces, document how to access them locally or in CI.
- Repository CI should run even before a full product build pipeline exists.

## CI/CD and delivery

- CI should guard readability and basic security early; do not defer it until the project is large.
- CD skeletons should produce clear artifacts and provenance before assuming a deploy target.
- When adding a real stack, extend existing pipelines instead of one-off bypass scripts.

## Configuration hygiene

- Example config should match real defaults where possible.
- Document required environment variables and external dependencies.
- Script critical setup steps; do not hide them only in a README corner.
