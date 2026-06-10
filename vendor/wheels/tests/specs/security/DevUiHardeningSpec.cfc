/**
 * Dev-UI hardening leftovers from the 2026-06-09 review campaign (issue #2974):
 *
 * 1. The JSON branch of /wheels/info serialized the full
 *    getApplicationMetadata() struct — datasource definitions (credentials),
 *    ORM settings, and arbitrary application config flowed into the response
 *    wholesale, bypassing the per-setting redaction shipped for the settings
 *    list (#2909 deferral). The metadata is now reduced to a whitelisted
 *    subset via Public.$safeApplicationMetadata().
 *
 * 2. /wheels/public/docs/core.cfm included "layouts/<format>.cfm" with an
 *    unvalidated, user-controllable format param — the same traversal class
 *    $getRequestFormat() was hardened against (#2900 sibling).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Dev-UI hardening (issue ##2974)", () => {

			describe("$safeApplicationMetadata()", () => {

				it("keeps only whitelisted metadata keys", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var fakeMeta = {
						name = "myApp",
						sessionTimeout = CreateTimespan(0, 0, 30, 0),
						sessionManagement = true,
						datasources = {main = {password = "s3cretDbPass", username = "sa"}},
						ormsettings = {dbcreate = "update"},
						customAppKey = "internal-config-value"
					};

					var safe = publicCfc.$safeApplicationMetadata(fakeMeta);

					expect(safe).toHaveKey("name");
					expect(safe).toHaveKey("sessionManagement");
					expect(safe).notToHaveKey("datasources");
					expect(safe).notToHaveKey("ormsettings");
					expect(safe).notToHaveKey("customAppKey");
					expect(SerializeJSON(safe)).notToInclude("s3cretDbPass");
				});

				it("tolerates absent whitelisted keys", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var safe = publicCfc.$safeApplicationMetadata({name = "onlyName"});
					expect(StructCount(safe)).toBe(1);
					expect(safe.name).toBe("onlyName");
				});

			});

			describe("Source coverage", () => {

				it("info.cfm JSON branch serializes the whitelisted metadata, not the raw struct", () => {
					var source = FileRead(ExpandPath("/wheels/public/views/info.cfm"));
					expect(Find("$safeApplicationMetadata", source) > 0).toBeTrue(
						"The JSON branch of info.cfm must reduce getApplicationMetadata() through "
						& "$safeApplicationMetadata() before serialization."
					);
					expect(Find('"metadata": applicationMeta', source)).toBe(
						0,
						"The raw getApplicationMetadata() struct must not be serialized wholesale — it "
						& "carries datasource definitions and arbitrary application config."
					);
				});

				it("core.cfm validates the format param before the layout include", () => {
					var source = FileRead(ExpandPath("/wheels/public/docs/core.cfm"));
					expect(Find("^[A-Za-z0-9]+$", source) > 0).toBeTrue(
						"core.cfm must reject non-alphanumeric format values (with an html fallback) "
						& "before interpolating the value into the layouts/ include path."
					);
				});

			});

		});

	}

}
