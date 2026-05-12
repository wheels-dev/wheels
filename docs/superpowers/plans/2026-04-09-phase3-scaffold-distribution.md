# Phase 3: Scaffold & Distribution — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** New developers go from `brew install wheels` to running app in under 2 minutes. `wheels new myapp` scaffolds a complete project with SQLite pre-wired.

**Architecture:** The `cli/lucli/Module.cfc` already has a `new` command and scaffold templates in `cli/lucli/templates/app/`. We update the scaffold to include SQLite datasources, environment-based DB naming, and a `.env` with sensible defaults. The Homebrew/Chocolatey formulae are rewritten to install LuCLI as `wheels`.

**Tech Stack:** CFML (scaffold templates), Ruby (Homebrew formula), PowerShell (Chocolatey)

**Prerequisites:** Phase 1 LuCLI PRs merged (cybersonic/LuCLI#48, #49, #50)

**Repos:**
- `/Users/peter/GitHub/wheels-dev/wheels` — scaffold templates
- `/Users/peter/GitHub/wheels-dev/homebrew-wheels` — Homebrew formula
- `/Users/peter/GitHub/wheels-dev/chocolatey-wheels` — Chocolatey package

---

### Task 1: Update scaffold lucee.json template

The scaffold template at `cli/lucli/templates/app/lucee.json` needs SQLite datasources with `{project}` paths, matching the pattern established in Phase 2.

**Files:**
- Modify: `cli/lucli/templates/app/lucee.json`

- [ ] Update datasource configuration to include `development` and `test` SQLite databases
- [ ] Use `{project}/db/` directory for database files (Rails convention)
- [ ] Set default port to 8080
- [ ] Set admin password from template variable `{{reloadPassword}}`
- [ ] Commit

---

### Task 2: Update scaffold .env template

**Files:**
- Modify: `cli/lucli/templates/app/_env`

- [ ] Add `RELOAD_PASSWORD=<random>` (generated during scaffold)
- [ ] Add `WHEELS_ENV=development`
- [ ] Add `WHEELS_DATASOURCE=wheelstestdb_sqlite` (or app-name-based)
- [ ] Commit

---

### Task 3: Update `wheels new` command to create SQLite databases

**Files:**
- Modify: `cli/lucli/Module.cfc` (the `newProject` function)

- [ ] After scaffolding files, create `db/` directory
- [ ] Create `db/development.db` and `db/test.db` (empty SQLite files)
- [ ] Generate random reload password for `.env`
- [ ] Print getting-started instructions:
  ```
  Project created! Next steps:
    cd myapp
    wheels server start
    Open http://localhost:8080
  ```
- [ ] Commit

---

### Task 4: Rewrite Homebrew formula

**Files:**
- Modify: `homebrew-wheels/Formula/wheels.rb` (in the homebrew-wheels repo)

Current formula wraps CommandBox. New formula:
- [ ] Depend on `openjdk@21` (cask)
- [ ] Download LuCLI binary from GitHub releases
- [ ] Rename to `wheels` during install
- [ ] Set `-Dlucli.binary.name=wheels` in the shell wrapper
- [ ] Bundle the Wheels framework template for `wheels new`
- [ ] Test: `brew install wheels && wheels --version` shows Wheels branding
- [ ] Commit

---

### Task 5: Rewrite Chocolatey package

**Files:**
- Modify: `chocolatey-wheels/` (in the chocolatey-wheels repo)

- [ ] Download LuCLI `.bat` from GitHub releases
- [ ] Rename to `wheels.bat`
- [ ] Set binary name property
- [ ] Bundle framework template
- [ ] Test on Windows
- [ ] Commit

---

### Task 6: Update module sync workflow

**Files:**
- Modify: `.github/workflows/sync-lucli-module.yml`

- [ ] Ensure `cli/lucli/` syncs to `wheels-dev/wheels-cli-lucli` on develop push
- [ ] Include scaffold templates in the sync
- [ ] Test: merge to develop triggers sync
- [ ] Commit

---

### Task 7: End-to-end validation

- [ ] Fresh macOS machine (or clean Docker): `brew install wheels`
- [ ] `wheels new testapp && cd testapp && wheels server start`
- [ ] Verify: http://localhost:8080 shows Wheels welcome page
- [ ] `wheels generate scaffold Post title body:text`
- [ ] `wheels dbmigrate latest`
- [ ] Verify: CRUD for Posts works
- [ ] `wheels test`
- [ ] Verify: tests pass
- [ ] Total time: under 2 minutes
