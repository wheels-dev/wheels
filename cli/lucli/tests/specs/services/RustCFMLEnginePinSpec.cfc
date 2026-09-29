/**
 * The CLI's RustCFML engine pin must equal tools/rustcfml/ENGINE_VERSION, the
 * build the framework's RustCFML CI leg and compat matrix run (#3812). The
 * installed CLI doesn't ship tools/, so it carries its own copy of the pin;
 * tools/rustcfml/check-version.sh moves both, and this fails if they part.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("RustCFMLEngine pin (##3812)", () => {

			it("equals tools/rustcfml/ENGINE_VERSION", () => {
				// The /cli mapping is the repo's cli/ folder; "/" is the public/ webroot.
				var repoRoot = createObject("java", "java.io.File").init(expandPath("/cli") & "/..").getCanonicalPath();
				var pinFile = repoRoot & "/tools/rustcfml/ENGINE_VERSION";
				expect(fileExists(pinFile)).toBeTrue("Missing #pinFile#");
				var pinned = trim(fileRead(pinFile));
				expect(reFind("^v[0-9]+\.[0-9]+\.[0-9]+$", pinned) == 1 && len(pinned) < 20).toBeTrue("Unexpected ENGINE_VERSION: [#pinned#]");
				expect(new cli.lucli.services.rustcfml.RustCFMLEngine().getEngineVersion()).toBe(
					pinned,
					"cli/lucli/services/rustcfml/RustCFMLEngine.cfc pins a different RustCFML build than tools/rustcfml/ENGINE_VERSION."
				);
			});

			it("is on the one line tools/rustcfml/check-version.sh rewrites", () => {
				var source = fileRead(expandPath("/cli/lucli/services/rustcfml/RustCFMLEngine.cfc"));
				var lines = reMatch("(?m)^[ \t]*variables\.engineVersion = ""v[0-9]+\.[0-9]+\.[0-9]+"";[ \t]*$", source);
				expect(arrayLen(lines)).toBe(1, "check-version.sh can only move a pin written as: variables.engineVersion = ""vX.Y.Z"";");
			});

		});

	}

}
