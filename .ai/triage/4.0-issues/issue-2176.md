# Issue #2176: LuCLI parallel-spawn race on `lucee.json` write (framework gap #11)

## Verdict
DEFER (for Wheels 4.0 GA) — fix upstream in LuCLI, not in Wheels. Wheels-side mitigations (retry + concurrency cap) already absorb the flake; shipping 4.0 is not blocked.

## Summary
Concurrent `wheels new` / `wheels`-spawn invocations in verify-docs harness hit a non-atomic `lucee.json` write in LuCLI (`LuceeServerConfig.saveConfig` writes directly to the target file). Readers intermittently see partial/empty JSON, surfacing as `booleanValue() … searchLocal is null` or `Can't cast String [] to a value of type [Struct]`. The harness absorbs it today via retries + a 4-way concurrency cap + `continue-on-error` on the CI step.

## Root cause
Upstream in LuCLI (`~/GitHub/bpamiri/LuCLI`), `src/main/java/org/lucee/lucli/server/LuceeServerConfig.java:688-690`:

```java
public static void saveConfig(ServerConfig config, Path configFile) throws IOException {
    objectMapper.writeValue(configFile.toFile(), config);
}
```

Jackson's `writeValue(File, Object)` opens the destination file directly, truncates, and streams JSON — no temp-file + rename, no fsync, no lock. When two processes on the same project dir (or two concurrent fixture dirs that happen to contend on the same host-level Lucee state at startup) call this in parallel:

- Writer A truncates `lucee.json` and begins streaming.
- Reader B (another process's `loadConfig()` at server init) reads while A is mid-write → sees `{}`-empty or truncated JSON → deserializes `searchLocal` (Boolean field) as `null`, or deserializes an array-shaped partial as the wrong type → the runtime throws `booleanValue() … is null` or `Can't cast String[] to Struct`.

Two things compound it in the docs-verify path:
1. Each `wheels new` spawns a JVM which initializes LuCLI's config layer. 4-way parallelism in `verify-docs.mjs` means up to 4 JVMs touch config in overlapping windows.
2. Linuxbrew's wrapper shell + `posix_spawn` contention at scale also produces transient `ENOENT` on `/home/linuxbrew/.../wheels` — a related but distinct flake currently bundled under the same gap #11 retry patterns in `web/sites/guides/scripts/verify-docs/lib/fixtures.mjs` and `drivers/cli.mjs`.

CI evidence: `.github/workflows/docs-verify.yml:87-100` sets `continue-on-error: true` on `verify:docs` with the note "266/290 pass reliably; the remaining 24 are infrastructure flakes." Local serial `pnpm verify:docs` passes 290/290.

## Files to change

### Upstream (LuCLI) — the real fix
- `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/server/LuceeServerConfig.java` — rewrite `saveConfig(ServerConfig, Path)` to do an atomic write:
  1. `Path tmp = Files.createTempFile(configFile.getParent(), configFile.getFileName().toString(), ".tmp");`
  2. `objectMapper.writeValue(tmp.toFile(), config);`
  3. `try (FileChannel ch = FileChannel.open(tmp, StandardOpenOption.WRITE)) { ch.force(true); }` (fsync)
  4. `Files.move(tmp, configFile, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);` (fall back to non-atomic move + log if `AtomicMoveNotSupportedException` on exotic filesystems)
  5. `finally` clean up the tmp file on exception paths
- Optional belt-and-suspenders: wrap load/save in a `FileChannel.tryLock()` cooperative lock on a sibling lockfile (`lucee.json.lock`) for cross-process serialization when two writers truly overlap. Atomic rename alone closes the reader-sees-partial window; the lock closes the last-writer-wins race if two PRs both legitimately need to edit the same file.
- Add a focused test alongside `src/test/java/org/lucee/lucli/server/LuceeServerConfigTest.java` that spawns N threads hammering `saveConfig`/`loadConfig` on the same path and asserts no deserialization ever sees null-valued primitives or type mismatches.

### Wheels-side — version bump + remove workarounds after upstream ships
- `.github/workflows/snapshot.yml:16` — bump `LUCLI_VERSION: "0.3.3"` → version containing the fix.
- `.github/workflows/pr.yml:35` — same bump.
- `.github/workflows/deploy-ci.yml:70` — same bump.
- `wheels-dev/homebrew-wheels/Formula/wheels.rb` — bump `LUCLI_VERSION` + regenerate SHA256s (per memory note on LuCLI 1.0.0 / Lucee-org move, align with that retarget if it happens first).
- `wheels-dev/chocolatey-wheels` — same bump + checksums.
- `.github/workflows/docs-verify.yml:87-100` — remove `continue-on-error: true` on `Verify v4 docs` step; delete the explanatory comment block about framework gap #11.
- `web/sites/guides/scripts/verify-docs/verify-docs.mjs:48-55` — keep `VERIFY_DOCS_CONCURRENCY` env override but raise default from 4 → 8 (or whatever a fresh post-fix run supports reliably); prune the gap-#11 comment.
- `web/sites/guides/scripts/verify-docs/lib/fixtures.mjs:15-52` — drop the `lucee.json`-related transient patterns (`Can't cast String…`, `"engine" is null`, `ScriptEngine.put`). Keep the `spawn … ENOENT` patterns — those are a separate Linuxbrew issue, not the `lucee.json` race.
- `web/sites/guides/scripts/verify-docs/drivers/cli.mjs:20-28` — same pruning.

## Implementation steps
1. **LuCLI PR** (author: Peter, review: Mark Drew / cybersonic):
   - Implement atomic rename + fsync in `LuceeServerConfig.saveConfig`.
   - Add concurrency test.
   - Update `CHANGELOG.md` entry using LuCLI's conventions (see memory `feedback_lucli_pr_conventions.md`).
   - Open PR against `bpamiri/LuCLI` (or `lucee/LuCLI` if the org move has landed per `project_lucli_1_0_cfcamp.md`).
2. **LuCLI release**: Mark cuts a patch/minor (or ideally folds into 1.0.0 for CFCamp).
3. **Wheels version bumps**: single PR to bump `LUCLI_VERSION` in all three workflow files + Homebrew/Chocolatey formulas.
4. **Wheels cleanup PR** (can be combined with #3): remove `continue-on-error`, prune transient patterns that match the race signature, raise concurrency default. Commit scope: `ci` (touches workflows + verify-docs harness, not framework code).
5. Close #2176 referencing the LuCLI PR + release tag.

## Testing
- **LuCLI unit**: new concurrency test in `LuceeServerConfigTest.java` — 16 threads × 500 iters alternating `saveConfig`/`loadConfig` on one path, fail on any null-primitive or cast exception.
- **End-to-end (local)**: from a clean checkout, `cd web/sites/guides && VERIFY_DOCS_CONCURRENCY=8 pnpm verify:docs` should hit 290/290 across 3 consecutive runs, no retries triggered. Instrument `fixtures.mjs`/`cli.mjs` to log when the retry path fires — must be 0.
- **CI**: land the workflow change behind a feature flag PR first, watch 5 consecutive `docs-verify` runs go green without `continue-on-error` before removing the flag.

## Risk & dependencies
- Upstream dependency on LuCLI maintainer timeline. Per memory (`project_lucli_1_0_cfcamp.md`), 1.0.0 is targeted for CFCamp with a repo move to the Lucee org — this is the natural window to land the fix. If CFCamp slips, cut a 0.3.x patch.
- Atomic rename is POSIX-correct on ext4/APFS/tmpfs and NTFS (via `MoveFileEx MOVEFILE_REPLACE_EXISTING`). The fallback branch handles the rare `AtomicMoveNotSupportedException` (some NFS/SMB mounts) — callers should not silently lose data there; log + degrade to non-atomic with a warning.
- No Wheels code change is required to ship 4.0 — workarounds are already in place and 266/290 reliably passes. Removing `continue-on-error` is post-fix polish, not release-blocking.
- The Linuxbrew `posix_spawn ENOENT` flake (still in the transient pattern list after this fix) is a separate gap; do not conflate.

## Effort estimate
- LuCLI fix: **S-M** (atomic-write refactor + test). ~2-4 hours for someone with Java/Jackson familiarity; the failure mode is well understood and the fix is textbook.
- Wheels cleanup: **S** (version bump + delete workaround code). ~30 minutes.
- Total elapsed time gated by Mark's release cadence, not author effort.
