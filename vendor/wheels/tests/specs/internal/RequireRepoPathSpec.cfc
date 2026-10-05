/**
 * Specs that read files only the framework repository has (cli/, tools/, .github/,
 * web/, the demo app) call $requireRepoPath() first, so the framework suite run from an
 * app reports them as skipped, naming the path, instead of erroring.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$requireRepoPath()", () => {

			it("returns the absolute path inside the framework repository", () => {
				// Skips itself inside an app, like every caller.
				var path = $requireRepoPath("cli/lucli/templates");
				expect(DirectoryExists(path)).toBeTrue(path);
				expect(path).toBe($frameworkRepoRoot() & "cli/lucli/templates");
				expect($requireRepoPath("/cli/lucli/templates")).toBe(path);
			});

			it("skips the spec, naming the path, outside the framework repository", () => {
				var root = $tempPath("wheels-reporoot-#CreateUUID()#/");
				DirectoryCreate(root);
				var state = {type = "", message = ""};
				try {
					var probe = new wheels.tests._assets.wheelstest.RepoRootProbe().setProbeRoot(root);
					try {
						probe.$requireRepoPath("cli/lucli/Module.cfc");
					} catch (any e) {
						state.type = e.type;
						state.message = e.message;
					}
				} finally {
					$removeTree(root);
				}
				expect(state.type).toBe("TestBox.SkipSpec");
				expect(state.message).toInclude("'cli/lucli/Module.cfc'");
				expect(state.message).toInclude("Wheels framework repository");
			});

		});

		describe("repository-only specs", () => {

			it("read repository-only paths only after $requireRepoPath()", () => {
				// Every spec that names a path only the repository has (the CLI source and
				// templates, .github, tools/ scripts, the guides and packages sites, the
				// example apps) calls $requireRepoPath(), or uses the older inRepo check.
				var repoOnly = "(cli/(lucli|src)/|\.github/|tools/(build|ci|docker|distribution-drafts|rustcfml)/|web/(sites|packages)/|examples/)";
				var specsRoot = ExpandPath("/wheels/tests/specs");
				var unguarded = [];
				for (var path in DirectoryList(specsRoot, true, "path", "*.cfc")) {
					// Code lines only: a path named in a comment reads nothing.
					var code = [];
					for (var line in ListToArray(FileRead(path), Chr(10))) {
						if (!ReFind("^\s*(//|/\*|\*)", line)) {
							ArrayAppend(code, line);
						}
					}
					var source = ArrayToList(code, Chr(10));
					if (ReFind(repoOnly, source) && !FindNoCase("$requireRepoPath(", source) && !FindNoCase("inRepo", source)) {
						ArrayAppend(unguarded, Replace(Replace(path, "\", "/", "all"), Replace(specsRoot, "\", "/", "all"), ""));
					}
				}
				expect(unguarded).toBe([], "read repository-only paths without $requireRepoPath(): " & ArrayToList(unguarded, ", "));
			});

		});

		describe("framework-repository runs", () => {

			it("can see the repository whenever WHEELS_EXPECT_REPO is set", () => {
				// compose.yml, pr.yml and tools/rustcfml/run-suite.sh set WHEELS_EXPECT_REPO for
				// repository runs. There, a missing repository marker would make every guarded
				// spec skip and the run stay green, so this fails instead. Unset, it skips with
				// the reason, so a repository run the variable did not reach shows a named skip
				// rather than a pass.
				var env = (StructKeyExists(server, "system") && StructKeyExists(server.system, "environment")) ? server.system.environment : {};
				var expected = StructKeyExists(env, "WHEELS_EXPECT_REPO") && CompareNoCase(Trim(env.WHEELS_EXPECT_REPO), "true") == 0;
				if (!expected) {
					skip("WHEELS_EXPECT_REPO not set (expected outside the Wheels repo).");
				}
				var marker = $frameworkRepoRoot() & "cli/lucli/templates";
				expect(DirectoryExists(marker)).toBeTrue(
					"WHEELS_EXPECT_REPO is set, but " & marker & " is missing: every spec that needs the Wheels framework repository would skip."
				);
			});

		});

	}

}
