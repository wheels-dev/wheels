# Issue #2177: LuCLI — auto-detect binary name from `ProcessHandle` instead of requiring `-Dlucli.binary.name`

## Verdict
DEFER — upstream LuCLI work; Wheels-side workaround already ships.

## Summary
LuCLI currently resolves its `CliProfile` (which controls banner, home-dir name, prompt prefix, and the alias routing that makes `wheels gen model User` work) from the `lucli.binary.name` system property. That property is only set by the POSIX `lucli.sh` shell stub via `basename "$0"`; the Windows `lucli.bat` stub does not set it at all, and the GraalVM native-image binary distributed via Homebrew has no shell stub to set it either. The fix is to have LuCLI fall back to `ProcessHandle.current().info().command()` (Java 9+, already used elsewhere in the LuCLI codebase) so every distribution channel works uniformly without wrapper plumbing.

## Root cause

Three-layer problem:

1. **`CliProfile.forBinaryName()` only reads the system property.** `~/GitHub/bpamiri/LuCLI/src/main/java/org/lucee/lucli/LuCLI.java:513-515` calls `CliProfile.forBinaryName(System.getProperty("lucli.binary.name", "lucli"))`. If the property is unset, the profile silently defaults to `DefaultProfile` (i.e. `lucli` branding, `~/.lucli` home) and `prependBinaryNameIfAliased()` (LuCLI.java:584-605) short-circuits — so `wheels generate model User` is parsed as `generate model User` against the wrong root command.

2. **Only the POSIX shell stub sets the property.** `~/GitHub/bpamiri/LuCLI/src/bin/lucli.sh:75-88` derives `binary_name=$(basename "$0")`, strips `.sh`/`.exe`, and passes `-Dlucli.binary.name="$binary_name" -jar "$this_script"`. The Windows equivalent `~/GitHub/bpamiri/LuCLI/src/bin/lucli.bat:38` invokes `java -jar` with no property at all — so `wheels.bat` on Windows loses profile detection entirely.

3. **Native-image distributions have no shell stub.** The Homebrew formula `~/GitHub/wheels-dev/homebrew-wheels/Formula/wheels.rb:24-26` downloads the GraalVM native binary (`lucli-0.3.7-macos` / `-linux`) and renames it to `wheels` (`libexec.install binary => "wheels"`). The wrapper at `bin/wheels` just `exec`s the native binary — no `-D` flag passing is possible because there's no JVM invocation. Profile detection depends entirely on `argv[0]`-equivalent logic inside the process, which does not exist today.

The `lucli.sh` `basename`-based detection is the *current Wheels-side workaround* — it happens to work for a shell-stub-packaged JAR renamed to `wheels`. But it does **not** cover the Homebrew + native-image path (the primary Wheels 4.0 macOS/Linux distribution) or Windows Chocolatey. The currently shipped Homebrew formula relies on the `DefaultProfile` fallback still working "well enough" for most commands — it doesn't, because prepend-alias routing is disabled, so `wheels generate`, `wheels test`, etc. only work because LuCLI also routes unknown top-level names to `modules run <name> …` via picocli fallback. This is fragile and the banner/prompt/home-dir are still wrong.

## Files to change

**LuCLI (upstream, `~/GitHub/bpamiri/LuCLI`)** — primary fix:

- `src/main/java/org/lucee/lucli/profile/CliProfile.java` — add a new resolver method `resolveActiveBinaryName()` encapsulating the fallback chain, and change `forBinaryName()` callers (or add an overload `forCurrentProcess()`) to use it.
- `src/main/java/org/lucee/lucli/LuCLI.java` — replace the two direct reads of `System.getProperty("lucli.binary.name", "lucli")` (lines 513-515 and 585-587) with the new resolver so both profile resolution *and* `prependBinaryNameIfAliased()` use identical logic.
- `src/test/java/org/lucee/lucli/profile/CliProfileTest.java` — add coverage for the fallback order (system property wins; env var second; `ProcessHandle` third; `"lucli"` default). Mock or stub `ProcessHandle.current()` via an injectable seam (see implementation step 2).
- `src/main/resources/META-INF/native-image/` (if reflection/resource config is required for `ProcessHandle.info()` under GraalVM) — verify; `ProcessHandle` is already used by `LuceeServerManager.java` so native-image metadata is likely already complete, but the `info().command()` path should be exercised in a native-image test.
- `src/bin/lucli.sh` — keep the `-Dlucli.binary.name=…` pass-through for belt-and-braces; it's cheap, backward-compatible, and makes sandboxed/container environments where `ProcessHandle.info().command()` returns empty still work.
- `src/bin/lucli.bat` — add the Windows equivalent: `-Dlucli.binary.name=%~n0` (basename without extension). Do this regardless of the ProcessHandle work; it's a standalone Windows bug.
- `CHANGELOG.md` (LuCLI) — entry under next release.

**Wheels-side (this repo)** — no changes required once LuCLI ships, but:

- `~/GitHub/wheels-dev/homebrew-wheels/Formula/wheels.rb` — bump `LUCLI_VERSION` to the release that contains the fix. Optionally add an explicit `export LUCLI_BINARY_NAME=wheels` line in the wrapper at line 62 as a defense-in-depth (uses the new env-var fallback; harmless if unused).
- `~/GitHub/wheels-dev/chocolatey-wheels/tools/wheels.cmd` — optionally add `set LUCLI_BINARY_NAME=wheels` before the `lucli.bat` invocation (line 21) for the same reason.
- `~/GitHub/wheels-dev/chocolatey-wheels/tools/chocolateyinstall.ps1` — bump `$lucliVersion` when the fix ships.
- `~/GitHub/wheels-dev/wheels/docs/superpowers/plans/2026-04-20-guides-rewrite-phase-2b-cli-report.md:135` — update the deferred-task note to link to the LuCLI release once shipped.
- `~/GitHub/wheels-dev/wheels/docs/superpowers/plans/2026-04-09-lucli-foundation-prs.md:263, 425, 491` and `docs/superpowers/specs/2026-04-09-wheels-cli-lucli-integration-design.md:213` — update the binary-name detection notes to reflect the new precedence.

Nothing under `vendor/wheels/`, `cli/lucli/`, or `app/` changes. This is a cross-repo upstream fix.

## Implementation steps

### Phase 1 — LuCLI upstream (required)

1. **Design the resolver** in `CliProfile.java`. New static method:
   ```
   static String resolveActiveBinaryName()
   ```
   Precedence (highest to lowest):
   1. `System.getProperty("lucli.binary.name")` — explicit JVM override; wins so existing shell stubs and any direct `-D` users are unaffected. Empty/blank is treated as unset.
   2. `System.getenv("LUCLI_BINARY_NAME")` — new env-var form so native-image users and Dockerfile authors have a no-JVM path.
   3. `ProcessHandle.current().info().command().map(Paths::get).map(Path::getFileName).map(Path::toString).orElse(null)` then normalise via existing `normalizeBinaryName(...)`. Catch/suppress any `SecurityException` and linux-specific quirks (on some distros `.info().command()` returns the full argv[0] or an empty optional under `/proc` restrictions).
   4. Hard-coded fallback `"lucli"`.

   Return the *normalised* name (reuse `normalizeBinaryName`). Never return `null`.

2. **Make `ProcessHandle` injectable for tests.** Package-private seam:
   ```
   static Supplier<Optional<String>> processCommandSupplier =
       () -> ProcessHandle.current().info().command();
   ```
   Tests swap the supplier in `@BeforeEach` / `@AfterEach`. Keeps the production path zero-overhead while letting `CliProfileTest` exercise all four precedence rungs deterministically without spawning processes.

3. **Retire the duplicate reads in `LuCLI.java`.**
   - Replace line 513-515 (`activeProfile = CliProfile.forBinaryName(System.getProperty("lucli.binary.name", "lucli"));`) with `activeProfile = CliProfile.forBinaryName(CliProfile.resolveActiveBinaryName());`.
   - Replace line 585-587 in `prependBinaryNameIfAliased()` the same way.
   - Move the `resolveActiveBinaryName()` call outside both sites into a single static initialisation block run from `main()` — the value is effectively immutable once the process is live. Cache it in a `private static final String ACTIVE_BINARY_NAME` field to avoid repeatedly probing `ProcessHandle` (cheap, but has a syscall cost).

4. **Keep backwards compatibility.** Do *not* remove `forBinaryName(String)` — Wheels-dev integration tests and external consumers may call it. Add `forCurrentProcess()` as the new convenience factory:
   ```
   static CliProfile forCurrentProcess() {
       return forBinaryName(resolveActiveBinaryName());
   }
   ```

5. **Windows stub parity.** In `src/bin/lucli.bat:38`, change:
   ```
   "%JAVA_CMD%" %LUCLI_JAVA_ARGS% -jar "%~f0" %*
   ```
   to:
   ```
   "%JAVA_CMD%" %LUCLI_JAVA_ARGS% -Dlucli.binary.name=%~n0 -jar "%~f0" %*
   ```
   `%~n0` is the basename of the invoking script without extension. This fix is independent of the ProcessHandle work and should land in the same release so Windows aliasing stops being silently broken.

6. **Unit tests** in `CliProfileTest.java`:
   - `resolve_prefersSystemProperty` — set the property, stub supplier to return something else; assert property wins.
   - `resolve_fallsBackToEnvVar` — clear property, set env (use `System.getenv` mocking via the supplier pattern applied to env-lookup too, or wrap env lookup behind a `Supplier<String>` seam).
   - `resolve_fallsBackToProcessHandle` — clear property + env, stub supplier to return `/usr/local/bin/wheels`; assert `"wheels"`.
   - `resolve_defaultsToLucliWhenAllEmpty` — everything empty/null; assert `"lucli"`.
   - `resolve_normalisesProcessHandleOutput` — stub supplier with `/opt/lucli/bin/wheels.sh`; assert `"wheels"` (exercises the `.sh` strip through `normalizeBinaryName`).
   - `resolve_handlesProcessHandleException` — supplier throws; assert graceful fallback to `"lucli"` (no exception leaks).

7. **GraalVM native-image verification.** Build `lucli` and `wheels` (via `cp lucli wheels`) native binaries and confirm `./wheels --version` shows the Wheels banner. If `ProcessHandle.current().info().command()` returns an empty `Optional` under native-image (it has occasionally regressed across GraalVM versions), add `--enable-url-protocols` / `--initialize-at-run-time=java.lang.ProcessHandle` to the native-image args and retest. Document any additional reachability metadata required in `src/main/resources/META-INF/native-image/`.

8. **Changelog + release.** Cut a LuCLI patch release (e.g. `0.3.8`). Tag notes should call out:
   - New: `LUCLI_BINARY_NAME` env var accepted
   - New: auto-detection via `ProcessHandle` when neither property nor env set
   - Fix: Windows `lucli.bat` now passes `-Dlucli.binary.name`
   - Backwards-compatible: existing `-Dlucli.binary.name` overrides everything else

### Phase 2 — Wheels-side adoption (after LuCLI release)

9. **Homebrew.** In `~/GitHub/wheels-dev/homebrew-wheels/Formula/wheels.rb`:
   - Bump `LUCLI_VERSION = "0.3.8"` (or whatever ships).
   - Update both `sha256` values (fetch from the new release).
   - Add `export LUCLI_BINARY_NAME=wheels` in the wrapper between line 61 (`export JAVA_HOME`) and line 63 (`exec`) as belt-and-braces defence. Technically redundant once ProcessHandle works, but protects against users aliasing `wheels` to some other path in their shell.
   - Verify with `brew reinstall wheels && wheels --version` — banner should read "Wheels", not "LuCLI".

10. **Chocolatey.** In `~/GitHub/wheels-dev/chocolatey-wheels/`:
    - `tools/chocolateyinstall.ps1` line 5: bump `$lucliVersion = "0.3.8"`.
    - `tools/wheels.cmd` line 21: add `set "LUCLI_BINARY_NAME=wheels" &` into the `endlocal &` chain before the final invocation. Runs `wheels.cmd` → sets env → calls `lucli.bat` → `lucli.bat` now either passes the system property (step 5) *or* LuCLI picks up the env var. Either way works.
    - Rebuild the `.nupkg` via `~/GitHub/wheels-dev/build.ps1` on a Windows host and smoke-test `wheels --version`.

11. **Documentation.** Update the three plan/report files listed above to:
    - Remove the "pending upstream fix" qualifier
    - Note the `LUCLI_BINARY_NAME` env var as the canonical override for containerised/sandboxed environments
    - Cross-reference the LuCLI release

12. **Close #2177** with a note linking the LuCLI PR and tagged release.

## Testing

### LuCLI side

- **Unit:** `./gradlew test --tests CliProfileTest` — all six new cases pass.
- **JVM integration:** Rename a built shaded JAR to `wheels.jar` and run `java -jar wheels.jar --version`. With no property and no env var, `ProcessHandle.current().info().command()` returns the `java` executable path, not `wheels` — this is expected and means **JAR-mode users still need the shell stub**. Document this as a known limitation; the ProcessHandle path is primarily for native-image.
- **Shell stub:**
  ```
  cp src/bin/lucli.sh /tmp/wheels
  ./tmp/wheels --version   # should show Wheels banner, via -Dlucli.binary.name
  ```
- **Windows stub:**
  ```
  copy src\bin\lucli.bat C:\tmp\wheels.bat
  C:\tmp\wheels.bat --version
  ```
  Expect "Wheels" banner — exercises the new `%~n0` plumbing.
- **Native image:**
  ```
  ./gradlew nativeCompile
  cp build/native/nativeCompile/lucli build/native/nativeCompile/wheels
  ./build/native/nativeCompile/wheels --version
  ```
  Expect "Wheels" banner — this is the primary thing #2177 is trying to fix and the path with no shell stub.
- **Env-var path (any mode):**
  ```
  LUCLI_BINARY_NAME=wheels lucli --version
  ```
  Expect Wheels banner.
- **Explicit override (regression):**
  ```
  java -Dlucli.binary.name=wheels -jar lucli.jar --version
  ```
  Expect Wheels banner — existing integrations unchanged.

### Wheels-side

- `brew reinstall wheels && wheels --version` on macOS — expect Wheels banner.
- `brew reinstall wheels && wheels generate model User name:string` — expect module routing (no "unknown command: generate" error).
- On a fresh Linux VM: `brew install wheels && wheels --help` — expect "Wheels" in the displayed command name.
- On Windows (Chocolatey): `choco install wheels -y && wheels --version` — expect Wheels banner, no "LuCLI" leakage.
- CI: run `bash tools/test-local.sh` on this repo — nothing in `vendor/wheels/` changes, so all 2700+ tests should pass unchanged.

## Risk & dependencies

- **Upstream release required.** This issue cannot be closed from this repo alone. The LuCLI PR + tag must land first. Owner: `bpamiri/LuCLI`. Estimated lead time: one maintainer cycle.
- **Java version: safe.** `ProcessHandle` is Java 9+; Wheels requires Java 21 and LuCLI targets Java 17+. No compatibility concern.
- **GraalVM native-image reachability.** `ProcessHandle.current().info()` occasionally requires extra native-image metadata. `LuceeServerManager.java` already uses `ProcessHandle.of(pid)` so the basic reachability is configured; the `.info().command()` sub-path should be verified in native-image before release. Mitigation: fall back gracefully if the call throws — the code already does this via step 6 test.
- **Sandboxed environments** (Docker --security-opt, Kubernetes with restricted `/proc`): `.info().command()` can return an empty Optional. The `LUCLI_BINARY_NAME` env-var path provides the escape hatch for these cases; the `-D` property path already does.
- **Related issues:**
  - **#2176** — LuCLI parallel-spawn race on `lucee.json` write. Same upstream repo, independent. Could be batched into the same release if scheduling permits.
  - **#1945** — Update Homebrew formula after LuCLI Issue #1945. Already closed-ish (formula exists); this issue's Phase 2 step 9 piggybacks on that work.
  - **#1946** — Update Chocolatey package for LuCLI Issue #1946. Same shape; Phase 2 step 10 lands there.
  - **No conflict** with #2174 (SecurityHeaders hsts), #2173, or the other triaged issues.
- **Backwards compatibility:** All three pre-existing entry points (`-D` property, shell-stub basename, Windows bat) remain functional. The new ProcessHandle and env-var paths are additive. No caller is forced to change.

## Effort estimate
**M** — spread across two repos over two releases. Upstream change is small (~80 lines + 6 tests) but requires a LuCLI release cycle. Wheels-side adoption is trivial (~5 line diff across homebrew formula + chocolatey install script + one doc refresh). The native-image verification is the one thing most likely to surface a surprise.

## Recommendation on sequencing
Not 4.0-GA blocking. Ship 4.0 with the current state (Homebrew formula's renamed native-binary + `DefaultProfile` fallback works well enough that `wheels --version` and module routing function; banner is cosmetic). File the LuCLI PR in parallel and pick it up in a 4.0.1 Homebrew/Chocolatey bump. The Windows `.bat` fix (step 5) alone could be fast-tracked if any Windows users are blocked — it's a one-line change with no code review complexity.
