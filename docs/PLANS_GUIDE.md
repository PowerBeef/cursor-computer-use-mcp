# Execution plan guide

Use execution plans for work that exceeds one chat turn, needs multiple commits, or carries meaningful risk.

## When to create a plan

- The task spans several commits or work sessions.
- The change touches architecture, protocols, migrations, or other high-risk areas.
- You need staged validation, rollback thinking, or a record of key decisions.
- Multiple people or agents may work on it over time.

## Where plans live

- In progress: `docs/exec-plans/active/`
- Completed: `docs/exec-plans/completed/`
- Template: [exec-plans/templates/execution-plan.md](exec-plans/templates/execution-plan.md)
- Deferred debt: [exec-plans/tech-debt-tracker.md](exec-plans/tech-debt-tracker.md)

## Maintenance

- State goals, scope, constraints, risks, and how you will verify success.
- Record progress and decisions in the repo, not only in chat.
- Update status as the plan moves.
- Close, archive, or remove stale plans so `active/` stays trustworthy.
