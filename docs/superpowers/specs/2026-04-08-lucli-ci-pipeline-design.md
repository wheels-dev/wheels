# LuCLI-Based CI Pipeline Design

## Summary

Replace the CommandBox Docker-based CI pipeline with a fast LuCLI-native pipeline. Primary CI (PRs and develop pushes) uses LuCLI to start Lucee 7 directly on the GitHub runner with SQLite — targeting ~2-3 minute cycle times instead of 40+ minutes. The existing multi-engine Docker Compose matrix moves to a separate non-blocking workflow on a weekly cron + manual dispatch.

## Motivation

The current CI runs 5 CFML engines x 7 databases through Docker Compose on every push to develop. This takes 30-40 minutes and cross-engine differences increasingly block development velocity. Lucee 7 + SQLite is the primary supported platform going forward. Other engines are secondary — monitored for compatibility but not blocking.

## Architecture

### Three Workflows

| File | Trigger | Purpose | Blocking? |
|------|---------|---------|-----------|
| `pr.yml` | PRs to develop | Fast test + commit lint | Yes |
| `snapshot.yml` | Push to develop | Fast test -> build -> sync docs | Yes (gates release) |
| `compat-matrix.yml` | Weekly cron (Sun 02:00 UTC) + `workflow_dispatch` | Full engine x DB matrix | No (informational) |

### Fast CI Flow (pr.yml / snapshot.yml)

```
checkout -> setup-java@v4 (JDK 21) -> install LuCLI binary
  -> install wheels module -> download SQLite JDBC
  -> lucli server start (Lucee 7, port 60007)
  -> wait for ready -> run tests (curl to test endpoint)
  -> parse results -> upload artifacts
```

Runs on `ubuntu-latest`. No Docker. LuCLI starts Lucee natively on the runner using the bundled `lucee.jar` that CommandBox would normally manage — but LuCLI does it directly.

### Compatibility Matrix (compat-matrix.yml)

The current `tests.yml` content, relocated and re-triggered:
- `schedule: cron: '0 2 * * 0'` (Sunday 02:00 UTC)
- `workflow_dispatch` with optional inputs for engine/DB filtering
- All 5 engines (lucee6, lucee7, adobe2023, adobe2025, boxlang)
- All databases per engine (mysql, postgres, sqlserver, h2, cockroachdb, oracle, sqlite)
- `continue-on-error: true` at the job level
- Slack notification on completion with summary
- No downstream jobs (no build, no docs sync)

### Snapshot Pipeline Chain

```
snapshot.yml:
  fast-test (Lucee 7 + SQLite via LuCLI)
    -> build (publish to ForgeBox)
      -> sync-docs (push to wheels.dev)
```

Build and sync-docs only run if fast-test passes.

## LuCLI Installation in CI

```bash
LUCLI_VERSION="0.3.3"
curl -sL "https://github.com/cybersonic/LuCLI/releases/download/v${LUCLI_VERSION}/lucli-${LUCLI_VERSION}-linux" \
  -o /usr/local/bin/lucli
chmod +x /usr/local/bin/lucli
```

The wheels module is installed from the distribution repo:
```bash
lucli modules install wheels --url https://github.com/wheels-dev/wheels-cli-lucli
```

## Server Start Strategy

LuCLI starts Lucee 7 directly on the runner JVM — no Docker container. The test suite source is the checked-out repo itself.

Requirements:
- JDK 21 (pre-installed on GitHub runners, pinned via `setup-java`)
- SQLite JDBC JAR downloaded into Lucee's classpath
- `lucee.json` or server config pointing to `public/` as webroot
- Non-interactive/background mode for CI

## Test Execution

Tests are run via HTTP against the running Lucee server:
```bash
curl -s -o results.json --max-time 300 \
  "http://localhost:60007/wheels/core/tests?db=sqlite&format=json"
```

Results are parsed for pass/fail/error counts. JUnit XML is generated for GitHub test annotations via `actions/upload-artifact` and the existing Publish Test Results job.

## Files Changed

| Action | File |
|--------|------|
| Rewrite | `.github/workflows/pr.yml` |
| Rewrite | `.github/workflows/snapshot.yml` |
| Rename + modify | `.github/workflows/tests.yml` -> `.github/workflows/compat-matrix.yml` |
| No change | `.github/workflows/release.yml` |
| No change | `.github/workflows/docs-sync.yml` |

## Rollback

If LuCLI-based CI has issues, revert to the previous `pr.yml` / `snapshot.yml` which used Docker Compose. The `compat-matrix.yml` can serve as the primary test workflow temporarily since it contains the full matrix.

## Open Questions

- Does `lucli server start` work headlessly with `--background` or equivalent flag for CI? Need to verify the exact CLI flags.
- Does LuCLI's wheels module `test` command parse results and return a proper exit code, or should CI use `curl` directly?
- SQLite JDBC JAR placement — where does LuCLI-managed Lucee look for additional JARs?
