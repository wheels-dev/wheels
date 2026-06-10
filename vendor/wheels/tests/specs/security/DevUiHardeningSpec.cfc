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
 *    $getRequestFormat() was hardened against (#2900 sibling). The format is
 *    now routed through the unit-testable Public.$resolveDocFormat() helper
 *    (alphanumeric allowlist, html fallback).
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

			describe("$resolveDocFormat()", () => {

				it("accepts plain alphanumeric formats", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$resolveDocFormat("html")).toBe("html");
					expect(publicCfc.$resolveDocFormat("json")).toBe("json");
				});

				it("falls back to html for empty input", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$resolveDocFormat("")).toBe("html");
				});

				it("rejects path traversal payloads and falls back to html", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var traversal = [
						"../views/info",
						"../../etc/passwd",
						"..\..\windows",
						"html/../../config",
						"layouts/html",
						"html.cfm"
					];
					for (var payload in traversal) {
						expect(publicCfc.$resolveDocFormat(payload)).toBe(
							"html",
							"Expected `" & payload & "` to be rejected by $resolveDocFormat() and fall back to html."
						);
					}
				});

				it("rejects payloads with non-alphanumeric characters", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					// Chr(0) is stripped by Lucee somewhere along the parameter-passing
					// chain, so it isn't a useful probe here — the traversal-payload
					// test above already covers slash, dot, and backslash. The remaining
					// payloads exercise other classes of non-alphanumeric chars.
					var bad = ["html json", "html&json", "html;json", "html.cfm", "html-extra"];
					for (var payload in bad) {
						expect(publicCfc.$resolveDocFormat(payload)).toBe(
							"html",
							"Expected `" & payload & "` (non-alphanumeric) to fall back to html."
						);
					}
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
					expect(Find("$resolveDocFormat", source) > 0).toBeTrue(
						"core.cfm must route the `format` request parameter through $resolveDocFormat() "
						& "before interpolating it into the layouts/<format>.cfm include path."
					);
					expect(Find('include "layouts/##request.wheels.params.format##.cfm"', source)).toBe(
						0,
						"core.cfm must not interpolate the unvalidated `format` request parameter into "
						& "the include path — same LFI traversal class $getRequestFormat was hardened against."
					);
				});

			});

		});

	}

}
