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
 * These specs simulate the include path by assigning a UDF directly to
 * `application.wo` (which is exactly the shape an included function takes:
 * a struct key on the component, not a metadata-enumerable function), then
 * instantiate a fresh `wheels.WheelsTest` and assert the auto-bind loop
 * caught it.
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
