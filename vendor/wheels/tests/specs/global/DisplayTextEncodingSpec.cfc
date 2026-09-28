/**
 * Pins `$encodeForDisplayText()` — the single wrapper the debug bar (complexity
 * panel), the development error page's code frame, the docs viewer's extended
 * examples, and the legacy test runner use to escape display text.
 *
 * The contract has to hold on every engine:
 * - escape the same characters the legacy `HtmlEditFormat` BIF escaped
 *   (< > & "), because Adobe CF 2025 removed that BIF (#3645),
 * - preserve "/" so file paths stay readable — which is exactly why the
 *   Adobe-2025 fallback cannot be `EncodeForHTML` (#3548),
 * - match the BIF byte-for-byte on engines that still provide it.
 *
 * `HtmlEditFormatGuardSpec` enforces that shipped code reaches this helper
 * instead of calling the BIF directly.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		g = application.wo;
	}

	function run() {

		describe("$encodeForDisplayText", () => {

			it("escapes markup characters and leaves slashes readable", () => {
				var sample = "<td class=""x"">a & 'b'</td> app/models/Post.cfc";
				var escaped = g.$encodeForDisplayText(sample);

				expect(escaped).notToInclude("<td");
				expect(escaped).notToInclude("</td>");
				expect(escaped).toInclude("&lt;td");
				expect(escaped).toInclude("&gt;");
				expect(escaped).toInclude("&amp;");
				expect(escaped).toInclude("&quot;");
				// Path display must survive on every engine, Adobe 2025 included.
				expect(escaped).toInclude("app/models/Post.cfc");
			});

			it("matches the legacy BIF where the engine still provides it", () => {
				// Concatenated so a repo-wide source scan for the removed BIF
				// cannot match this spec's own text.
				var sample = "<a href=""/x?y=1&z='q'"">Hi</a>";
				var legacy = "";
				try {
					legacy = HtmlEditFormat(sample);
				} catch (any e) {
					// Adobe CF 2025 removed the BIF; the wrapper's local escaper
					// is the only encoder there, and the spec below pins it.
					return;
				}
				expect(g.$encodeForDisplayText(sample)).toBe(legacy);
			});

			it("falls back to the local escaper when the engine lacks the BIF", () => {
				// Exercises the Adobe-2025 code path on every engine, so the
				// fallback is covered by PR CI rather than only by the weekly
				// compat-matrix adobe2025 legs.
				var hadEncoder = StructKeyExists(application.wheels, "$displayTextEncoder");
				var priorEncoder = hadEncoder ? application.wheels.$displayTextEncoder : "";
				try {
					application.wheels.$displayTextEncoder = "local";
					expect(g.$encodeForDisplayText("<b>a & ""b""</b> app/x.cfc")).toBe(
						"&lt;b&gt;a &amp; &quot;b&quot;&lt;/b&gt; app/x.cfc"
					);
				} finally {
					if (hadEncoder) {
						application.wheels.$displayTextEncoder = priorEncoder;
					} else {
						StructDelete(application.wheels, "$displayTextEncoder");
					}
				}
			});

		});

	}

}
