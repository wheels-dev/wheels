component extends="wheels.WheelsTest" {

	// Unit tests for vendor/wheels/BuildInfo.cfc. Construction with overrides
	// avoids touching the placeholder strings literally — production builds
	// rely on the release pipeline's sed substitution.

	function run() {

		describe("BuildInfo", () => {

			describe("version()", () => {

				it("returns the substituted version string verbatim", () => {
					var bi = new wheels.BuildInfo({version: "4.0.0-SNAPSHOT+1628"});
					expect(bi.version()).toBe("4.0.0-SNAPSHOT+1628");
				});

				it("returns 0.0.0-dev when the version placeholder is unsubstituted", () => {
					// Constructed with no overrides: every field stays as @build.*@.
					var bi = new wheels.BuildInfo();
					expect(bi.version()).toBe("0.0.0-dev");
				});

				it("returns 0.0.0-dev when version is explicitly the unsubstituted placeholder", () => {
					var bi = new wheels.BuildInfo({version: "@build.version@"});
					expect(bi.version()).toBe("0.0.0-dev");
				});

				it("falls back to the sibling wheels.json version when unstamped (dev mode)", () => {
					// Webroot-relative temp dir: RustCFML's Linux build cannot write to
					// getTempDirectory() (permission-denied), while the webroot is always
					// writable in CI. Deleted in the finally block below.
					var dir = expandPath("/") & "wheels-buildinfo-" & createUUID();
					// Adobe CF's directoryCreate validates to a single parameter —
					// the dir is webroot-relative and single-level, so no createPath.
					directoryCreate(dir);
					var manifestPath = dir & "/wheels.json";
					fileWrite(manifestPath, '{"version": "4.1.2"}');
					try {
						var bi = new wheels.BuildInfo();
						expect(bi.version(manifestPath = manifestPath)).toBe("4.1.2");
					} finally {
						directoryDelete(dir, true);
					}
				});

				it("falls back to the sibling box.json when wheels.json is absent", () => {
					// Webroot-relative temp dir: RustCFML's Linux build cannot write to
					// getTempDirectory() (permission-denied), while the webroot is always
					// writable in CI. Deleted in the finally block below.
					var dir = expandPath("/") & "wheels-buildinfo-" & createUUID();
					// Adobe CF's directoryCreate validates to a single parameter —
					// the dir is webroot-relative and single-level, so no createPath.
					directoryCreate(dir);
					var manifestPath = dir & "/box.json";
					fileWrite(manifestPath, '{"version": "3.5.0"}');
					try {
						var bi = new wheels.BuildInfo();
						expect(bi.version(manifestPath = manifestPath)).toBe("3.5.0");
					} finally {
						directoryDelete(dir, true);
					}
				});

				it("returns 0.0.0-dev when no manifest exists", () => {
					// Webroot-relative temp dir: RustCFML's Linux build cannot write to
					// getTempDirectory() (permission-denied), while the webroot is always
					// writable in CI. Deleted in the finally block below.
					var dir = expandPath("/") & "wheels-buildinfo-" & createUUID();
					// Adobe CF's directoryCreate validates to a single parameter —
					// the dir is webroot-relative and single-level, so no createPath.
					directoryCreate(dir);
					try {
						var bi = new wheels.BuildInfo();
						expect(bi.version(manifestPath = dir & "/wheels.json")).toBe("0.0.0-dev");
					} finally {
						directoryDelete(dir, true);
					}
				});

				it("returns 0.0.0-dev when the manifest version is still a placeholder", () => {
					// Webroot-relative temp dir: RustCFML's Linux build cannot write to
					// getTempDirectory() (permission-denied), while the webroot is always
					// writable in CI. Deleted in the finally block below.
					var dir = expandPath("/") & "wheels-buildinfo-" & createUUID();
					// Adobe CF's directoryCreate validates to a single parameter —
					// the dir is webroot-relative and single-level, so no createPath.
					directoryCreate(dir);
					var manifestPath = dir & "/wheels.json";
					fileWrite(manifestPath, '{"version": "@build.version@"}');
					try {
						var bi = new wheels.BuildInfo();
						expect(bi.version(manifestPath = manifestPath)).toBe("0.0.0-dev");
					} finally {
						directoryDelete(dir, true);
					}
				});

				it("stamped BuildInfo version wins over the manifest", () => {
					// Webroot-relative temp dir: RustCFML's Linux build cannot write to
					// getTempDirectory() (permission-denied), while the webroot is always
					// writable in CI. Deleted in the finally block below.
					var dir = expandPath("/") & "wheels-buildinfo-" & createUUID();
					// Adobe CF's directoryCreate validates to a single parameter —
					// the dir is webroot-relative and single-level, so no createPath.
					directoryCreate(dir);
					var manifestPath = dir & "/wheels.json";
					fileWrite(manifestPath, '{"version": "9.9.9"}');
					try {
						var bi = new wheels.BuildInfo({version: "4.0.0"});
						expect(bi.version(manifestPath = manifestPath)).toBe("4.0.0");
					} finally {
						directoryDelete(dir, true);
					}
				});

			});

			describe("isDev() / isSnapshot()", () => {

				it("isDev() is true when version is the unsubstituted placeholder", () => {
					expect(new wheels.BuildInfo().isDev()).toBeTrue();
				});

				it("isDev() is false for any concrete version", () => {
					expect(new wheels.BuildInfo({version: "4.0.0"}).isDev()).toBeFalse();
					expect(new wheels.BuildInfo({version: "4.0.0-SNAPSHOT+1628"}).isDev()).toBeFalse();
				});

				it("source contains the @build.version@ sentinel exactly once (regression guard)", () => {
					// The release pipeline (tools/build/scripts/prepare-core.sh) does a
					// GLOBAL `sed s/@build.version@/<version>/g` over BuildInfo.cfc at
					// artifact-construction time. If the sentinel appears anywhere
					// other than the `version:` field of init()'s `variables.info`
					// struct — say, inside isDev()'s equality comparison — that
					// occurrence is rewritten too, silently turning every released
					// build into a self-reported "0.0.0-dev" build. This test reads
					// the source and asserts the structural invariant: exactly one
					// literal occurrence, no more.
					//
					// If this fails, you almost certainly added a comparison like
					//     return variables.info.version == "@build.version@";
					// somewhere. Use the prefix/suffix structural check that
					// $blankIfPlaceholder() uses instead.
					var src = fileRead(expandPath("/wheels/BuildInfo.cfc"));
					var token = "@" & "build.version" & "@"; // split so this file isn't itself a sentinel
					var occurrences = (len(src) - len(replace(src, token, "", "all"))) / len(token);
					expect(occurrences).toBe(
						1,
						"BuildInfo.cfc must contain exactly one '" & token & "' literal (found " & occurrences & "). A second occurrence is rewritten by prepare-core.sh's global sed and breaks dev detection on every released build."
					);
				});

				it("isSnapshot() is true for SNAPSHOT versions", () => {
					expect(new wheels.BuildInfo({version: "4.0.0-SNAPSHOT+1628"}).isSnapshot()).toBeTrue();
				});

				it("isSnapshot() is false for release versions and dev builds", () => {
					expect(new wheels.BuildInfo({version: "4.0.0"}).isSnapshot()).toBeFalse();
					expect(new wheels.BuildInfo().isSnapshot()).toBeFalse();
				});

			});

			describe("metadata getters", () => {

				it("returns substituted values verbatim", () => {
					var bi = new wheels.BuildInfo({
						version: "4.0.0-SNAPSHOT+1628",
						buildNumber: "1628",
						branch: "develop",
						commitSha: "81e9f7958d3abc",
						commitShortSha: "81e9f79",
						commitSubject: "fix(cli): override version() and showHelp()",
						builtAt: "2026-04-28T19:11:00Z",
						runId: "25072250128",
						runUrl: "https://github.com/wheels-dev/wheels/actions/runs/25072250128",
						repository: "wheels-dev/wheels"
					});
					expect(bi.buildNumber()).toBe("1628");
					expect(bi.branch()).toBe("develop");
					expect(bi.commitSha()).toBe("81e9f7958d3abc");
					expect(bi.commitShortSha()).toBe("81e9f79");
					expect(bi.commitSubject()).toBe("fix(cli): override version() and showHelp()");
					expect(bi.builtAt()).toBe("2026-04-28T19:11:00Z");
					expect(bi.runId()).toBe("25072250128");
					expect(bi.runUrl()).toBe("https://github.com/wheels-dev/wheels/actions/runs/25072250128");
					expect(bi.repository()).toBe("wheels-dev/wheels");
				});

				it("blanks out unresolved placeholders to empty strings", () => {
					var bi = new wheels.BuildInfo();
					expect(bi.buildNumber()).toBe("");
					expect(bi.branch()).toBe("");
					expect(bi.commitSha()).toBe("");
					expect(bi.commitShortSha()).toBe("");
					expect(bi.commitSubject()).toBe("");
					expect(bi.builtAt()).toBe("");
					expect(bi.runId()).toBe("");
					expect(bi.runUrl()).toBe("");
					expect(bi.repository()).toBe("");
				});

			});

			describe("asStruct()", () => {

				it("returns all fields with the dev sentinel applied to version", () => {
					var s = new wheels.BuildInfo().asStruct();
					expect(s.version).toBe("0.0.0-dev");
					expect(s.buildNumber).toBe("");
					expect(s.branch).toBe("");
				});

				it("returns substituted values verbatim", () => {
					var s = new wheels.BuildInfo({
						version: "4.0.0",
						buildNumber: "1628",
						branch: "master"
					}).asStruct();
					expect(s.version).toBe("4.0.0");
					expect(s.buildNumber).toBe("1628");
					expect(s.branch).toBe("master");
				});

			});

		});

	}

}
