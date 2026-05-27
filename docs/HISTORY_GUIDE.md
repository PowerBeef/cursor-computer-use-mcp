# Code change history guide

`docs/histories/` records **completed** code-change tasks. Pure Q&A, research, or analysis does not need a history unless you actually changed the repository.

## Requirements

- Each completed code-change task should have a history file, or extend an existing one for the same task.
- You may compress the user request but keep what mattered.
- Do not put secrets, local paths, keys, or raw log dumps in histories.
- For multi-session work on one task, keep one history file; do not duplicate.

## Layout and naming

- Directory: `docs/histories/YYYY-MM/`
- Filename: `YYYYMMDD-HHmm-task-slug.md`
- Template: [histories/template.md](histories/template.md)

Example:

```text
docs/histories/
  2026-04/
    20260408-1430-bootstrap-template.md
```

## What to include

- The user request (verbatim or a redacted summary).
- Main code and documentation changes.
- Design rationale—why this approach.
- The most important files touched.
