---
status: skeleton
slot: post 5 (week 2–3; paired with contributor-focused outreach)
target_length: 1100–1400 words
---

# LuCLI and the Zero-Docker Dev Experience

**Subhead / dek:** *Sixty-second test runs, one native binary, and a multi-phase migration that quietly transformed how Wheels is built.*

**Target audience:**
- CFML developers who gave up on `box test` → Docker matrix runs taking 20+ minutes
- Contributors bounced off the project by Docker setup friction
- Internal team tracking the LuCLI-as-strategic-direction arc
- Framework authors curious about the Ortus-independence strategy

**Lead paragraph intent:**
- For a decade, running the Wheels test suite meant Docker, a CommandBox server, and patience.
- Today, it means one shell script, SQLite, and 60 seconds.
- This is the LuCLI story — what it is, how the migration went, and what it unlocks.

## Sections

### 1. "Why Docker was the wrong default for the inner loop"
- Docker was the right answer for cross-engine CI (Lucee 5/6/7 × Adobe 2018/2021/2023/2025 × 7 databases).
- Docker is the wrong answer for the inner dev loop. A failing test shouldn't take 90 seconds to confirm.
- The 2024/2025 CFML landscape shifted: Lucee 7 + LuCLI (Lucee-as-a-CLI) became mature enough to support a pure-Java, zero-Docker inner loop.

### 2. What LuCLI is
- A single binary (`lucli`) that runs Lucee directly without CommandBox/Ortus infrastructure.
- Starts a CFML-capable server, runs a script, or drops into a REPL.
- Brew-installable on macOS; direct-download tarballs for Linux/Windows.
- Frame: "Node.js for CFML" — single binary, fast startup, scriptable.

### 3. The migration arc — Phase 1 through Phase 4
- **Phase 1** (pre-4.0) — LuCLI matures to production-readiness ([project_lucli_phase1.md](https://github.com/wheels-dev/wheels/blob/develop/)).
- **Phase 2** ([#2063](https://github.com/wheels-dev/wheels/pull/2063)) — local testing without Docker. `tools/test-local.sh` ships.
- **Phase 2 service layer + MCP annotations** ([#1941](https://github.com/wheels-dev/wheels/pull/1941)).
- **LuCLI-native CI** ([#2032](https://github.com/wheels-dev/wheels/pull/2032)) — Lucee 7 + SQLite in CI for every PR.
- **Phase 3-4** ([#2065](https://github.com/wheels-dev/wheels/pull/2065)) — in-process service invocation; scaffold + seed as library calls, not shell-outs.
- **Tier 1 commands ported to LuCLI** ([#2092](https://github.com/wheels-dev/wheels/pull/2092)) + **LuCLI module distribution** ([#2018](https://github.com/wheels-dev/wheels/pull/2018)).

### 4. What it feels like now
- `brew install lucli` (one time).
- `bash tools/test-local.sh` — full core suite, ~60s on a developer laptop.
- `bash tools/test-local.sh security` — subset, ~5s.
- REPL: `lucli server run --port=8080`, then `curl` or a browser.
- CI runs the same pipeline. Local == CI.

### 5. Why the frameworks team made this a strategic choice
- **Reduced Ortus dependency** — Wheels controls its own testing and tooling story end-to-end.
- **Optimized for AI-augmented dev** — fast feedback loops matter more in an era where iteration rate is the constraint.
- **Lower barrier to contribution** — "install Docker, install CommandBox, docker compose up -d lucee6, wait..." becomes "install lucli, run the script."
- Not a rejection of Ortus tools — CommandBox, TestBox-era specs, and the rest continue to work. This is a complementary path.

### 6. Cross-engine testing still matters
- LuCLI inner loop = Lucee 7 + SQLite. That covers ~95% of real bugs.
- The other 5% (Adobe CF quirks, database-specific SQL) still run in Docker-based CI on a schedule.
- Best practice: push early, push often; let Docker CI catch the cross-engine edge cases.

### 7. What ships with the Wheels CLI in 4.0
- `wheels new` — scaffold app.
- `wheels g model/controller/scaffold` — generators.
- `wheels test run` — LuCLI-native.
- `wheels dbmigrate latest / up / down / info / diff` — migrations including auto-diff.
- `wheels db:seed` — convention-based seeding.
- `wheels jobs work/status/retry/purge/monitor` — background jobs.
- `wheels browser:install` — Playwright JARs + Chromium.
- `wheels server start/stop/status` — dev server wrapper.

### 8. What's still coming
- Full command-set parity with CommandBox-era `wheels`.
- More in-process service invocation (fewer process fork boundaries).
- Per-OS packaging polish.

## Code / config snippets to include

```bash
# First-time setup (one-time)
brew install lucli                # or download from GitHub releases
brew install openjdk@21           # Java 21 required

# Inner loop — the 60s test run
cd /path/to/wheels
bash tools/test-local.sh          # all core tests
bash tools/test-local.sh model    # model tests only
bash tools/test-local.sh security # security tests only
```

```bash
# Manual server mode (for ad-hoc curl / browser testing)
sqlite3 wheelstestdb.db "SELECT 1;"
sqlite3 wheelstestdb_tenant_b.db "SELECT 1;"
lucli server run --port=8080

# In another terminal
curl -s "http://localhost:8080/?reload=true&password=wheels"
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail')"
```

```bash
# CI runs the same commands the developer does
# .github/workflows/pr.yml (simplified)
- run: bash tools/test-local.sh
```

## Suggested visuals

- **Timeline:** Phase 1 → Phase 2 → Phase 3-4, with dates and PR numbers. Shows the 14-week transformation.
- **Before/after bar:** "Time to first test result." Docker-first vs LuCLI-first. Aim for a 20x or 30x gap — honest and striking.
- **Screenshot:** `bash tools/test-local.sh` terminal output showing 2667 tests pass in 60s.

## Outro / CTA

- "Clone, install lucli, run the test script. You'll know you're onboarded in under a minute."
- Link to the contributing guide.
- Plug the `wheels-cli-lucli` repo.
- Note that the Phase 2 validation (2667 tests passing) confirms the migration is production-ready.

## Citations (must link in final post)

- [Phase 2 PR #2063](https://github.com/wheels-dev/wheels/pull/2063)
- [LuCLI CI PR #2032](https://github.com/wheels-dev/wheels/pull/2032)
- [Phase 3-4 PR #2065](https://github.com/wheels-dev/wheels/pull/2065)
- [LuCLI module distribution PR #2018](https://github.com/wheels-dev/wheels/pull/2018)
- [Tier 1 commands PR #2092](https://github.com/wheels-dev/wheels/pull/2092)
- [LuCLI repo](https://github.com/bpamiri/LuCLI)
- CLAUDE.md "Running Tests Locally (LuCLI — Recommended)" section
