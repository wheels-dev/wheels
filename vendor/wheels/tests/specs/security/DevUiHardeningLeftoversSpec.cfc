/**
 * Dev-UI hardening leftovers (issue #2974, deferrals from #2909 / #2900).
 *
 * Two dev-UI surfaces still bypass the hardening shipped in those PRs:
 *
 * 1. `vendor/wheels/public/views/info.cfm` JSON branch dumps the full
 *    `getApplicationMetadata()` struct — datasources (with credentials) and
 *    application config flow through unredacted, bypassing the per-setting
 *    redaction the surrounding loops already use.
 * 2. `vendor/wheels/public/docs/core.cfm` interpolates the unvalidated
 *    `format` request parameter directly into `include "layouts/<format>.cfm"`
 *    — the same LFI traversal class `$getRequestFormat` was hardened against.
 *
 * Both surfaces are dev-environment-gated, so this is defense-in-depth, but
 * the propose-fix follow-ups promised in those PRs were never filed.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Dev-UI hardening leftovers (##2974)", () => {

			describe("$resolveDocFormat() — validates docs layout format parameter", () => {

				it("accepts plain alphanumeric formats", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$resolveDocFormat("html")).toBe("html");
					expect(publicCfc.$resolveDocFormat("json")).toBe("json");
				});

				it("falls back to html for empty or missing format", () => {
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

			describe("core.cfm docs viewer wires format through $resolveDocFormat()", () => {

				it("core.cfm no longer interpolates the raw format request parameter into the include path", () => {
					var source = FileRead(ExpandPath("/wheels/public/docs/core.cfm"));
					expect(Find('include "layouts/##request.wheels.params.format##.cfm"', source)).toBe(
						0,
						"core.cfm must not interpolate the unvalidated `format` request parameter into "
						& "the include path — same LFI traversal class $getRequestFormat was hardened against."
					);
				});

				it("core.cfm validates format before including the layout", () => {
					var source = FileRead(ExpandPath("/wheels/public/docs/core.cfm"));
					expect(Find("$resolveDocFormat", source) > 0).toBeTrue(
						"core.cfm must route the `format` request parameter through $resolveDocFormat() "
						& "before interpolating it into the layouts/<format>.cfm include path."
					);
				});

			});

			describe("/wheels/info JSON branch — applicationMeta whitelist", () => {

				it("info.cfm does not serialize the full getApplicationMetadata() into the JSON response", () => {
					var source = FileRead(ExpandPath("/wheels/public/views/info.cfm"));
					expect(ReFindNoCase('"metadata"\s*[=:]\s*applicationMeta\b', source)).toBe(
						0,
						"The JSON branch must not dump the whole applicationMeta struct — datasources "
						& "(with credentials) and application config flow through unredacted. Whitelist "
						& "safe keys (e.g. mappings) instead, mirroring the HTML branch."
					);
				});

				it("info.cfm exposes applicationMeta.mappings explicitly in the JSON branch", () => {
					var source = FileRead(ExpandPath("/wheels/public/views/info.cfm"));
					// HTML branch already references applicationMeta.mappings once
					// (the Mappings table). After the JSON branch is whitelisted, a
					// second reference appears — assert two-or-more occurrences so
					// the JSON branch must explicitly opt into mappings (instead of
					// dumping the whole struct).
					var occurrences = ArrayLen(ReMatch("applicationMeta\.mappings", source));
					expect(occurrences >= 2).toBeTrue(
						"The JSON branch should expose applicationMeta.mappings explicitly (mirroring the "
						& "HTML branch's Mappings table) instead of dumping the full struct. Found "
						& occurrences & " reference(s) — expected at least 2 (one for each branch)."
					);
				});

			});

		});

	}

}
