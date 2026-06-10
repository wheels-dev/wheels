component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.rc = new cli.lucli.services.ReleaseChannel();
	}

	function run() {

		describe("ReleaseChannel Service", () => {

			describe("classify()", () => {

				it("classifies SemVer-clean versions as stable", () => {
					expect(rc.classify("4.0.0")).toBe("stable");
					expect(rc.classify("4.1.0")).toBe("stable");
					expect(rc.classify("10.20.30")).toBe("stable");
				});

				it("classifies post-fix snapshot versions as bleeding-edge", () => {
					// New format introduced when the SemVer separator was fixed
					// from `+` (build metadata) to `.` (pre-release identifier).
					expect(rc.classify("4.0.1-snapshot.1700")).toBe("bleeding-edge");
					expect(rc.classify("5.0.0-snapshot.1")).toBe("bleeding-edge");
				});

				it("classifies legacy SNAPSHOT+N versions as bleeding-edge", () => {
					// Pre-fix format: SemVer §10 says build metadata is ignored
					// in precedence, so this format sorted incorrectly across
					// adjacent runs. Brew bottles built before the fix still
					// carry these strings — must classify them correctly.
					expect(rc.classify("4.0.0-SNAPSHOT+1656")).toBe("bleeding-edge");
					expect(rc.classify("3.5.0-SNAPSHOT+42")).toBe("bleeding-edge");
				});

				it("classifies release candidates", () => {
					expect(rc.classify("4.1.0-rc.1")).toBe("release-candidate");
					expect(rc.classify("5.0.0-rc.10")).toBe("release-candidate");
				});

				it("classifies dev-checkout sentinels as development", () => {
					// Assemble the token at runtime so the build's @build.version@
					// replacer can't clobber this literal (it would become a real
					// version and classify as stable). Mirrors the production fix. CLI audit H10.
					expect(rc.classify("@" & "build.version" & "@")).toBe("development");
					expect(rc.classify("Version not specified")).toBe("development");
					expect(rc.classify("0.0.0-dev")).toBe("development");
					expect(rc.classify("")).toBe("development");
				});

				it("trims whitespace before classifying", () => {
					expect(rc.classify("  4.0.0  ")).toBe("stable");
					expect(rc.classify("\t4.0.1-snapshot.1\n")).toBe("bleeding-edge");
				});

				it("returns empty for unrecognized formats", () => {
					// Custom-build version strings degrade gracefully to no
					// channel tag rather than crashing or guessing.
					expect(rc.classify("custom-build")).toBe("");
					expect(rc.classify("4.0")).toBe("");
					expect(rc.classify("v4.0.0")).toBe("");
				});

			});

			describe("releaseRepo()", () => {

				it("maps stable to the main repo", () => {
					expect(rc.releaseRepo("stable")).toBe("wheels-dev/wheels");
				});

				it("maps bleeding-edge to the snapshots repo", () => {
					expect(rc.releaseRepo("bleeding-edge")).toBe("wheels-dev/wheels-snapshots");
				});

				it("returns empty for channels that should not auto-check", () => {
					// RC users opted in explicitly; dev checkouts have no meaningful target.
					expect(rc.releaseRepo("release-candidate")).toBe("");
					expect(rc.releaseRepo("development")).toBe("");
					expect(rc.releaseRepo("")).toBe("");
				});

			});

			describe("upgradeCommand()", () => {

				it("uses package name 'wheels' for stable", () => {
					var cmd = rc.upgradeCommand("stable");
					expect(cmd).toInclude("wheels");
					expect(cmd).notToInclude("wheels-be");
				});

				it("uses package name 'wheels-be' for bleeding-edge", () => {
					var cmd = rc.upgradeCommand("bleeding-edge");
					expect(cmd).toInclude("wheels-be");
				});

				it("returns a command containing 'upgrade' or 'update'", () => {
					// Cross-platform check: brew uses "upgrade", scoop uses "update".
					// The helper should produce one of those verbs regardless of OS.
					var stable = rc.upgradeCommand("stable");
					var be = rc.upgradeCommand("bleeding-edge");
					expect(reFindNoCase("upgrade|update", stable) > 0).toBeTrue();
					expect(reFindNoCase("upgrade|update", be) > 0).toBeTrue();
				});

			});

		});

	}

}
