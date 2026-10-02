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

	private any function pathOf(required string location) {
		return createObject("java", "java.io.File").init(arguments.location).toPath();
	}

	/** Create a symbolic link at `link` pointing to `target`. */
	private void function symlink(required string link, required string target) {
		var noAttributes = createObject("java", "java.lang.reflect.Array").newInstance(
			createObject("java", "java.lang.Class").forName("java.nio.file.attribute.FileAttribute"),
			javaCast("int", 0)
		);
		createObject("java", "java.nio.file.Files").createSymbolicLink(pathOf(arguments.link), pathOf(arguments.target), noAttributes);
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

		describe("$resolveTestFilter and symlinks (issue 3800)", () => {

			beforeEach(() => {
				variables.linkRoot = getTempDirectory() & "wheels-cli-spec-links-" & createUUID();
				directoryCreate(variables.linkRoot & "/config", true, true);
				directoryCreate(variables.linkRoot & "/tests/specs/favorites", true, true);
				directoryCreate(variables.linkRoot & "/tests/specsOld", true, true);
				fileWrite(variables.linkRoot & "/config/settings.cfm", "<cfscript>" & chr(10) & "</cfscript>" & chr(10));
				fileWrite(variables.linkRoot & "/tests/specs/favorites/PageFavoritesToggleSpec.cfc", "component {}" & chr(10));
				fileWrite(variables.linkRoot & "/tests/specsOld/OrphanSpec.cfc", "component {}" & chr(10));
				variables.linksMade = true;
				try {
					// A sibling whose name starts with the spec root's name.
					symlink(variables.linkRoot & "/tests/specs/legacy", variables.linkRoot & "/tests/specsOld");
					// A second path to a folder already inside the spec root.
					symlink(variables.linkRoot & "/tests/specs/alias", variables.linkRoot & "/tests/specs/favorites");
				} catch (any e) {
					// No symlink support here (e.g. Windows without the privilege).
					variables.linksMade = false;
				}
				variables.linkMod = new cli.lucli.Module(cwd = variables.linkRoot);
			});

			afterEach(() => {
				for (var link in ["/tests/specs/legacy", "/tests/specs/alias"]) {
					try {
						createObject("java", "java.nio.file.Files").deleteIfExists(pathOf(variables.linkRoot & link));
					} catch (any e) {
					}
				}
				if (Len(variables.linkRoot) > 10 && directoryExists(variables.linkRoot)) {
					directoryDelete(variables.linkRoot, true);
				}
			});

			it("does not treat a sibling folder that starts with the spec root's name as inside it", () => {
				if (!variables.linksMade) return;
				// Before: "tests.specs.ld.OrphanSpec" (the prefix test had no separator boundary).
				expect(linkMod.$resolveTestFilter("OrphanSpec")).toBe("tests.specs.OrphanSpec");
			});

			it("counts a file reached by two paths inside the spec root once", () => {
				if (!variables.linksMade) return;
				// Before: Wheels.AmbiguousTestFilter listing the same path twice.
				expect(linkMod.$resolveTestFilter("PageFavoritesToggleSpec")).toBe("tests.specs.favorites.PageFavoritesToggleSpec");
			});

		});

		describe("$pathWithinExact", () => {

			it("accepts the root itself and its descendants", () => {
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/specs", "/")).toBeTrue();
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/specs/models/UserSpec.cfc", "/")).toBeTrue();
				expect(mod.$pathWithinExact("/srv/App/tests/specs/", "/srv/App/tests/specs/UserSpec.cfc", "/")).toBeTrue();
			});

			it("compares exactly", () => {
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/Specs/UserSpec.cfc", "/")).toBeFalse();
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/app/tests/specs/UserSpec.cfc", "/")).toBeFalse();
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/SPECS", "/")).toBeFalse();
			});

			it("requires a separator boundary after the root", () => {
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/specsOld/OrphanSpec.cfc", "/")).toBeFalse();
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/spec", "/")).toBeFalse();
			});

			it("treats a backslash as a filename character where the separator is /", () => {
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/specs\deep/UserSpec.cfc", "/")).toBeFalse();
				expect(mod.$pathWithinExact("/srv/App/tests/specs", "/srv/App/tests/specs\UserSpec.cfc", "/")).toBeFalse();
				expect(mod.$pathWithinExact("/srv/App/tests/specs\", "/srv/App/tests/specs\/UserSpec.cfc", "/")).toBeTrue();
			});

			it("treats a backslash as a separator where the separator is \", () => {
				expect(mod.$pathWithinExact("C:\App\tests\specs", "C:\App\tests\specs", "\")).toBeTrue();
				expect(mod.$pathWithinExact("C:\App\tests\specs", "C:\App\tests\specs\models\UserSpec.cfc", "\")).toBeTrue();
				expect(mod.$pathWithinExact("C:\App\tests\specs\", "C:\App\tests\specs\UserSpec.cfc", "\")).toBeTrue();
				expect(mod.$pathWithinExact("C:\App\tests\specs", "C:\App\tests\Specs\UserSpec.cfc", "\")).toBeFalse();
				expect(mod.$pathWithinExact("C:\App\tests\specs", "C:\App\tests\specsOld\UserSpec.cfc", "\")).toBeFalse();
			});

			it("defaults to the platform separator", () => {
				expect(mod.$nativeSeparator()).toBe(createObject("java", "java.io.File").separator);
				expect(mod.$pathWithinExact(variables.tempRoot, variables.tempRoot & "/tests/specs")).toBeTrue();
			});

		});

		describe("$resolveTestFilter and a sibling of the spec root", () => {

			beforeEach(() => {
				variables.siblingRoot = getTempDirectory() & "wheels-cli-spec-sibling-" & createUUID();
				directoryCreate(variables.siblingRoot & "/config", true, true);
				directoryCreate(variables.siblingRoot & "/tests/specs/favorites", true, true);
				fileWrite(variables.siblingRoot & "/config/settings.cfm", "<cfscript>" & chr(10) & "</cfscript>" & chr(10));
				fileWrite(variables.siblingRoot & "/tests/specs/favorites/PageFavoritesToggleSpec.cfc", "component {}" & chr(10));
				variables.siblingReason = "";
				// tests/Specs is a separate directory only on a case-sensitive filesystem.
				if (directoryExists(variables.siblingRoot & "/tests/Specs")) {
					variables.siblingReason = "needs a case-sensitive filesystem (tests/Specs and tests/specs are one directory here)";
				} else {
					directoryCreate(variables.siblingRoot & "/tests/Specs/deep", true, true);
					fileWrite(variables.siblingRoot & "/tests/Specs/deep/SiblingSpec.cfc", "component {}" & chr(10));
					try {
						symlink(variables.siblingRoot & "/tests/specs/linked", variables.siblingRoot & "/tests/Specs");
					} catch (any e) {
						variables.siblingReason = "needs symbolic link support";
					}
				}
				variables.siblingMod = new cli.lucli.Module(cwd = variables.siblingRoot);
			});

			afterEach(() => {
				try {
					createObject("java", "java.nio.file.Files").deleteIfExists(pathOf(variables.siblingRoot & "/tests/specs/linked"));
				} catch (any e) {
				}
				if (Len(variables.siblingRoot) > 10 && directoryExists(variables.siblingRoot)) {
					directoryDelete(variables.siblingRoot, true);
				}
			});

			it("does not treat a linked sibling folder of the spec root as inside it", () => {
				if (Len(variables.siblingReason)) {
					skip(variables.siblingReason);
				}
				// Treated as inside, it would resolve to "tests.specs.deep.SiblingSpec".
				expect(siblingMod.$resolveTestFilter("SiblingSpec")).toBe("tests.specs.SiblingSpec");
			});

			it("still resolves spec files inside the spec root", () => {
				expect(siblingMod.$resolveTestFilter("PageFavoritesToggleSpec")).toBe("tests.specs.favorites.PageFavoritesToggleSpec");
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
