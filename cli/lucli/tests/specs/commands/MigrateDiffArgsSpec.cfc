/**
 * Unit coverage for the `wheels migrate diff` argument surface —
 * $parseMigrateDiffArgs() and $buildDiffBridgeUrl(). The bridge round-trip
 * itself is covered by CliBridgeSpec on the framework side; these cases pin
 * the CLI-side parsing contract without needing a running app server.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("$parseMigrateDiffArgs", () => {

			it("defaults to a diffAll preview with no flags", () => {
				var opts = mod.$parseMigrateDiffArgs(["diff"]);
				expect(opts.model).toBe("");
				expect(opts.write).toBeFalse();
				expect(opts.threshold).toBe("");
			});

			it("captures a positional model", () => {
				var opts = mod.$parseMigrateDiffArgs(["diff", "User"]);
				expect(opts.model).toBe("User");
			});

			it("parses a single OLD:NEW rename pair", () => {
				var opts = mod.$parseMigrateDiffArgs(["diff", "User", "--rename=full_name:fullName"]);
				expect(opts.hints.renames).toHaveKey("full_name");
				expect(opts.hints.renames.full_name).toBe("fullName");
			});

			it("parses multiple rename pairs (equals form)", () => {
				var opts = mod.$parseMigrateDiffArgs(["diff", "User", "--rename=a:b", "--rename=c:d"]);
				expect(opts.hints.renames.a).toBe("b");
				expect(opts.hints.renames.c).toBe("d");
			});

			it("parses the diffAll Model.OLD:NEW form into per-model hints", () => {
				var opts = mod.$parseMigrateDiffArgs(["diff", "--rename=User.full_name:fullName"]);
				expect(opts.hints.renames).toHaveKey("User");
				expect(opts.hints.renames.User.full_name).toBe("fullName");
			});

			it("merges --hints JSON with --rename pairs", () => {
				var opts = mod.$parseMigrateDiffArgs([
					"diff", "User",
					'--hints={"renames":{"title":"name"}}',
					"--rename=body:content"
				]);
				expect(opts.hints.renames.title).toBe("name");
				expect(opts.hints.renames.body).toBe("content");
			});

			it("rejects malformed --hints JSON", () => {
				expect(() => mod.$parseMigrateDiffArgs(["diff", "User", "--hints=not-json"]))
					.toThrow("Wheels.InvalidArguments");
			});

			it("rejects a malformed rename pair", () => {
				expect(() => mod.$parseMigrateDiffArgs(["diff", "User", "--rename=no-colon-here"]))
					.toThrow("Wheels.InvalidArguments");
			});

			it("rejects an out-of-range threshold", () => {
				expect(() => mod.$parseMigrateDiffArgs(["diff", "User", "--threshold=7"]))
					.toThrow("Wheels.InvalidArguments");
			});

			it("captures threshold, name, and write", () => {
				var opts = mod.$parseMigrateDiffArgs(["diff", "User", "--threshold=0.85", "--name=rename_name_field", "--write"]);
				expect(opts.threshold).toBe("0.85");
				expect(opts.name).toBe("rename_name_field");
				expect(opts.write).toBeTrue();
			});

		});

		describe("$buildDiffBridgeUrl", () => {

			it("is empty for a bare diffAll preview", () => {
				var opts = {model: "", hints: {}, threshold: "", name: "", write: false};
				expect(mod.$buildDiffBridgeUrl(opts)).toBe("");
			});

			it("encodes the model and hints", () => {
				var opts = {model: "Blog Post", hints: {renames: {"old name": "newName"}}, threshold: "", name: "", write: false};
				var suffix = mod.$buildDiffBridgeUrl(opts);
				expect(suffix).toInclude("modelName=");
				expect(suffix).toInclude("hints=");
			});

			it("adds write=true and the name only when writing", () => {
				var opts = {model: "User", hints: {}, threshold: "", name: "renameField", write: true};
				var suffix = mod.$buildDiffBridgeUrl(opts);
				expect(suffix).toInclude("write=true");
				expect(suffix).toInclude("name=renameField");
				// name must not leak into a preview
				opts.write = false;
				expect(mod.$buildDiffBridgeUrl(opts)).notToInclude("&name=");
			});

		});

		describe("$isOffline / $consumeOfflineFlag", () => {

			it("is false by default", () => {
				expect(mod.$isOffline()).toBeFalse();
			});

			it("turns true when --offline is consumed", () => {
				mod.__arguments = ["migrate", "--offline", "diff"];
				mod.$consumeOfflineFlag(["migrate", "--offline", "diff"]);
				expect(mod.$isOffline()).toBeTrue();
				expect(request.$wheelsOffline).toBeTrue();
				// tidy up so later specs in this bundle aren't affected
				structDelete(request, "$wheelsOffline");
				mod.__arguments = [];
			});

		});

	}

}
