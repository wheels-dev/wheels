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
			// the legacy plugin directory, etc.). `fullSource` is kept for
			// assertions on the scanner's surroundings (exit-code throw,
			// --format=json plumbing) that live outside the checks block.
			var block = "";
			var fullSource = "";
			if (fileExists(modulePath)) {
				fullSource = fileRead(modulePath);
				var start = find("currentMajor <= 3 && targetMajor >= 4", fullSource);
				if (start > 0) {
					var endIdx = find("// Run checks", fullSource, start);
					var sliceLen = endIdx > 0 ? endIdx - start : len(fullSource) - start + 1;
					block = sliceLen > 0 ? mid(fullSource, start, sliceLen) : "";
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

			it("scans for deprecated paginationLinks() helper", () => {
				expect(findNoCase("paginationLinks", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep views for paginationLinks( (renamed to paginationNav(), CHANGELOG ##2714)."
				);
			});

			it("scans for wirebox.system.ioc bootstraps including the root Application.cfc", () => {
				expect(findNoCase("wirebox.system.ioc", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep for wirebox.system.ioc (the guide's hardest item-10 case is a "
					& "`new wirebox.system.ioc.Injector(...)` bootstrap in the root Application.cfc)."
				);
				expect(findNoCase("Application.cfc", block) > 0).toBeTrue(
					"The WireBox check must scan the root Application.cfc, not only app/ — the 3.x bootstrap lives at the project root."
				);
			});

			it("covers wheels.Testbox and single-quoted extends forms in the test base class grep", () => {
				expect(findNoCase("wheels\.Test(box)?", block) > 0).toBeTrue(
					"The test base class grep should match wheels.Testbox (the silent WheelsTest alias, removal target 5.0) "
					& "and both quote styles via a quote character class, not a hardcoded double quote."
				);
			});

			it("scans for removed renderPage()/renderPageToString() helpers", () => {
				expect(findNoCase("renderPage", block) > 0).toBeTrue(
					"3.x -> 4.x checks should grep app/ for renderPage()/renderPageToString() — removed in 4.0, "
					& "shimmed only by the optional wheels-legacy-adapter package."
				);
			});

			it("carries an HSTS advisory (SecurityHeaders defaults on in production)", () => {
				expect(findNoCase("SecurityHeaders", block) > 0).toBeTrue(
					"3.x -> 4.x checks should carry an advisory for the HSTS default flip (guide item 2, CHANGELOG ##2081)."
				);
			});

			it("carries a CSRF SameSite advisory", () => {
				expect(findNoCase("SameSite", block) > 0).toBeTrue(
					"3.x -> 4.x checks should carry an advisory for the CSRF cookie SameSite attribute (guide item 6, CHANGELOG ##2035)."
				);
				expect(findNoCase("protectsFromForgery", block) > 0).toBeTrue(
					"The SameSite advisory should key off protectsFromForgery usage so only CSRF-protected apps are flagged."
				);
			});

			it("exits non-zero when breaking findings exist (Wheels.UpgradeCheckFailed)", () => {
				expect(findNoCase("Wheels.UpgradeCheckFailed", fullSource) > 0).toBeTrue(
					"runUpgradeCheck must throw Wheels.UpgradeCheckFailed after the report flushes so breaking findings "
					& "gate CI with a non-zero exit (mirrors validate()'s Wheels.ValidationFailed)."
				);
			});

			it("supports --format=json for machine-readable CI output", () => {
				expect(findNoCase("--format=json", fullSource) > 0).toBeTrue(
					"wheels upgrade check should document/accept --format=json so pipelines can consume the report."
				);
			});

		});

	}

}
