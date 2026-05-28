# 2026-05-28 14:10 — Prep first Cairn npm publish (0.2.0)

## Why

After the rebrand to Cairn, the next followup in [docs/REBRAND.md](../../REBRAND.md) was publishing the npm package. A pre-flight check surfaced blockers that had to be resolved before any tag push:

- `cairn-computer-use` — available on npm (good; this is our package).
- `cairn-mcp` — **already owned** by an unrelated project (`tommoman`, cairn.fyi, v0.2.1). Our build set published both `cairn-computer-use` and `cairn-mcp`, so a publish run would have failed on the second name.
- `cairn` — taken by an unrelated React Native styling library; only relevant as our *binary* alias, not a package name.
- Local box has no Go toolchain and is not logged into npm, so the cross-platform build/publish must run in CI (the `macos-26` release runner has Go).

User decisions: drop `cairn-mcp` from the published set (keep it as a bin alias), and publish via the CI tag path. Target version `0.2.0` (first release under the Cairn name).

## What changed

### npm package set

- [scripts/npm/build-packages.mjs](../../../scripts/npm/build-packages.mjs): `metaPackageNames` reduced to `["cairn-computer-use"]`. The `cairn` and `cairn-mcp` `bin` entries inside the package are unchanged (still both launch the same Node launcher); only the standalone `cairn-mcp` npm *package* is no longer staged or published.

### Bundle discovery

- [packages/CairnKit/Sources/CairnKit/Permissions.swift](../../../packages/CairnKit/Sources/CairnKit/Permissions.swift): `PermissionSupport.npmPackageNames` now searches `cairn-computer-use` (the real global install dir) plus the legacy `open-codex-computer-use-mcp`. Previously it listed `cairn` / `cairn-mcp`, which are now unrelated third-party packages and would never contain `Cairn.app`. The existing permission-resolution tests pass explicit URLs, so they were unaffected.

### Version bump to 0.2.0

- [plugins/cairn/.cursor-plugin/plugin.json](../../../plugins/cairn/.cursor-plugin/plugin.json) — npm version source read by `build-packages.mjs`.
- [packages/CairnKit/Sources/CairnKit/CairnVersion.swift](../../../packages/CairnKit/Sources/CairnKit/CairnVersion.swift) — `cairnVersion`.
- [apps/CairnSmokeSuite/Sources/CairnSmokeSuite/main.swift](../../../apps/CairnSmokeSuite/Sources/CairnSmokeSuite/main.swift) — smoke client's self-reported `clientInfo.version`.
- The two `"0.1.51"` strings in `CairnKitTests.swift` are mock `clientInfo` for a fake client named `"test"` (assertions only check `"name":"cairn"`), so they were left as test inputs, not bumped.

### Docs

- [docs/REBRAND.md](../../REBRAND.md): clarified that `cairn-computer-use` is the single published package and `cairn` / `cairn-mcp` are bin aliases only; rewrote the npm-publish followup with the concrete CI path (NPM_TOKEN for the first publish of a new name, trusted publisher after).
- [docs/CICD.md](../../CICD.md): dropped the `cairn-mcp-<version>.tgz` release artifact line.
- [docs/releases/feature-release-notes.md](../feature-release-notes.md): added the `0.2.0` entry.

## Verification

- `node --check` on both npm scripts ✔
- `swift build` ✔
- `swift test` ✔ 139/139
- `node --test scripts/install-config-helper.test.mjs` ✔ 2/2
- `./scripts/check-docs.sh` ✔
- Full `npm run npm:build` was **not** run locally (no Go toolchain); the cross-platform build + publish runs on the CI `macos-26` runner.

## How to actually publish (next step, manual)

1. Ensure the GitHub repo has an `NPM_TOKEN` secret (granular automation token with publish access for `cairn-computer-use`) — required for the first publish of a brand-new package name.
2. Push a `v0.2.0` tag. The [release workflow](../../../.github/workflows/release.yml) builds the universal `Cairn.app` + Linux/Windows Go runtimes, stages `cairn-computer-use`, and publishes it.
3. After the first publish, optionally attach an npm trusted publisher pointing at the repo + `release.yml` so future releases use OIDC provenance and the token becomes optional.

## Not done here

- No tag pushed and nothing published — this commit is repo prep only.
- GitHub repo rename to `PowerBeef/cairn-computer-use` is still pending (followup 2 in REBRAND.md) and makes provenance cleaner.
