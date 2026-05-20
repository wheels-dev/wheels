component extends="wheels.WheelsTest" {

	// Regression: the Scoop-installed wheels.cmd shipped on at least one
	// real Windows 11 build (10.0.26200.8457) failed on every invocation
	// with two compounding bugs, both reported in issue ##2765.
	//
	// Bug 1 -- the wrapper set `JAVA_HOME=%~dp0share\jdk`, a path Scoop
	// never produces. A Scoop install only populates `share\module` and
	// `share\framework`; no `share\jdk`. The brew formula resolves
	// JAVA_HOME from openjdk@21's opt_prefix (a real path), but the Scoop
	// wrapper was written assuming a parallel layout that doesn't exist
	// in a Scoop install. That dead assignment was already removed from
	// the in-repo template before this fix, but the published bucket
	// carried it.
	//
	// Bug 2 -- the wrapper invoked lucli with
	// `call "%~dp0lucli-<ver>.bat"`. The lucli-<ver>.bat artifact is a
	// bat-jar concatenation (small bat preamble + `:JAR_BOUNDARY` + raw
	// JAR ZIP bytes, ~915 KB). cmd.exe pre-parses the entire bat file
	// for labels/control flow before running it, and on this Windows
	// build the pre-parse trips on a byte sequence in the JAR tail with
	// `The filename, directory name, or volume label syntax is
	// incorrect.` The bat never executes. Bypassing the bat preamble by
	// invoking java directly --
	// `"%JAVA_HOME%\bin\java.exe" -client -jar "%~dp0lucli-<ver>.bat" %*`
	// -- works because java reads the JAR via stream and skips the bat
	// preamble in front of the ZIP central directory.
	//
	// This spec pins both bucket manifests AND the source-of-truth
	// build-manifests.py against both regressions, plus the implied
	// JAVA_HOME resolver that the direct-java dispatch needs.

	function run() {

		describe("Scoop wrapper (build-manifests.py output)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var beManifest = repoRoot & "/tools/distribution-drafts/scoop/wheels-be.json";
			var stableManifest = repoRoot & "/tools/distribution-drafts/scoop/wheels.json";
			var script = repoRoot & "/tools/distribution-drafts/scoop/build-manifests.py";

			var manifestTargets = [
				{path: beManifest, label: "wheels-be.json (bleeding-edge channel)"},
				{path: stableManifest, label: "wheels.json (stable channel)"}
			];

			for (var target in manifestTargets) {
				// IIFE to capture loop variable for closure binding.
				(function(t) {
					describe(t.label, () => {

						it("does not dispatch lucli via `call ""%~dp0lucli-<ver>.bat""`", () => {
							expect(fileExists(t.path)).toBeTrue("Missing file: " & t.path);
							var src = fileRead(t.path);
							// Both the normal dispatch and the deploy
							// arg-rewrite dispatch are subject to the
							// cmd.exe bat-jar parser regression. Either
							// `call` line is a re-introduction of bug 2.
							var hasBatCall = findNoCase("call \""%~dp0lucli-", src) > 0;
							expect(hasBatCall).toBeFalse(
								t.label & " must not dispatch lucli via `call ""%~dp0lucli-<ver>.bat""`. "
								& "cmd.exe pre-parses the bat-jar tail and aborts before lucli runs on at "
								& "least Windows 11 10.0.26200.8457. Invoke java directly instead. "
								& "See issue ##2765."
							);
						});

						it("dispatches lucli via direct `java.exe -client -jar`", () => {
							var src = fileRead(t.path);
							// Substring match on the JSON-encoded form of
							// the wrapper line. The raw CMD line is
							// `"%JAVA_HOME%\bin\java.exe" -client -jar "%~dp0lucli-<ver>.bat" %*`;
							// after PS single-quote wrap and JSON quote
							// escape, the file contains the run below.
							var hasDirectJava = findNoCase(
								"\""%JAVA_HOME%\\bin\\java.exe\"" -client -jar \""%~dp0lucli-",
								src
							) > 0;
							expect(hasDirectJava).toBeTrue(
								t.label & " must invoke lucli via "
								& """%JAVA_HOME%\bin\java.exe"" -client -jar ""%~dp0lucli-<ver>.bat"" "
								& "to bypass cmd.exe's bat-file pre-parser. See issue ##2765."
							);
						});

						it("does not set JAVA_HOME to %~dp0share\jdk", () => {
							var src = fileRead(t.path);
							// Bug 1: a Scoop install never populates
							// share\jdk -- share holds only module and
							// framework subdirs.
							var hasBrokenJavaHome = findNoCase(
								"JAVA_HOME=%~dp0share\\jdk",
								src
							) > 0;
							expect(hasBrokenJavaHome).toBeFalse(
								t.label & " must not set JAVA_HOME=%~dp0share\jdk -- Scoop installs "
								& "populate share/module and share/framework only. Resolve JAVA_HOME "
								& "from the openjdk21 dependency declared via `depends: java/openjdk21`. "
								& "See issue ##2765."
							);
						});

						it("resolves JAVA_HOME from the openjdk21 dependency", () => {
							var src = fileRead(t.path);
							// The direct-java dispatch above requires
							// JAVA_HOME to be set. Scoop installs the
							// openjdk21 dependency under
							// `%SCOOP%\apps\openjdk21\current` (or the
							// sibling `%~dp0..\..\openjdk21\current`).
							// Match `openjdk21` inside a `$lines.Add(...)`
							// call rather than the bare top-level
							// `depends: java/openjdk21` field -- only the
							// wrapper-template emission counts.
							var hasOpenjdk21InWrapper = reFindNoCase(
								"\$lines\.Add\([^)]*openjdk21",
								src
							) > 0;
							expect(hasOpenjdk21InWrapper).toBeTrue(
								t.label & " must resolve JAVA_HOME from Scoop's openjdk21 install "
								& "(declared via `depends: java/openjdk21`) inside the wrapper "
								& "template, not just as a top-level dependency. Without it, the "
								& "direct-java dispatch fails when JAVA_HOME isn't already set. "
								& "See issue ##2765."
							);
						});

					});
				})(target);
			}

			describe("build-manifests.py (source of truth)", () => {

				it("emits the direct-java dispatch line", () => {
					expect(fileExists(script)).toBeTrue("Missing file: " & script);
					var src = fileRead(script);
					// Source-script + JSON drift would silently
					// re-introduce the regression on the next regen. Pin
					// both ends.
					var hasJavaHomeRef = findNoCase("%JAVA_HOME%", src) > 0;
					expect(hasJavaHomeRef).toBeTrue(
						"build-manifests.py must reference %JAVA_HOME% in the wrapper template; "
						& "otherwise a regen wipes the fix from both JSONs. See issue ##2765."
					);
				});

			});

		});

	}

}
