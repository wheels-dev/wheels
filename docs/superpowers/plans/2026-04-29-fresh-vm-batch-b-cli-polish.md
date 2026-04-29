# Fresh-VM Batch B — CLI Output Polish

> **For agentic workers:** REQUIRED SUB-SKILLs in execution order:
> 1. superpowers:test-driven-development (every fix has a failing test first)
> 2. superpowers:subagent-driven-development (recommended) OR superpowers:executing-plans for the orchestration
>
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land four small, low-risk CLI fixes from the [Fresh-VM Onboarding Findings](./2026-04-29-fresh-vm-onboarding-findings.md) triage so that a fresh-VM run of chapters 2 and 7 — and a fresh `wheels new` — produces output that matches what readers expect. After this batch, `wheels migrate` reads cleanly, `wheels test` distinguishes "all clear" from "your spec broke and we silently skipped it," `wheels reload` tells the reader its limits, and `wheels new` actually produces a directory layout that survives `git commit`.

**Architecture.** Four independent edits, each targeting one CLI surface plus a regression test. None of them depend on each other:

- **Task 1** — fix the `wheels new` scaffolder so it copies `.gitkeep` files instead of skipping them.
- **Task 2** — make the migrator emit `Chr(13) & Chr(10)` (CRLF) instead of bare `Chr(13)` so terminals don't collapse the output onto a single line.
- **Task 3** — add a "loaded N spec files" probe to the test runner output, plus a distinct "1 failed to load" line whenever TestBox's bundle count is lower than the disk count, so silent compile-time swallowing is loud and obvious.
- **Task 4** — append a one-line note to `wheels reload` output explaining that `onApplicationStart` does not re-fire.

Plus a final triage-doc-update + PR task.

**Tech Stack:** CFML/Lucee, LuCLI ScriptEngine, [LuCLI local CLI test harness](../../tools/test-cli-local.sh), [LuCLI local framework test harness](../../tools/test-local.sh). The migrator change touches `vendor/wheels/` (framework) so it lives behind the framework test suite. The `new`/`test`/`reload` changes live in `cli/lucli/` so they're covered by `tools/test-cli-local.sh`.

**Source findings:** [#2 (test runner parse-error swallow)](./2026-04-29-fresh-vm-onboarding-findings.md#2-wheels-test-reports-0-passed-when-a-spec-fails-to-compile), [#3 (migrate output formatting)](./2026-04-29-fresh-vm-onboarding-findings.md#3-wheels-migrate-output-mis-formatted-no-newlines-between-sections), [#8 (`wheels reload` doesn't re-fire `onApplicationStart`)](./2026-04-29-fresh-vm-onboarding-findings.md#8-wheels-reload-doesnt-re-fire-onapplicationstart-related-to-6), and a new sub-finding (`.gitkeep` files dropped by the scaffolder) surfaced during batch A's reconnaissance and called out at the top of the triage's "Shipped" section.

Finding #7 (`wheels destroy` argument order) was originally grouped here but already shipped via PR #2360 — exclude from this batch.

---

## Task 1: `wheels new` — copy `.gitkeep` files into the scaffolded app

**Bug.** `cli/lucli/Module.cfc::copyTemplateDir()` explicitly skips files named `.gitkeep` when walking the template tree. The comment says they "exist only to keep empty dirs in git" — which is the *whole point* of copying them. As a result, `wheels new blog` produces `blog/tests/specs/{controllers,functional,models}/` empty directories that vanish the moment the user runs `git init && git add -A && git commit -m "initial"`. The tutorial's chapter 1 file tree (verified accurate by batch A) advertises those subdirectories, but they don't survive the user's first commit.

**Files:**
- Modify: `cli/lucli/Module.cfc:4194-4242` (the `copyTemplateDir` private method — specifically the `.gitkeep` skip clause at lines 4231-4234)
- Modify or extend: `cli/lucli/tests/specs/commands/NewCommandTemplateSpec.cfc`

- [ ] **Step 1: Read the current behavior to confirm the diagnosis**

```bash
sed -n '4225,4245p' /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-b/cli/lucli/Module.cfc
```

Expected: lines 4231-4234 contain:

```cfm
// Skip .gitkeep files — they exist only to keep empty dirs in git
if (entry.name == ".gitkeep") {
    continue;
}
```

- [ ] **Step 2: Confirm the templates ship `.gitkeep` files**

```bash
find cli/lucli/templates/app/tests/specs -type f -name '.gitkeep'
```

Expected output (three lines):

```
cli/lucli/templates/app/tests/specs/controllers/.gitkeep
cli/lucli/templates/app/tests/specs/functional/.gitkeep
cli/lucli/templates/app/tests/specs/models/.gitkeep
```

- [ ] **Step 3: Write a failing regression test**

Append to `cli/lucli/tests/specs/commands/NewCommandTemplateSpec.cfc`'s `describe("wheels new template completeness", ...)` block:

```cfm
it("ships .gitkeep files in tests/specs subfolders so empty dirs survive git", () => {
    // Templates check — confirms the .gitkeep files exist on disk in the
    // template tree. Their copying is verified by the scaffold spec below.
    expect(fileExists(templateRoot & "tests/specs/controllers/.gitkeep")).toBeTrue();
    expect(fileExists(templateRoot & "tests/specs/functional/.gitkeep")).toBeTrue();
    expect(fileExists(templateRoot & "tests/specs/models/.gitkeep")).toBeTrue();
});
```

Then add a new spec at `cli/lucli/tests/specs/commands/NewCommandGitkeepSpec.cfc` that scaffolds a temporary app and asserts the `.gitkeep` files land in the output (this is the spec that actually fails today):

```cfm
component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.testHelper = new cli.lucli.tests.TestHelper();
        variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
    }

    function afterAll() {
        testHelper.cleanupTempProject(variables.tempRoot);
    }

    function run() {

        describe("wheels new — .gitkeep handling", () => {

            it("copies .gitkeep into tests/specs/{controllers,functional,models} so the dirs survive git", () => {
                // Regression: copyTemplateDir() used to skip .gitkeep entries
                // entirely, leaving empty directories that vanished on first
                // git commit. Tutorial chapter 1's file tree advertised those
                // subdirectories, so users hit "where did my tests/specs go?"
                // the first time they checked their repo into git. See batch B
                // sub-finding (2026-04-29 fresh-VM triage).
                expect(fileExists(tempRoot & "/tests/specs/controllers/.gitkeep")).toBeTrue();
                expect(fileExists(tempRoot & "/tests/specs/functional/.gitkeep")).toBeTrue();
                expect(fileExists(tempRoot & "/tests/specs/models/.gitkeep")).toBeTrue();
            });

        });

    }

}
```

- [ ] **Step 4: Run the spec and confirm it fails**

```bash
bash tools/test-cli-local.sh
```

Expected: `NewCommandGitkeepSpec` fails on all three `expect(...).toBeTrue()` assertions because `copyTemplateDir` strips the `.gitkeep` files.

- [ ] **Step 5: Apply the fix**

In `cli/lucli/Module.cfc`, modify `copyTemplateDir` (lines 4230-4240). Replace the skip clause with a copy clause:

```diff
             } else {
-                // Skip .gitkeep files — they exist only to keep empty dirs in git
-                if (entry.name == ".gitkeep") {
-                    continue;
-                }
-                // Read template, process placeholders, write to target
-                var content = fileRead(sourcePath);
-                content = processPlaceholders(content, arguments.context);
-                fileWrite(targetPath, content);
-                printCreated(relativePath);
+                // .gitkeep files are deliberately preserved as-is — they exist
+                // to keep otherwise-empty directories tracked once the user
+                // runs `git init && git add -A`. Copy them byte-for-byte
+                // (no placeholder processing — they are intentionally empty
+                // and have no template syntax). Earlier code skipped them
+                // entirely, which defeated their purpose: empty directories
+                // vanished on first commit, surprising users who followed the
+                // tutorial's chapter 1 file tree. See batch B fresh-VM
+                // sub-finding (2026-04-29).
+                if (entry.name == ".gitkeep") {
+                    fileCopy(sourcePath, targetPath);
+                    printCreated(relativePath);
+                    continue;
+                }
+                // Read template, process placeholders, write to target
+                var content = fileRead(sourcePath);
+                content = processPlaceholders(content, arguments.context);
+                fileWrite(targetPath, content);
+                printCreated(relativePath);
             }
```

- [ ] **Step 6: Re-run the spec to verify it passes**

```bash
bash tools/test-cli-local.sh
```

Expected: `NewCommandGitkeepSpec` and `NewCommandTemplateSpec` both pass; no other CLI spec regresses.

- [ ] **Step 7: Manually verify a fresh `wheels new` end-to-end**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-b/vendor/wheels \
  wheels new probe-batch-b --no-open-browser 2>&1 | tail -10
ls -la probe-batch-b/tests/specs/controllers/ probe-batch-b/tests/specs/functional/ probe-batch-b/tests/specs/models/
cd - && rm -rf "$TMP"
```

Expected: each subdirectory contains a `.gitkeep` file (size 0).

- [ ] **Step 8: Commit**

```bash
git add cli/lucli/Module.cfc \
        cli/lucli/tests/specs/commands/NewCommandTemplateSpec.cfc \
        cli/lucli/tests/specs/commands/NewCommandGitkeepSpec.cfc
git commit -m "$(cat <<'EOF'
fix(cli): copy .gitkeep files so empty test dirs survive git commit

copyTemplateDir() previously skipped any file named .gitkeep with a
comment that they "exist only to keep empty dirs in git" — but skipping
them meant the scaffolded app's tests/specs/{controllers,functional,
models}/ directories vanished on first git commit, contradicting the
tutorial's chapter 1 file tree.

Copy .gitkeep files byte-for-byte (no placeholder processing — they're
empty by design). Add a regression spec that scaffolds a temp project
and asserts the .gitkeep files land on disk.

Closes the new sub-finding from
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
(top of the "Shipped" section, surfaced during batch A's Task 0
reconnaissance).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `wheels migrate` — emit CRLF (`Chr(13) & Chr(10)`) instead of bare CR

**Bug.** `vendor/wheels/Migrator.cfc` and `vendor/wheels/migrator/Base.cfc::announce()` both build their output strings using `#Chr(13)#` (bare carriage return). On macOS and Linux terminals — and on the LuCLI `out()` pipe — bare CR moves the cursor to the start of the line *without* advancing it, so the next chunk overwrites. Result:

```
Migrating from 0 up to 20260428225339.-------- 20260428225339_create_posts_table -----------------Created table posts
```

The tutorial's chapter 2 expected output (`Migrating up <timestamp>` then `Migration complete.`) doesn't match anything that ever actually emits today. Bumping to `Chr(13) & Chr(10)` (CRLF) renders correctly on all three major terminals (macOS Terminal, iTerm2, GNOME Terminal, Windows Terminal/PowerShell). Pure `Chr(10)` (LF) would also work but CRLF is the safest cross-platform default and matches what `cfheader` and most CFML I/O do.

**Files:**
- Modify: `vendor/wheels/Migrator.cfc` (16 occurrences of `Chr(13)`)
- Modify: `vendor/wheels/migrator/Base.cfc:12` (the one line in `announce()`)
- Add: `vendor/wheels/tests/specs/migrator/MigratorOutputSpec.cfc` (new regression spec)

- [ ] **Step 1: Inventory the bare-CR sites**

```bash
grep -n 'Chr(13)' vendor/wheels/Migrator.cfc | wc -l
grep -n 'Chr(13)' vendor/wheels/migrator/Base.cfc
```

Expected: 16 lines in `Migrator.cfc`, 1 line in `Base.cfc`.

- [ ] **Step 2: Write a failing regression spec**

Create `vendor/wheels/tests/specs/migrator/MigratorOutputSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function run() {

        describe("Migrator output formatting", () => {

            it("announce() appends CRLF, not bare CR", () => {
                // Regression: Base.cfc::announce() used to append Chr(13) only,
                // which collapsed migrator output onto a single line in macOS
                // and Linux terminals. Tutorial chapter 2's "Run the migration"
                // step displayed mangled output as a result. See finding #3 in
                // docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
                request.$wheelsMigrationOutput = "";
                var base = new wheels.migrator.Base();
                base.announce("Created table posts");

                expect(request.$wheelsMigrationOutput).toInclude(Chr(13) & Chr(10));
                // Sanity: the message body should still be present.
                expect(request.$wheelsMigrationOutput).toInclude("Created table posts");
            });

        });

    }

}
```

- [ ] **Step 3: Run the spec and confirm it fails**

```bash
bash tools/test-local.sh migrator
```

Expected: `MigratorOutputSpec` fails on the `toInclude(Chr(13) & Chr(10))` assertion.

- [ ] **Step 4: Apply the fix in `Base.cfc`**

Replace the `announce()` body:

```diff
 public function announce(required string message) {
     param name="request.$wheelsMigrationOutput" default="";
-    request.$wheelsMigrationOutput = request.$wheelsMigrationOutput & arguments.message & Chr(13);
+    request.$wheelsMigrationOutput = request.$wheelsMigrationOutput & arguments.message & Chr(13) & Chr(10);
 }
```

- [ ] **Step 5: Apply the fix in `Migrator.cfc`**

Replace every `#Chr(13)#` with `#Chr(13) & Chr(10)#`. Use `replace_all` on the file. The 16 occurrences are at lines 43, 49, 62 (×2), 72 (×3), 82, 85, 95 (×2), 105 (×3), 141, 145, 150, 156 (×2), 166 (×3), 286, 292 (×2), 304 (×3) — verify with the inventory grep before and after.

The mechanical safe approach is `Edit` with `replace_all=true`, replacing the literal token `#Chr(13)#` with `#Chr(13) & Chr(10)#`. After the replacement, re-grep to confirm zero occurrences of the old pattern survive:

```bash
grep -n '#Chr(13)#' vendor/wheels/Migrator.cfc
```

Expected: no matches (all should now be `#Chr(13) & Chr(10)#`).

- [ ] **Step 6: Re-run the spec to verify it passes**

```bash
bash tools/test-local.sh migrator
```

Expected: `MigratorOutputSpec` passes; the existing migrator suite remains green.

- [ ] **Step 7: Run the full framework test suite to verify nothing else regresses**

```bash
bash tools/test-local.sh
```

Expected: same pass count as `develop`'s baseline (or one extra for the new spec).

- [ ] **Step 8: Manual verify against a real fresh app**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-b/vendor/wheels \
  wheels new migrate-output-probe --no-open-browser
cd migrate-output-probe
wheels generate model Post title:string body:text
wheels start --port=8766
sleep 4
wheels migrate latest
wheels stop
cd - && rm -rf "$TMP"
```

Expected: `wheels migrate latest` output renders across at least 3 visible lines (header, divider, per-table summary). No lines collapse onto each other.

- [ ] **Step 9: Commit**

```bash
git add vendor/wheels/Migrator.cfc \
        vendor/wheels/migrator/Base.cfc \
        vendor/wheels/tests/specs/migrator/MigratorOutputSpec.cfc
git commit -m "$(cat <<'EOF'
fix(migration): emit CRLF (not bare CR) so migrator output renders correctly

Migrator.cfc and migrator/Base.cfc::announce() built their output using
bare Chr(13). On macOS, Linux, and the LuCLI out() pipe, bare CR moves
the cursor to column 0 without advancing the line, so subsequent text
overwrites. The result on a fresh `wheels migrate latest` was:

    Migrating from 0 up to 20260428225339.-------- 20260428225339_create_posts_table -----------------Created table posts

— a single line where the tutorial promised three. Switch every CR to
CRLF (Chr(13) & Chr(10)). Add a regression spec that pins down the
announce() contract so future migrator hacks can't drop the LF again.

Closes finding #3 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `wheels test` — surface "spec failed to compile" instead of silent "0 passed"

**Bug.** When a CFML parse error sneaks into a spec file (e.g. unescaped `#` inside a CSS selector string, a Lucee 7 closing-tag glitch), TestBox skips the unloadable bundle silently. The test runner's HTTP response then contains `totalPass: 0, totalFail: 0, totalError: 0` and the CLI reports `0 passed`. The user has no idea why their spec count dropped to zero. The fresh-VM journal lost ~10 minutes to this exact symptom.

The fix is **CLI-side, not framework-side**: we don't try to teach TestBox how to surface compile errors (its API doesn't support it cleanly). We instead probe the disk for `*Spec.cfc` files in the requested directory and compare the count against TestBox's `bundleStats` count. When the disk count exceeds the loaded count, emit a distinct, unmissable warning.

**Files:**
- Modify: `cli/lucli/services/TestRunner.cfc` (add `countSpecsOnDisk` helper)
- Modify: `cli/lucli/Module.cfc::displayTestResults` (lines 3451-3507) — add a "loaded N of M spec files" check and a separate "failed to load" count
- Modify: `cli/lucli/tests/specs/services/TestRunnerSpec.cfc`

- [ ] **Step 1: Confirm the silent-swallow behavior reproduces**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-b/vendor/wheels \
  wheels new test-runner-probe --no-open-browser
cd test-runner-probe
mkdir -p tests/specs/models
cat > tests/specs/models/BrokenSpec.cfc <<'CFC'
component extends="wheels.WheelsTest" {
    function run() {
        // Deliberately broken: unescaped # in a string outside an
        // expression context blows Lucee's parser.
        var bad = "turbo-frame#new_comment button[type=submit]";
        describe("never runs", () => {
            it("never runs", () => {
                expect(true).toBeTrue();
            });
        });
    }
}
CFC
wheels start --port=8767
sleep 5
wheels test
wheels stop
cd - && rm -rf "$TMP"
```

Expected: today's output reads `0 passed (0.00s)` with no mention of the broken file. After Step 5's fix, output should include a "1 spec failed to load" line and the broken file's path.

- [ ] **Step 2: Add a disk-count helper to `TestRunner.cfc`**

In `cli/lucli/services/TestRunner.cfc`, add a public method below `resolveTestDirectory()`:

```cfm
/**
 * Count *Spec.cfc files on disk in the given test directory.
 *
 * Used by the CLI to detect TestBox silently swallowing unloadable
 * specs: when this count exceeds the TestBox bundle count, at least
 * one spec failed to compile.
 *
 * @testDirectory Dotted-path directory (e.g. "tests.specs" or
 *                "wheels.tests.specs.model")
 * @return Numeric count, or 0 if the directory doesn't exist.
 */
public numeric function countSpecsOnDisk(required string testDirectory) {
    // Resolve dotted path -> filesystem path.
    var fsPath = expandPath("/" & replace(arguments.testDirectory, ".", "/", "all"));
    if (!directoryExists(fsPath)) {
        return 0;
    }
    var specs = directoryList(fsPath, true, "name", "*Spec.cfc");
    return arrayLen(specs);
}

/**
 * List the on-disk spec file paths (relative to the test directory).
 *
 * Returned paths are dotted, matching TestBox's bundle-name convention,
 * so a caller can compute "spec-on-disk minus bundles-loaded" to find
 * which specific specs failed to compile.
 */
public array function listSpecsOnDisk(required string testDirectory) {
    var fsPath = expandPath("/" & replace(arguments.testDirectory, ".", "/", "all"));
    if (!directoryExists(fsPath)) {
        return [];
    }
    var specs = directoryList(fsPath, true, "path", "*Spec.cfc");
    var rv = [];
    for (var spec in specs) {
        // Convert filesystem path back to dotted bundle name.
        var rel = replace(spec, fsPath, "");
        rel = reReplace(rel, "^[\\/]+", "");
        rel = reReplace(rel, "\.cfc$", "");
        rel = replace(rel, "/", ".", "all");
        rel = replace(rel, "\", ".", "all");
        arrayAppend(rv, arguments.testDirectory & "." & rel);
    }
    return rv;
}
```

- [ ] **Step 3: Write a failing CLI spec**

Append to `cli/lucli/tests/specs/services/TestRunnerSpec.cfc`'s `describe("TestRunner Service", ...)` block:

```cfm
describe("countSpecsOnDisk()", () => {

    it("returns the count of *Spec.cfc files in the requested dotted directory", () => {
        // Arrange — drop two specs into a temp tests/specs/models dir.
        var specsDir = tempRoot & "/tests/specs/models";
        directoryCreate(specsDir, true, true);
        fileWrite(specsDir & "/AlphaSpec.cfc", "component {}");
        fileWrite(specsDir & "/BetaSpec.cfc",  "component {}");
        // A non-Spec file should not be counted.
        fileWrite(specsDir & "/Helper.cfc", "component {}");

        var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
        expect(runner.countSpecsOnDisk("tests.specs.models")).toBe(2);
    });

    it("returns 0 for a missing directory", () => {
        var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
        expect(runner.countSpecsOnDisk("tests.specs.does.not.exist")).toBe(0);
    });

});

describe("listSpecsOnDisk()", () => {

    it("returns dotted bundle names for every *Spec.cfc on disk", () => {
        var specsDir = tempRoot & "/tests/specs/listme";
        directoryCreate(specsDir, true, true);
        fileWrite(specsDir & "/OneSpec.cfc", "component {}");
        fileWrite(specsDir & "/TwoSpec.cfc", "component {}");

        var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
        var names = runner.listSpecsOnDisk("tests.specs.listme");
        expect(arrayLen(names)).toBe(2);
        expect(arrayContains(names, "tests.specs.listme.OneSpec")).toBeTrue();
        expect(arrayContains(names, "tests.specs.listme.TwoSpec")).toBeTrue();
    });

});
```

- [ ] **Step 4: Run the CLI spec — both `countSpecsOnDisk` and `listSpecsOnDisk` tests should now pass after Step 2's helper landed.**

```bash
bash tools/test-cli-local.sh
```

If the helper code in Step 2 has a typo or path-resolution bug, the new specs flag it before Step 5 inspects results.

- [ ] **Step 5: Wire the disk-count probe into `displayTestResults` in `Module.cfc`**

In `cli/lucli/Module.cfc::runTests` (around line 3422), pass the resolved test directory through to `displayTestResults` so it can call the new helper. Modify the signature first:

```diff
-		private void function displayTestResults(required any result, boolean verboseOutput = false) {
+		private void function displayTestResults(
+			required any result,
+			boolean verboseOutput = false,
+			string testDirectory = ""
+		) {
```

Then, just before the existing summary line at line 3478 (`var duration = ...`), add the disk-vs-loaded comparison:

```cfm
// Detect specs that failed to compile. TestBox silently skips bundles
// it can't load, so its "totalPass: 0, totalFail: 0, totalError: 0"
// reply is indistinguishable from "you have no specs" or "all specs
// passed an empty run." We probe the disk and warn if the loaded bundle
// count is lower than the on-disk *Spec.cfc count. See finding #2 in
// the 2026-04-29 fresh-VM triage.
var specsFailedToLoad = 0;
var unloadedSpecPaths = [];
if (len(arguments.testDirectory)) {
    try {
        var runner = new cli.lucli.services.TestRunner(projectRoot = projectRoot());
        var diskCount = runner.countSpecsOnDisk(arguments.testDirectory);
        var loadedCount = (structKeyExists(result, "bundleStats") && isArray(result.bundleStats))
            ? arrayLen(result.bundleStats)
            : 0;
        if (diskCount > loadedCount) {
            specsFailedToLoad = diskCount - loadedCount;
            // Compute which specific specs are missing from bundleStats.
            var diskSpecs = runner.listSpecsOnDisk(arguments.testDirectory);
            var loadedNames = {};
            if (loadedCount > 0) {
                for (var b in result.bundleStats) {
                    loadedNames[b.name ?: ""] = true;
                }
            }
            for (var p in diskSpecs) {
                if (!structKeyExists(loadedNames, p)) {
                    arrayAppend(unloadedSpecPaths, p);
                }
            }
        }
    } catch (any probeErr) {
        // Probe is best-effort — never let it crash the test report.
        verbose("Failed-to-load probe failed: #probeErr.message#");
    }
}

if (specsFailedToLoad > 0) {
    out("");
    out("WARN  #specsFailedToLoad# spec file(s) failed to compile and were silently skipped:", "yellow");
    for (var unloaded in unloadedSpecPaths) {
        out("        #unloaded#", "yellow");
    }
    out("        Visit /wheels/app/tests in a browser for the parse-error details.", "yellow");
    out("");
}
```

Update the summary line so that "failed to load" counts are visible alongside pass/fail:

```diff
 		if (totalFail == 0 && totalError == 0) {
-			out("#totalPass# passed#duration#", "green");
+			if (specsFailedToLoad > 0) {
+				out("#totalPass# passed, #specsFailedToLoad# failed to load#duration#", "yellow");
+			} else {
+				out("#totalPass# passed#duration#", "green");
+			}
 		} else {
-			out("#totalPass# passed, #totalFail# failed, #totalError# error(s)#duration#", "red");
+			var failedToLoadStr = specsFailedToLoad > 0 ? ", #specsFailedToLoad# failed to load" : "";
+			out("#totalPass# passed, #totalFail# failed, #totalError# error(s)#failedToLoadStr##duration#", "red");
```

Also adjust the call site in `runTests` (around line 3433) to pass the resolved directory:

```diff
-					displayTestResults(result, verboseOutput);
+					var resolvedDir = len(filter)
+						? filter
+						: (coreTests ? "wheels.tests.specs" : "tests.specs");
+					displayTestResults(result, verboseOutput, resolvedDir);
```

The non-zero exit code path is already gated on `totalFail + totalError`. We do **not** flip the exit code based on `specsFailedToLoad`: the warning is loud enough on stdout and several CI systems treat exit-code changes as breaking. (If a follow-up wants strict mode, expose a `--strict-loading` flag — out of scope here.)

- [ ] **Step 6: Run the CLI spec suite to verify nothing regresses**

```bash
bash tools/test-cli-local.sh
```

Expected: all CLI specs pass. The new `countSpecsOnDisk` and `listSpecsOnDisk` cases stay green.

- [ ] **Step 7: Re-run the manual repro from Step 1 to confirm the fix**

Expected output (after the fix):

```
Running app tests (sqlite)...

WARN  1 spec file(s) failed to compile and were silently skipped:
        tests.specs.models.BrokenSpec
        Visit /wheels/app/tests in a browser for the parse-error details.

0 passed, 1 failed to load (0.00s)
```

- [ ] **Step 8: Commit**

```bash
git add cli/lucli/services/TestRunner.cfc \
        cli/lucli/Module.cfc \
        cli/lucli/tests/specs/services/TestRunnerSpec.cfc
git commit -m "$(cat <<'EOF'
fix(cli): surface specs that fail to compile in wheels test output

TestBox silently skips bundles it cannot instantiate (e.g. CFML parse
errors), so its JSON response showed totalPass: 0 with no failures and
no errors — indistinguishable from "all clear" or "no specs found."
The fresh-VM tutorial run lost ~10 minutes when an unescaped `#`
inside a CSS selector crashed Lucee's parser silently.

Probe the disk for *Spec.cfc files in the requested test directory and
compare the count against TestBox's bundleStats. When the disk count
is higher, emit a distinct warning naming the unloaded specs and
report "X failed to load" alongside pass/fail counts.

The exit code is unchanged — strict-loading mode is intentionally out
of scope for this batch.

Closes finding #2 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `wheels reload` — append a one-line note about `onApplicationStart`

**Bug.** `wheels reload` re-fires the framework's reload path (`?reload=true`) but does **not** re-fire `onApplicationStart`. Users coming from Rails or Django assume reload re-runs init code; in Wheels, init code only runs on a *cold* start (`wheels stop && wheels start`). After batch A defined "cold reload" inline in chapter 6, the next surprise is going to be the same friction at the CLI level. The fix is purely cosmetic: append one line of output.

**Files:**
- Modify: `cli/lucli/Module.cfc::reload` (lines 408-435)
- Modify or extend: `cli/lucli/tests/specs/commands/` (look for a reload spec; create one if absent)

- [ ] **Step 1: Inventory the existing reload spec coverage**

```bash
grep -rn "function reload\|reload(\|wheels reload" cli/lucli/tests/specs/ | head -20
```

If no reload spec exists, create `cli/lucli/tests/specs/commands/ReloadCommandSpec.cfc`. If one does, append to it.

- [ ] **Step 2: Write a failing spec**

The reload command makes a real HTTP request, which is hard to unit-test without spinning up a server. Test the *output formatting* by stubbing `makeHttpRequest` via a tiny harness, OR — simpler — assert that the literal string we want appears somewhere in the module source:

```cfm
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {

        describe("wheels reload — output hints", () => {

            it("emits a note that onApplicationStart does NOT re-fire on a hot reload", () => {
                // Source-level check: avoids spinning up a real server in
                // unit tests. The Module.cfc::reload() function should emit
                // a hint pointing the user at `wheels stop && wheels start`
                // for cold init code edits. See finding #8 in the 2026-04-29
                // fresh-VM onboarding triage.
                var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
                expect(moduleSource).toInclude("onApplicationStart");
                expect(moduleSource).toInclude("wheels stop && wheels start");
            });

        });

    }

}
```

This is a deliberately shallow test — its job is to fail today (the source doesn't contain those strings inside the `reload()` function) and pass after Step 3. A heavier integration test for reload behavior is out of scope.

- [ ] **Step 3: Run the spec, confirm it fails**

```bash
bash tools/test-cli-local.sh
```

Expected: `ReloadCommandSpec` fails on either `toInclude("onApplicationStart")` or `toInclude("wheels stop && wheels start")` (or both).

- [ ] **Step 4: Apply the fix in `Module.cfc`**

Modify `reload()` (lines 423-433). After the success `out(...)` call, append the hint line:

```diff
 		try {
 			var reloadUrl = "http://localhost:#serverPort#/?reload=true&password=#password#";
 			var httpResult = makeHttpRequest(reloadUrl);
 			out("Application reloaded successfully.", "green");
+			// Surface the hot-vs-cold reload contract — Wheels does NOT
+			// re-fire onApplicationStart on `?reload=true`. Users editing
+			// app/events/onapplicationstart.cfm or config/services.cfm need
+			// a full restart. See finding #8 in the 2026-04-29 fresh-VM
+			// triage.
+			out("Note: onApplicationStart does NOT re-fire. For init-code edits, run `wheels stop && wheels start`.", "cyan");
 			verbose("URL: http://localhost:#serverPort#/?reload=true&password=***");
 		} catch (any e) {
 			out("Failed to reload: #e.message#", "red");
 			if (!len(password)) {
 				out("Hint: Set RELOAD_PASSWORD in .env or config/settings.cfm", "yellow");
 			}
 		}
```

- [ ] **Step 5: Re-run the spec to verify it passes**

```bash
bash tools/test-cli-local.sh
```

Expected: `ReloadCommandSpec` passes; no other CLI spec regresses.

- [ ] **Step 6: Manual smoke test against a running server**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/fresh-vm-batch-b/vendor/wheels \
  wheels new reload-probe --no-open-browser
cd reload-probe
wheels start --port=8768
sleep 4
wheels reload
wheels stop
cd - && rm -rf "$TMP"
```

Expected output:

```
Application reloaded successfully.
Note: onApplicationStart does NOT re-fire. For init-code edits, run `wheels stop && wheels start`.
```

- [ ] **Step 7: Commit**

```bash
git add cli/lucli/Module.cfc \
        cli/lucli/tests/specs/commands/ReloadCommandSpec.cfc
git commit -m "$(cat <<'EOF'
fix(cli): hint at cold reload from wheels reload output

`wheels reload` re-fires the framework reload path but does not re-run
onApplicationStart — surprising users coming from Rails/Django where
restart is the default. Append a one-line note pointing readers at
`wheels stop && wheels start` whenever they need init code to re-execute.

Pairs with the chapter 6 doc fix in batch A: now the contract is
visible at both surfaces a fresh-VM user encounters.

Closes finding #8 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Whole-batch verification

- [ ] **Step 1: Run the full CLI spec suite**

```bash
bash tools/test-cli-local.sh
```

Expected: every spec pass; no regressions across `Test`, `New`, `Migrate`, `Reload`, `Destroy`, `Generate`, etc.

- [ ] **Step 2: Run the full framework spec suite**

```bash
bash tools/test-local.sh
```

Expected: same pass count as `develop`'s baseline plus the new `MigratorOutputSpec`.

- [ ] **Step 3: Run the onboarding harness**

```bash
bash tools/test-onboarding.sh
```

Expected: all phases that exercise `wheels new`, `wheels migrate`, `wheels reload`, and `wheels test` complete cleanly. The harness's phase 4 (migration cliff) should now produce visibly multi-line output.

- [ ] **Step 4: No commit — verification only**

---

## Task 6: Update the triage doc + open the PR

**Files:**
- Modify: `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`

- [ ] **Step 1: Mark findings #2, #3, #8 as shipped, with the commit SHAs**

```diff
-### [ ] 2. `wheels test` reports "0 passed" when a spec fails to compile
+### [x] 2. `wheels test` reports "0 passed" when a spec fails to compile — **shipped in batch B** (commit `<sha-test>`)
```

```diff
-### [ ] 3. `wheels migrate` output mis-formatted (no newlines between sections)
+### [x] 3. `wheels migrate` output mis-formatted — **shipped in batch B** (commit `<sha-migrate>`)
```

```diff
-### [ ] 8. `wheels reload` doesn't re-fire `onApplicationStart` (related to #6)
+### [x] 8. `wheels reload` doesn't re-fire `onApplicationStart` — **shipped in batch B** (commit `<sha-reload>`)
```

- [ ] **Step 2: Add the new sub-finding (`.gitkeep` not copied) to the Shipped table**

The triage's "Shipped" section currently lists batches A and D. Add a batch B subsection:

```markdown
### Batch B — CLI output polish (2026-04-29)

Per [batch B plan](./2026-04-29-fresh-vm-batch-b-cli-polish.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| sub | `.gitkeep` files copied so empty test dirs survive git | `<sha-gitkeep>` | wheels |
| 3 | `wheels migrate` emits CRLF | `<sha-migrate>` | wheels |
| 2 | `wheels test` surfaces silent compile errors | `<sha-test>` | wheels |
| 8 | `wheels reload` notes that `onApplicationStart` does not re-fire | `<sha-reload>` | wheels |
```

- [ ] **Step 3: Update the cross-reference for April 19 #15**

Finding #2 in this triage subsumed [April 19 #15](./2026-04-19-framework-gaps-from-guides-phase-1.md). Update that file too:

```bash
grep -n "test runner output format\|runner output format" docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md
```

Mark April 19 #15 closed by batch B.

- [ ] **Step 4: Commit the doc updates**

```bash
git add docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md \
        docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md
git commit -m "$(cat <<'EOF'
docs(docs): mark batch B items shipped + close April 19 #15

Records the four CLI fixes landed in batch B (gitkeep, migrate output,
test runner compile-error surfacing, reload hint) and crosses out
April 19's #15 ("test runner output format needs verification") which
was subsumed by finding #2 in the 2026-04-29 triage.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Push the branch and open the PR**

```bash
git push -u origin HEAD
gh pr create --base develop --title "fix(cli): batch B — fresh-VM onboarding CLI output polish" --body "$(cat <<'EOF'
## Summary
- Copy `.gitkeep` files into the scaffolded app so `tests/specs/{controllers,functional,models}/` survive a `git commit` (closes the new sub-finding from batch A's reconnaissance).
- Make `wheels migrate` emit CRLF (`Chr(13) & Chr(10)`) instead of bare CR so output renders across multiple lines on macOS, Linux, and the LuCLI `out()` pipe (closes finding #3).
- Surface specs that fail to compile in `wheels test` output with a distinct "X failed to load" line and the unloaded spec paths, so silent TestBox swallowing is loud and obvious (closes finding #2, subsumes April 19 #15).
- Append a one-line note to `wheels reload` output explaining that `onApplicationStart` does not re-fire (closes finding #8, pairs with batch A's chapter 6 doc fix).

Closes findings #2, #3, #8, and the new sub-finding from `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`. (Finding #7 already shipped via #2360.)

## Test plan
- [ ] `bash tools/test-cli-local.sh` passes including the four new/extended specs (`NewCommandGitkeepSpec`, `TestRunnerSpec` count helpers, `ReloadCommandSpec`, `NewCommandTemplateSpec` extension)
- [ ] `bash tools/test-local.sh migrator` passes with the new `MigratorOutputSpec`
- [ ] `bash tools/test-local.sh` full framework suite stable
- [ ] `bash tools/test-onboarding.sh` completes — phase 4 (migrate) renders multi-line output, phase 2 (`wheels new`) confirms `.gitkeep` files land
- [ ] Manual: `wheels reload` against a running server prints the hot-reload note
- [ ] Manual: scaffold a fresh app, drop a deliberately-broken `*Spec.cfc`, run `wheels test`, confirm the "failed to load" warning fires

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 6: Report the PR URL and the commit SHAs to backfill the triage table**

After the PR squash-merges, edit the triage's batch-B table to fill in real SHAs.

---

## Out of scope for this batch

- **#1 (three-version-surface mismatch).** Tracked as batch F. Build/release engineering, not CLI polish.
- **#4 (scaffold output drift from chapter 3).** Tracked as batch C — needs a template overhaul and cross-engine verification.
- **#9 (DI singleton bug).** Already covered by batch D — separate plan, separate PR.
- **#10/#11/#12 (browser-test infra and tutorial spec).** Tracked as batch E.
- **`wheels reload --cold` flag.** Could close finding #8 more aggressively but introduces new CLI surface area. The output-hint fix here is the minimal, low-risk path; a `--cold` flag (or a `wheels restart` alias) is a follow-up task if user feedback wants it.
- **`wheels test --strict-loading` flag.** A future enhancement that would change the exit code on silent-skip detection. Out of scope to keep CI behavior stable.

---

## Open questions

- **Should `Chr(13) & Chr(10)` be hoisted to a constant (`Chr(13) & Chr(10)` is verbose and duplicated 16 times)?** A `local.lf = Chr(13) & Chr(10);` at the top of each function would read better but inflates the diff. Defer until someone wants to clean up the migrator more broadly.
- **Should the failed-to-load warning include the parse-error message inline?** TestBox doesn't expose those errors via the JSON contract. Surfacing them would require either (a) running each spec through `getComponentMetadata()` first and catching, or (b) parsing Lucee's exception output. Both are significantly more work — defer.
- **Is the `out("Note: ...", "cyan")` color too subtle?** Cyan reads as informational across most terminals; yellow would be louder but reserved for warnings elsewhere. Match existing convention; revisit if user feedback says it's missed.
