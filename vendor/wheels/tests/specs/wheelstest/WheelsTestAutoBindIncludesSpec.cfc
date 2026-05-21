/**
 * Regression: WheelsTest auto-bind misses include-injected helpers (#2790).
 *
 * `WheelsTest.cfc` uses `getMetaData(application.wo).functions` to discover
 * which Wheels globals to bind into the spec's `variables` / `this` scopes.
 * That metadata enumerates only methods defined directly on the CFC body,
 * NOT symbols merged in via `cfinclude` / `include` (which is how
 * `vendor/wheels/Global.cfc` pulls `/app/global/functions.cfm` at the bottom
 * of the file). User-defined global helpers therefore worked in controllers /
 * views / models but were invisible to test specs — every spec had to
 * manually rebind helpers in `beforeAll()`.
 *
 * Cross-engine note: a bare `include` inside a CFC body lands UDFs in the
 * component's `variables` scope, not `this`. Lucee's struct-iteration over
 * a CFC instance surfaces both scopes, but Adobe CF's contract only
 * reliably exposes `this`-scope members. To make the auto-bind path
 * uniform across engines, `vendor/wheels/Global.cfc` promotes include-
 * injected UDFs from `variables` to `this` immediately after the include
 * runs. These specs simulate that post-promotion shape by assigning the
 * probe UDF directly to `application.wo` (bracket-notation assignment
 * from outside writes to `this`), then assert that:
 *
 * - The probe is invisible to `getMetaData(application.wo).functions`
 *   (the bug precondition the old code missed).
 * - The probe is enumerated by `for (key in application.wo)` — the
 *   iteration mechanism the new auto-bind loop relies on. Failure here
 *   on any engine means the auto-bind loop will silently miss the helper.
 * - The probe lands on a fresh `wheels.WheelsTest` instance and is
 *   callable.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("WheelsTest auto-bind", () => {

			describe("helpers attached to application.wo outside of CFC metadata (issue ##2790)", () => {

				it("the bug precondition holds: include-style UDFs are invisible to getMetaData", () => {
					var probeName = "$bot2790MetaProbe";
					application.wo[probeName] = function() {
						return "metadata-probe";
					};
					try {
						var meta = getMetaData(application.wo).functions;
						var foundInMeta = false;
						for (var fn in meta) {
							if (fn.name == probeName) {
								foundInMeta = true;
								break;
							}
						}
						expect(foundInMeta).toBeFalse();
						expect(structKeyExists(application.wo, probeName)).toBeTrue();
						expect(isCustomFunction(application.wo[probeName])).toBeTrue();
					} finally {
						structDelete(application.wo, probeName);
					}
				});

				it("for-in iteration over application.wo enumerates the probe key", () => {
					// Guards the iteration mechanism the auto-bind loop in
					// WheelsTest.cfc relies on. If this fails on any engine
					// (notably Adobe CF, where struct-iteration over a CFC
					// only reliably exposes this-scope members), the bind
					// case below will silently pass-but-not-test.
					var probeName = "$bot2790IterProbe";
					application.wo[probeName] = function() {
						return "iter-probe";
					};
					try {
						var seen = false;
						for (var key in application.wo) {
							if (key == probeName) {
								seen = true;
								break;
							}
						}
						expect(seen).toBeTrue();
					} finally {
						structDelete(application.wo, probeName);
					}
				});

				it("auto-binds include-style helpers into a fresh WheelsTest instance", () => {
					var probeName = "$bot2790BindProbe";
					application.wo[probeName] = function() {
						return "bind-probe";
					};
					try {
						var freshSpec = new wheels.WheelsTest();
						expect(structKeyExists(freshSpec, probeName)).toBeTrue();
						var bound = freshSpec[probeName];
						expect(bound()).toBe("bind-probe");
					} finally {
						structDelete(application.wo, probeName);
					}
				});

				it("still binds methods that ARE in CFC metadata (regression guard for the existing path)", () => {
					var freshSpec = new wheels.WheelsTest();
					expect(structKeyExists(freshSpec, "model")).toBeTrue();
					expect(structKeyExists(freshSpec, "urlFor")).toBeTrue();
				});

			});

		});

	}

}
