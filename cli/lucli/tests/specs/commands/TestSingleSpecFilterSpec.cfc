/**
 * `wheels test` single-spec-file runs (issue 3759).
 *
 * $resolveTestFilter() turns a bare spec name into the dotted path of the one
 * file it names, so the runner can run it as a single bundle; an ambiguous
 * name fails with the candidates instead of guessing. $testSummaryLine()
 * keeps a run that discovered no bundles from printing a green summary.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.tempRoot = getTempDirectory() & "wheels-cli-single-spec-" & createUUID();
		for (var dir in [
			"/config",
			"/tests/specs/favorites",
			"/tests/specs/models",
			"/tests/specs/controllers",
			"/vendor/wheels/tests/specs/dispatch"
		]) {
			directoryCreate(variables.tempRoot & dir, true, true);
		}
		fileWrite(variables.tempRoot & "/config/settings.cfm", "<cfscript>" & chr(10) & "</cfscript>" & chr(10));
		for (var spec in [
			"/tests/specs/favorites/PageFavoritesToggleSpec.cfc",
			"/tests/specs/models/UserSpec.cfc",
			"/tests/specs/controllers/UserSpec.cfc",
			"/vendor/wheels/tests/specs/dispatch/RouteThingSpec.cfc"
		]) {
			fileWrite(variables.tempRoot & spec, "component {}" & chr(10));
		}
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		if (Len(variables.tempRoot) > 10 && directoryExists(variables.tempRoot)) {
			directoryDelete(variables.tempRoot, true);
		}
	}

	function run() {

		describe("$resolveTestFilter (issue 3759)", () => {

			it("resolves a bare spec name to the dotted path of the one file it names", () => {
				expect(mod.$resolveTestFilter("PageFavoritesToggleSpec")).toBe("tests.specs.favorites.PageFavoritesToggleSpec");
			});

			it("resolves a bare spec name in core mode under the framework spec root", () => {
				expect(mod.$resolveTestFilter("RouteThingSpec", true)).toBe("wheels.tests.specs.dispatch.RouteThingSpec");
			});

			it("keeps a folder name as a folder scope", () => {
				expect(mod.$resolveTestFilter("favorites")).toBe("tests.specs.favorites");
			});

			it("passes an explicit dotted spec path through unchanged", () => {
				expect(mod.$resolveTestFilter("tests.specs.models.UserSpec")).toBe("tests.specs.models.UserSpec");
			});

			it("leaves a name that matches no file to the runner's 0-bundle failure", () => {
				expect(mod.$resolveTestFilter("NoSuchSpecAnywhere")).toBe("tests.specs.NoSuchSpecAnywhere");
			});

			it("returns empty for an empty filter", () => {
				expect(mod.$resolveTestFilter("")).toBe("");
			});

			it("refuses an ambiguous name and lists every matching dotted path", () => {
				var state = {type = "", message = ""};
				try {
					mod.$resolveTestFilter("UserSpec");
				} catch (any e) {
					state.type = e.type;
					state.message = e.message & " " & e.detail;
				}
				expect(state.type).toBe("Wheels.AmbiguousTestFilter");
				expect(state.message).toInclude("tests.specs.controllers.UserSpec");
				expect(state.message).toInclude("tests.specs.models.UserSpec");
			});

		});

		describe("$testSummaryLine (issue 3759)", () => {

			it("never prints a green summary when no test bundles ran", () => {
				var line = mod.$testSummaryLine(
					result = {totalPass = 0, totalFail = 0, totalError = 0, bundlesDiscovered = 0},
					totalPass = 0, totalFail = 0, totalError = 0, duration = "", specsFailedToLoad = 0
				);
				expect(line.color).toBe("red");
				expect(line.text).toInclude("no test bundles ran");
			});

			it("prints a green summary for a real passing run", () => {
				var line = mod.$testSummaryLine(
					result = {totalPass = 3, totalFail = 0, totalError = 0, bundlesDiscovered = 1},
					totalPass = 3, totalFail = 0, totalError = 0, duration = " (0.10s)", specsFailedToLoad = 0
				);
				expect(line.color).toBe("green");
				expect(line.text).toBe("3 passed (0.10s)");
			});

			it("prints a red summary when specs failed", () => {
				var line = mod.$testSummaryLine(
					result = {totalPass = 2, totalFail = 1, totalError = 0, bundlesDiscovered = 1},
					totalPass = 2, totalFail = 1, totalError = 0, duration = "", specsFailedToLoad = 0
				);
				expect(line.color).toBe("red");
				expect(line.text).toBe("2 passed, 1 failed, 0 error(s)");
			});

			it("prints a yellow summary when specs failed to load", () => {
				var line = mod.$testSummaryLine(
					result = {totalPass = 2, totalFail = 0, totalError = 0, bundlesDiscovered = 1},
					totalPass = 2, totalFail = 0, totalError = 0, duration = "", specsFailedToLoad = 1
				);
				expect(line.color).toBe("yellow");
				expect(line.text).toBe("2 passed, 1 failed to load");
			});

		});

	}

}
