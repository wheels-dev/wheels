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

			it("read cli/lucli/templates only after $requireRepoPath()", () => {
				// Every spec under this suite that reads the CLI templates either calls
				// $requireRepoPath() or is listed here with the reason it can run anywhere.
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
					if (FindNoCase("cli/lucli/templates", source) && !FindNoCase("$requireRepoPath(", source) && !FindNoCase("inRepo", source)) {
						ArrayAppend(unguarded, Replace(Replace(path, "\", "/", "all"), Replace(specsRoot, "\", "/", "all"), ""));
					}
				}
				expect(unguarded).toBe([], "read cli/lucli/templates without $requireRepoPath(): " & ArrayToList(unguarded, ", "));
			});

		});

	}

}
