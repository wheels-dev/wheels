# Phase 2: Core CLI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `wheels test` work with zero setup for both framework contributors and app developers. Update `lucee.json` with SQLite datasources. Update documentation.

**Architecture:** The `cli/lucli/Module.cfc` already has a working `test` command that makes HTTP calls to a running server. We enhance it to: (1) auto-start a temporary server if none running, (2) detect core vs app tests, (3) support CI output formats. We also commit the `lucee.json` with `{project}` datasource paths.

**Tech Stack:** CFML (Module.cfc), shell scripting (test-local.sh), Markdown (CLAUDE.md)

**Repo:** `/Users/peter/GitHub/wheels-dev/wheels`

---

### Task 1: Update lucee.json with SQLite datasources

**Files:**
- Modify: `lucee.json`

- [ ] **Step 1: Update lucee.json**

Replace the current `lucee.json` (which has empty datasources) with the version that includes SQLite datasources using `{project}` placeholder. This was already validated end-to-end in Phase 1 Task 4.

- [ ] **Step 2: Update tools/ci/lucee.ci.json to match**

The CI config should also use `{project}` placeholder now that LuCLI resolves it (once the LuCLI PR lands). For backward compatibility, keep the CI config as-is for now — it works because SQLite resolves relative paths from the working directory in CI.

- [ ] **Step 3: Add db files to .gitignore**

Ensure `*.db` files are in `.gitignore` so SQLite databases aren't committed.

- [ ] **Step 4: Commit**

---

### Task 2: Create tools/test-local.sh convenience script

A script that works TODAY (before Phase 1 LuCLI PRs land) by using `sed` to resolve `{project}` and handling the full setup.

**Files:**
- Create: `tools/test-local.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Run Wheels core tests locally via LuCLI + SQLite
# Usage: bash tools/test-local.sh [test-directory]
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8080}"
FILTER="${1:-}"

# ... setup, start server, run tests, report results
```

- [ ] **Step 2: Make executable and test**
- [ ] **Step 3: Commit**

---

### Task 3: Enhance wheels test command in Module.cfc

**Files:**
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Add --ci flag support**

In the `test()` function, parse `--ci` flag. When set, use `--format=junit` and exit with non-zero on failures.

- [ ] **Step 2: Add core vs app test detection**

Add `--core` flag. When running in the framework repo (detected by `vendor/wheels/tests/` existence), default to core tests URL (`/wheels/core/tests`). Otherwise default to app tests (`/wheels/app/tests`).

- [ ] **Step 3: Add --db flag**

Parse `--db=sqlite` (default) to pass the database parameter to the test URL.

- [ ] **Step 4: Commit**

---

### Task 4: Update CLAUDE.md with new local testing workflow

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add LuCLI local testing section**

Add a new section after the Docker testing section that documents the LuCLI-based workflow as the recommended approach.

- [ ] **Step 2: Commit**

---

### Task 5: Update tools/ci to use the same lucee.json

**Files:**
- Modify: `.github/workflows/pr.yml`

- [ ] **Step 1: Remove the cp lucee.ci.json lucee.json step**

Once `lucee.json` in the repo has SQLite datasources, CI no longer needs to overlay the CI config. The main `lucee.json` IS the config.

NOTE: Only do this AFTER the LuCLI `{project}` PR lands. For now, document this as a future step.

- [ ] **Step 2: Commit**
