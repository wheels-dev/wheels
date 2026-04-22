# Issue #1945: LuCLI: update Homebrew formula for LuCLI

## Verdict
CLOSE — already shipped.

## Summary
The Homebrew formula at `wheels-dev/homebrew-wheels` was rewritten to use LuCLI instead of CommandBox in commit `b2b49c0` ("feat: rewrite formula for LuCLI-based wheels CLI", PR #2), with follow-ups to wire in the module tarball (`d76af45`), pin LuCLI 0.3.7 + module 4.0.0-SNAPSHOT+1523 (`cf9b215`, `31891e8`), and fix the JAVA_HOME / LUCLI_HOME wrapper (`eb7fb37`). The blocking issue #1947 (module distribution) is CLOSED. No further action is required for the formula migration itself.

## Root cause
Issue predates the rewrite. Current state confirms the work is done:

- `~/GitHub/wheels-dev/homebrew-wheels/Formula/wheels.rb:1-87` — formula downloads LuCLI release binary (macOS/Linux branches), stages a `wheels_module` resource from the Wheels GitHub release tarball, depends on `openjdk@21`, and writes a wrapper that sets `LUCLI_HOME=~/.wheels` and `exec`s the LuCLI binary. No `commandbox` dependency, no `box wheels` call, no arg conversion.
- `Formula/wheels.rb:6-7` — `LUCLI_VERSION = "0.3.7"`, `MODULE_VERSION = "4.0.0-SNAPSHOT+1523"` (tracks the two versions independently, as noted in memory `reference_distribution_repos.md`).
- `Formula/wheels.rb:42-65` — wrapper syncs the bundled module tarball into `~/.wheels/modules/wheels/` on first run or when `.module-version` changes, then `exec`s LuCLI. This replaces the approach suggested in the original issue (`lucli modules install wheels --url ...` at `post_install`) with a bundled-resource approach that works offline and in sandboxed CI.
- `.github/workflows/auto-update.yml` is present (10 KiB) and guards against empty versions / 404s (`822a1ac`). Daily auto-PR cadence matches the Chocolatey counterpart (memory note: 8am UTC brew, 9am UTC choco).
- Issue #1947 (`LuCLI: module distribution`) is CLOSED — the blocker identified in the bot's analysis comment is resolved.
- README.md at the tap repo already documents the LuCLI-based install flow (`brew tap wheels-dev/wheels && brew install wheels`, requires Java 21).

The only deviation from the original issue proposal: module is shipped as a versioned tarball resource rather than installed via `lucli modules install` at `post_install` time. This is a better fit for Homebrew's sandboxed install phase (no network in `post_install`) and matches what is actually in production.

## Files to change
None. For the closing comment on the issue, reference:

- `wheels-dev/homebrew-wheels` @ `b2b49c0` (formula rewrite)
- `wheels-dev/homebrew-wheels` @ `d76af45` (snapshot tarball wiring)
- `wheels-dev/homebrew-wheels` @ `cf9b215` / `31891e8` (version pins)
- `wheels-dev/homebrew-wheels` @ `eb7fb37` (wrapper fix)
- `wheels-dev/homebrew-wheels` @ `53d542a` + `822a1ac` (auto-update CI)
- `wheels-dev/homebrew-wheels` PR #2 (peter/rewrite-formula-lucli)
- Closed: wheels-dev/wheels#1947

## Implementation steps
1. Smoke-test the current formula on a clean environment (optional sanity check before closing):
   ```bash
   brew untap wheels-dev/wheels 2>/dev/null; brew uninstall wheels 2>/dev/null
   brew tap wheels-dev/wheels
   brew install wheels
   wheels --version     # expect a semver string
   wheels info          # expect LuCLI banner with Wheels branding
   ls ~/.wheels/modules/wheels/Module.cfc    # module was synced
   ```
2. Post a closing comment on wheels-dev/wheels#1945 that references the commits/PR above and links to #1947 (closed) so the audit trail is intact.
3. `gh issue close 1945 --repo wheels-dev/wheels --reason completed --comment "Shipped in wheels-dev/homebrew-wheels#2 (b2b49c0). Module distribution blocker #1947 closed. Formula tracks LuCLI 0.3.7 and module 4.0.0-SNAPSHOT+1523 via versioned resources, with daily auto-update workflow."`
4. Leave the parent tracking issue #1942 open; it also tracks #1946 (Chocolatey) and other Phase 4 items.

## Testing
- `brew install wheels` end-to-end on macOS (arm64 + x86_64 if feasible) and Linux (GitHub Actions `ubuntu-latest` runner already covered by `ci.yml`).
- `wheels --version`, `wheels server start`, `wheels new tmpapp` should all work without `box` present on `PATH`.
- Verify `~/.wheels/modules/wheels/.module-version` matches `MODULE_VERSION` in the formula after install.
- Confirm `ci.yml` is green on `main` (brew audit + brew install smoke) — already passing per recent commit history.
- Confirm `auto-update.yml` last run succeeded in GitHub Actions UI; inspect the most recent auto-PR for correct sha256 updates.

## Risk & dependencies
- **Blocker status:** #1947 (module distribution) is CLOSED — the precondition the bot analysis flagged is resolved. Formula uses versioned release tarballs, not `lucli modules install --url`, so it is not coupled to registry-style distribution at all.
- **LuCLI Homebrew dependency:** The original issue proposed `depends_on "lucli"`. The shipped approach sidesteps this by downloading the LuCLI release binary directly as the formula's primary asset — no separate `lucli` formula needed. Net safer against upstream tap availability.
- **Distribution / release coupling:** Formula is pinned to a specific `MODULE_VERSION` including snapshot build metadata (`4.0.0-SNAPSHOT+1523`). When v4.0 GA ships, the auto-update workflow must either (a) pick up the GA tag correctly or (b) be manually bumped. Watch the first GA auto-PR carefully.
- **Cross-platform:** Formula has separate macOS/Linux URL + sha256 pairs. Any LuCLI release that ships only one platform will break the auto-update bot (hence the `822a1ac` guard against empty versions / 404s).
- **Chocolatey parity:** #1946 is the Windows equivalent and should be audited in a separate triage pass — same resolution pattern likely applies.
- **Brand note:** Tap repo CLAUDE.md / README still describe "Wheels" correctly (not "CFWheels"). No drift.

## Effort estimate
S — closing action + optional smoke test. No code changes in this repo or the tap repo required.
