/**
 * The CLI's RustCFML engine pin must equal tools/rustcfml/ENGINE_VERSION, the
 * build the framework's RustCFML CI leg and compat matrix run (#3812), and its
 * per-asset sha256 pins must equal tools/rustcfml/ENGINE_SHA256. The installed
 * CLI doesn't ship tools/, so it carries its own copy of both;
 * tools/rustcfml/bump-pin.sh moves them together, and this fails if they part.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("RustCFMLEngine pins (##3812)", () => {

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

			it("is on the one line tools/rustcfml/bump-pin.sh rewrites", () => {
				var source = fileRead(expandPath("/cli/lucli/services/rustcfml/RustCFMLEngine.cfc"));
				var lines = reMatch("(?m)^[ \t]*variables\.engineVersion = ""v[0-9]+\.[0-9]+\.[0-9]+"";[ \t]*$", source);
				expect(arrayLen(lines)).toBe(1, "bump-pin.sh can only move a pin written as: variables.engineVersion = ""vX.Y.Z"";");
			});

			it("pins the same sha256 per release asset as tools/rustcfml/ENGINE_SHA256", () => {
				var repoRoot = createObject("java", "java.io.File").init(expandPath("/cli") & "/..").getCanonicalPath();
				var shaFile = repoRoot & "/tools/rustcfml/ENGINE_SHA256";
				expect(fileExists(shaFile)).toBeTrue("Missing #shaFile#");
				// sha256sum format: "<64 hex>  <asset>" per line.
				var pinned = {};
				for (var line in listToArray(fileRead(shaFile), chr(10))) {
					line = trim(line);
					if (!len(line)) continue;
					expect(reFind("^[0-9a-f]{64}  rustcfml-[a-z0-9_-]+$", line)).toBe(1, "Unexpected ENGINE_SHA256 line: [#line#]");
					pinned[listLast(line, " ")] = listFirst(line, " ");
				}
				expect(structKeyList(pinned)).notToBe("", "ENGINE_SHA256 pins no assets");
				var cliPins = new cli.lucli.services.rustcfml.RustCFMLEngine().getEngineSha256();
				expect(listSort(structKeyList(cliPins), "textnocase")).toBe(
					listSort(structKeyList(pinned), "textnocase"),
					"RustCFMLEngine.cfc and tools/rustcfml/ENGINE_SHA256 pin different assets."
				);
				for (var asset in pinned) {
					expect(cliPins[asset]).toBe(
						pinned[asset],
						"cli/lucli/services/rustcfml/RustCFMLEngine.cfc pins a different sha256 for #asset# than tools/rustcfml/ENGINE_SHA256."
					);
				}
			});

			it("pins every published asset's sha256 on a line tools/rustcfml/bump-pin.sh rewrites", () => {
				var source = fileRead(expandPath("/cli/lucli/services/rustcfml/RustCFMLEngine.cfc"));
				for (var asset in ["rustcfml-linux-aarch64", "rustcfml-linux-x86_64", "rustcfml-macos-aarch64"]) {
					var lines = reMatch("(?m)^[ \t]*variables\.engineSha256\[""#asset#""\] = ""[0-9a-f]{64}"";[ \t]*$", source);
					expect(arrayLen(lines)).toBe(
						1,
						"bump-pin.sh can only move a sha256 pin written as: variables.engineSha256[""#asset#""] = ""<64 hex>"";"
					);
				}
			});

		});

	}

}
