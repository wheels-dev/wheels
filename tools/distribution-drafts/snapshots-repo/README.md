# wheels-snapshots

Pre-release snapshot artifacts of the [Wheels framework](https://wheels.dev),
published from `wheels-dev/wheels`'s `develop` branch on every merge.

**This repository contains no source code.** Releases here are produced by CI
in the source repo — see [`publish-snapshot.yml`](https://github.com/wheels-dev/wheels/blob/develop/.github/workflows/publish-snapshot.yml).

## What's here

Each snapshot is a GitHub Release tagged `v<version>-snapshot.<run>`, e.g.
`v4.0.1-snapshot.1700`. Each release attaches:

| Asset | Purpose |
|---|---|
| `wheels-cli-<version>.zip` | LuCLI module — what brew/scoop stage as the CLI |
| `wheels-core-<version>.zip` | Framework source — what `wheels new` copies into `vendor/wheels/` |
| `*.md5`, `*.sha512` | Verification |

## How to install

```bash
brew install wheels-be      # macOS / Linux (Homebrew)
scoop install wheels-be     # Windows (Scoop)
```

The `wheels-be` package across all supported package managers tracks this
repo's `releases/latest` (which is filtered to pre-releases since this repo
publishes nothing else).

## Why a separate repo

Snapshots churn at ~200-500/year. Hosting them on the main repo's Releases page
would drown the GA tags (~6-12/year). This repo also auto-deletes snapshots
older than 30 days (see [`.github/workflows/cleanup-old-snapshots.yml`](.github/workflows/cleanup-old-snapshots.yml))
without touching any GA history.

## Lifecycle

1. PR lands on `wheels-dev/wheels`'s `develop` branch.
2. `publish-snapshot.yml` builds artifacts, opens a release here with
   `prerelease: true`.
3. `repository_dispatch` fires on `wheels-dev/homebrew-wheels` (and
   `wheels-dev/scoop-wheels` once it exists), which auto-bumps the
   corresponding formula via PR.
4. Tap CI validates the install path. Maintainer rubberstamps within minutes.
5. `brew upgrade wheels-be` (or `scoop update wheels-be`) lands the new build
   on user machines.

Total time from `wheels-dev/wheels` PR merge to user-installable: ~10 minutes
when the dispatch token is configured, ~24 hours when falling back to the
cron-based discovery path.

## Reporting issues

Don't open issues here. Open them on
[wheels-dev/wheels](https://github.com/wheels-dev/wheels/issues) — that's
where the source lives. Mention the snapshot version (`wheels --version`)
in the report.
