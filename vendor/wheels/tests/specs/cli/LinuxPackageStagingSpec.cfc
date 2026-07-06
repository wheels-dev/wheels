component extends="wheels.WheelsTest" {

	// Regression: the v4.0.0 .deb / .rpm Linux packages diverged from the
	// brew formula in three ways that broke `wheels start` on Rocky Linux
	// during the paiindustries/titan production cutover on 2026-05-13:
	//
	//   1. build-linux-packages.sh unzipped wheels-cli-VER.zip (the legacy
	//      CommandBox-shaped artifact, ~558 KB) into build/module/ instead
	//      of consuming wheels-module-VER.tar.gz (the lucli-native module,
	//      ~24 MB, with Module.cfc at top).
	//   2. The build script wrote .version / .channel into build/ but the
	//      nfpm yamls never declared them under `contents:`, so they were
	//      dropped on the floor — `wheels --version` returned "unknown".
	//   3. The generated /usr/bin/wheels wrapper ended with
	//      `exec /opt/wheels/lucli "$@"`. lucli with bare argv[0]=lucli has
	//      no module context, so `wheels start` became `lucli start` and
	//      hit `Unknown command: 'start'`.
	//
	// Plus the rpm omitted `tar` as a runtime dependency. Rocky Linux 10
	// minimal cloud images do not ship `tar`, and the post-install (or any
	// downstream role unpacking the module) fails silently without it.
	//
	// This spec pins the packaging files against all four sub-bugs.
	// Issue ##2700.

	function run() {

		describe("Linux package staging (build-linux-packages.sh + nfpm yamls)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var buildScript = repoRoot & "/tools/distribution-drafts/linux-packages/build-linux-packages.sh";
			var nfpmStable = repoRoot & "/tools/distribution-drafts/linux-packages/nfpm-wheels.yaml";
			var nfpmBe = repoRoot & "/tools/distribution-drafts/linux-packages/nfpm-wheels-be.yaml";

			describe("build-linux-packages.sh", () => {

				it("consumes the lucli-native wheels-module tarball, not the legacy wheels-cli zip", () => {
					expect(fileExists(buildScript)).toBeTrue("Missing file: " & buildScript);
					var src = fileRead(buildScript);

					// Must reference wheels-module-${WHEELS_VERSION}.tar.gz —
					// the lucli-native artifact built from cli/lucli/ at
					// release.yml line 270.
					var hasModule = reFindNoCase(
						"wheels-module-\$\{WHEELS_VERSION\}\.tar\.gz",
						src
					) > 0;
					expect(hasModule).toBeTrue(
						"build-linux-packages.sh must consume wheels-module-${WHEELS_VERSION}.tar.gz "
						& "(the lucli-native module with Module.cfc at top) instead of the legacy "
						& "CommandBox-shaped wheels-cli zip. See issue ##2700."
					);

					// Must NOT unzip wheels-cli into build/module/ — that's
					// the legacy CommandBox artifact that ships `box`-shaped
					// contents and makes `wheels start` fail with
					// `Unknown command: 'start'`.
					var hasLegacyUnzip = reFindNoCase(
						"unzip[^\n]+wheels-cli-\$\{WHEELS_VERSION\}\.zip[^\n]+build/module",
						src
					) > 0;
					expect(hasLegacyUnzip).toBeFalse(
						"build-linux-packages.sh must not stage wheels-cli-${WHEELS_VERSION}.zip into "
						& "build/module/ — that ships the legacy CommandBox-style module instead of "
						& "the lucli-native one. See issue ##2700."
					);
				});

				it("emits a wrapper that routes lucli through the wheels module", () => {
					var src = fileRead(buildScript);

					// The wrapper must route lucli through the wheels module in one
					// of these forms:
					//   (a) rename the native binary so argv[0] is `wheels` and exec
					//       it directly (the old brew approach — lucli routes by
					//       basename(argv[0])), OR
					//   (b) call lucli via `modules run wheels "$@"` explicitly, OR
					//   (c) launch the portable jar with the binary-name flag:
					//       `exec java -Dlucli.binary.name=wheels -jar /opt/wheels/lucli.jar "$@"`
					//       (the arch-independent form — the flag replaces the
					//       basename(argv[0]) trick; same mechanism Scoop uses).
					// The bare `exec /opt/wheels/lucli "$@"` form is incorrect and
					// produces `Unknown command: 'start'`.
					var execsBareLucli = reFindNoCase(
						"exec[[:space:]]+/opt/wheels/lucli[[:space:]]+""?\$@""?",
						src
					) > 0;
					expect(execsBareLucli).toBeFalse(
						"The generated /usr/bin/wheels wrapper must not exec /opt/wheels/lucli "
						& "directly with bare ""$@"" — lucli needs a module context to resolve "
						& "`wheels start`. Either rename the binary to /opt/wheels/wheels and exec "
						& "that, or use `exec /opt/wheels/lucli modules run wheels ""$@""`. "
						& "See issue ##2700."
					);

					var routesByArgv0 = reFindNoCase(
						"exec[[:space:]]+""?/opt/wheels/wheels""?[[:space:]]+""?\$@""?",
						src
					) > 0;
					var routesByModulesRun = reFindNoCase(
						"exec[[:space:]]+/opt/wheels/lucli[[:space:]]+modules[[:space:]]+run[[:space:]]+wheels",
						src
					) > 0;
					// Arch-independent jar launcher: `-Dlucli.binary.name=wheels`
					// routes to the wheels module and `-jar .../lucli.jar` runs the
					// portable launcher (installs/runs on amd64 AND arm64).
					var routesByJar = reFindNoCase(
						"-Dlucli\.binary\.name=wheels[^\n]*-jar[^\n]*lucli\.jar",
						src
					) > 0;
					expect(routesByArgv0 || routesByModulesRun || routesByJar).toBeTrue(
						"The wrapper must route lucli through the wheels module — via "
						& "argv[0] rename (`exec /opt/wheels/wheels ""$@""`), explicit module "
						& "dispatch (`exec /opt/wheels/lucli modules run wheels ""$@""`), or the "
						& "portable jar launcher (`java -Dlucli.binary.name=wheels -jar "
						& "/opt/wheels/lucli.jar ""$@""`). See issue ##2700."
					);
				});

			});

			var nfpmTargets = [
				{path: nfpmStable, label: "nfpm-wheels.yaml (stable channel)"},
				{path: nfpmBe, label: "nfpm-wheels-be.yaml (bleeding-edge channel)"}
			];

			for (var target in nfpmTargets) {
				// Capture loop variable for closure binding.
				(function(t) {
					describe(t.label, () => {

						it("ships /opt/wheels/.version so `wheels --version` reports the installed version", () => {
							expect(fileExists(t.path)).toBeTrue("Missing file: " & t.path);
							var src = fileRead(t.path);
							var hasVersionFile = reFindNoCase(
								"dst:[[:space:]]+/opt/wheels/\.version",
								src
							) > 0;
							expect(hasVersionFile).toBeTrue(
								t.label & " must declare /opt/wheels/.version under `contents:` so the "
								& "/usr/bin/wheels wrapper can read it. Without it, `wheels --version` "
								& "returns ""unknown (stable)"". See issue ##2700."
							);
						});

						it("ships /opt/wheels/.channel so `wheels --version` reports the installed channel", () => {
							var src = fileRead(t.path);
							var hasChannelFile = reFindNoCase(
								"dst:[[:space:]]+/opt/wheels/\.channel",
								src
							) > 0;
							expect(hasChannelFile).toBeTrue(
								t.label & " must declare /opt/wheels/.channel under `contents:` so the "
								& "/usr/bin/wheels wrapper can read it. Without it, the channel falls "
								& "back to a hardcoded default. See issue ##2700."
							);
						});

						it("declares tar as an rpm runtime dependency", () => {
							var src = fileRead(t.path);
							// Match `tar` as a list item under overrides.rpm.depends. It can
							// either be a bare entry or part of an alternative — we just need
							// to see `- tar` (possibly with whitespace) somewhere under the
							// rpm depends block. The simplest robust check: presence of
							// `- tar` as a list item in the file.
							var hasTarDep = reFindNoCase(
								"-[[:space:]]+tar([[:space:]]|$)",
								src
							) > 0;
							expect(hasTarDep).toBeTrue(
								t.label & " must declare `tar` as an rpm runtime dependency. Rocky "
								& "Linux 10 minimal cloud images do not ship tar, and any role that "
								& "unpacks /opt/wheels/module/ (or other tarball-shaped payloads) "
								& "fails silently without it. See issue ##2700."
							);
						});

						it("stages framework src from ./build/framework/wheels/ so contents flatten under vendor/wheels/", () => {
							var src = fileRead(t.path);
							// wheels-core-VER.zip has a top-level `wheels/` directory inside it
							// (the smoke test asserts this at tools/ci/smoke-test-module.sh:112).
							// nfpm `type: tree` copies the *contents* of src into dst, so if src
							// points at ./build/framework/ (one level above the inner wheels/),
							// the entire wheels/ subdirectory itself lands at dst — producing
							// /opt/wheels/module/vendor/wheels/wheels/Injector.cfc instead of
							// /opt/wheels/module/vendor/wheels/Injector.cfc. The framework then
							// never loads at runtime ("could not find component or class with
							// name [wheels.Injector]" — see issue ##2773).
							//
							// The brew formula handles this by explicitly re-introducing the
							// wheels/ wrapper at stage time — see homebrew-wheels Formula/wheels.rb:62
							// — (share/"wheels/framework/wheels").install Dir["*"]. The .deb/.rpm
							// equivalent is to point src at the inner wheels/ directory directly.
							//
							// `[[:space:]]+` matches across the YAML line break between the src
							// value and `dst:` — POSIX `[[:space:]]` resolves to Java's `\s` in
							// both Lucee and Adobe CF, which includes `\n`.
							var hasFixedPair = reFindNoCase(
								"src:[[:space:]]+\./build/framework/wheels/[[:space:]]+dst:[[:space:]]+/opt/wheels/module/vendor/wheels/",
								src
							) > 0;
							expect(hasFixedPair).toBeTrue(
								t.label & " must declare `src: ./build/framework/wheels/` (with the "
								& "trailing /wheels/) for the framework contents entry. Without the "
								& "inner /wheels/ segment, nfpm's `type: tree` double-nests the "
								& "framework at /opt/wheels/module/vendor/wheels/wheels/, and Lucee "
								& "fails to resolve `wheels.Injector` at app startup. See issue ##2773."
							);

							// Negative guard: the buggy bare-framework form must not coexist
							// with the fixed form. A future copy-paste could leave both entries
							// in the file, and nfpm would happily stage both — the bare one
							// reintroduces the double-nesting. Pairs with the toBeTrue above
							// per the dual-assertion pattern already used by the wrapper-routing
							// checks at lines 60-68 / 81-106.
							var hasBuggyPair = reFindNoCase(
								"src:[[:space:]]+\./build/framework/[[:space:]]+dst:[[:space:]]+/opt/wheels/module/vendor/wheels/",
								src
							) > 0;
							expect(hasBuggyPair).toBeFalse(
								t.label & " must NOT declare `src: ./build/framework/` (without "
								& "the trailing /wheels/) for any contents entry targeting "
								& "/opt/wheels/module/vendor/wheels/. If both the bare and the "
								& "/wheels/-suffixed entries coexist, nfpm stages the inner "
								& "wheels/ wrapper as a subdirectory and the framework "
								& "double-nests. See issue ##2773."
							);
						});

					});
				})(target);
			}

		});

	}

}
