# Detach from domdomegg/computer-use-mcp (GitHub fork network)

GitHub still shows **forked from domdomegg/computer-use-mcp** until you leave the fork network. This is metadata on GitHub, not something `git` can change locally.

## Eligibility (this repository)

| Check | Status |
|-------|--------|
| Public | Yes |
| Size | Under 1 GB |
| Child forks | None |

## Recommended: Leave fork network (keeps issues/PRs/stars)

1. Open [Repository settings → General](https://github.com/PowerBeef/cursor-computer-use-mcp/settings)
2. Scroll to **Danger Zone** → **Leave fork network**
3. Confirm the warnings
4. Type `cursor-computer-use-mcp` and click **Leave fork network**

Reference: [Detaching a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/detaching-a-fork)

## Verify

```bash
gh repo view PowerBeef/cursor-computer-use-mcp --json isFork,parent
```

Expect: `"isFork": false` and no `parent`.

The compare banner vs `domdomegg/computer-use-mcp` should disappear on the repo home page.

## Local git (unchanged)

```text
origin   → PowerBeef/cursor-computer-use-mcp
upstream → iFurySt/open-codex-computer-use
```

Pulling open-codex-computer-use changes:

```bash
git fetch upstream
git rebase upstream/main
```

## If “Leave fork network” is missing

Use GitHub’s [manual detach](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/detaching-a-fork#manually-leaving-the-fork-network): bare clone, delete repo, create a **new** repo (do not use the Fork button), mirror-push. This removes open issues/PRs on GitHub.

There is no public REST or GraphQL API for this action.
