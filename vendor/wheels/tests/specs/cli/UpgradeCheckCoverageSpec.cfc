/**
 * Regression for issue ##2628: `wheels upgrade check --to=4.0.0` for
 * `currentMajor <= 3 && targetMajor >= 4` in cli/lucli/Module.cfc scans
 * only 3 of the 11 documented breakers from the canonical 3.x → 4.0
 * guide. A 3.x user can run the check, see the WireBox bootstrap, the
 * plugin folder, and the test base class flagged, upgrade, and then
 * hit one of the unscanned breakers in production.
 *
 * The spec inspects the source of Module.cfc statically and asserts
 * that each documented breaker pattern appears in the 3.x -> 4.x
 * checks block. This avoids instantiating the CLI Module (which
 * depends on the LuCLI `modules.BaseModule` runtime) and keeps the
 * assertion close to the data we ship.
 *
 * Canonical reference: web/sites/guides/src/content/docs/v4-0-0/upgrading/3x-to-4x.mdx
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels upgrade check 3.x -> 4.x breaker coverage", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var modulePath = repoRoot & "/cli/lucli/Module.cfc";

			it("Module.cfc exists at the expected path", () => {
				expect(fileExists(modulePath)).toBeTrue("Missing: " & modulePath);
			});

			// Slice out the 3.x -> 4.x branch so assertions don't accidentally
			// match the 2.x -> 3.x checks (which also reference wheels.Test,
			// the legacy plugin directory, etc.).
			var block = "";
			if (fileExists(modulePath)) {
				var moduleSource = fileRead(modulePath);
				var start = find("currentMajor <= 3 && targetMajor >= 4", moduleSource);
				if (start > 0) {
					var endIdx = find("// Run checks", moduleSource, start);
					var sliceLen = endIdx > 0 ? endIdx - start : len(moduleSource) - start + 1;
					block = sliceLen > 0 ? mid(moduleSource, start, sliceLen) : "";
				}
			}

			it("scans for CORS default flip (deny-all) — bare wheels.middleware.Cors()", () => {
				expect(findNoCase("wheels.middleware.Cors", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep config/ for new wheels.middleware.Cors() without allowOrigins (CHANGELOG ##2039)."
				);
			});

			it("scans for RateLimiter without explicit trustProxy/proxyStrategy", () => {
				expect(findNoCase("RateLimiter", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep config/ for RateLimiter middleware missing trustProxy/proxyStrategy (CHANGELOG ##2024, ##2088)."
				);
			});

			it("scans for allowEnvironmentSwitchViaUrl=true", () => {
				expect(findNoCase("allowEnvironmentSwitchViaUrl", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep config/ for allowEnvironmentSwitchViaUrl=true (CHANGELOG ##2076)."
				);
			});

			it("scans for missing csrfEncryptionKey configuration", () => {
				expect(findNoCase("csrfEncryptionKey", block) > 0).toBeTrue(
					"3.x -> 4.x checks should detect a missing csrfEncryptionKey in config/ (CHANGELOG ##2054, ##2079)."
				);
			});

			it("scans for legacy 'wheels snippets' invocations in build/CI scripts", () => {
				expect(findNoCase("wheels snippets", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep build scripts and CI for the legacy 'wheels snippets' command, renamed to 'wheels generate snippets' (CHANGELOG ##1852)."
				);
			});

			it("scans for legacy tests/specs/functions/ directory", () => {
				expect(findNoCase("tests/specs/functions", block) > 0).toBeTrue(
					"3.x -> 4.x checks should detect the legacy tests/specs/functions/ directory, renamed to functional/ (CHANGELOG ##1872)."
				);
			});

			it("scans for Vite asset helpers (manifest strictness default flip)", () => {
				var hasVite = findNoCase("viteScriptTag", block) > 0
					|| findNoCase("viteStyleTag", block) > 0
					|| findNoCase("vitePreloadTag", block) > 0;
				expect(hasVite).toBeTrue(
					"3.x -> 4.x checks should grep views for viteScriptTag/viteStyleTag/vitePreloadTag (viteStrictManifest default flip, CHANGELOG ##2133)."
				);
			});

		});

	}

}
