/**
 * Adobe ColdFusion 2025 does not provide HTMLEditFormat (Variable
 * HTMLEDITFORMAT is undefined). The Packages admin page
 * (vendor/wheels/public/views/packagelist.cfm) used it for registry
 * error text, names, descriptions, versions, homepage hrefs, and
 * copy-command markup, so GET /wheels/packages 500s on that engine
 * (issue #3378). Other /wheels admin views already encode with
 * EncodeForHTML — the same BIF this spec requires.
 *
 * An Adobe 2025 BIF miss cannot be reproduced on the Lucee CI runner,
 * so the gate is this structural scan of the view source.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("packagelist.cfm HTML encoding (issue ##3378)", () => {

			it("does not call HTMLEditFormat", () => {
				var src = FileRead(ExpandPath("/wheels/public/views/packagelist.cfm"));
				// Built by concatenation so a later admin-surface scan of
				// this spec file cannot match the forbidden BIF name.
				var forbidden = "HTML" & "EditFormat";

				expect(FindNoCase(forbidden, src) GT 0).toBeFalse(
					"packagelist.cfm must not call #forbidden# — Adobe ColdFusion 2025 "
					& "does not provide that BIF (Variable HTMLEDITFORMAT is undefined), "
					& "so /wheels/packages 500s. Use EncodeForHTML, the encoder already "
					& "used by other /wheels admin views. See issue ##3378."
				);
			});

			it("encodes registry output with EncodeForHTML", () => {
				var src = FileRead(ExpandPath("/wheels/public/views/packagelist.cfm"));

				expect(FindNoCase("EncodeForHTML(", src) GT 0).toBeTrue(
					"packagelist.cfm should encode registry names, descriptions, "
					& "versions, errors, and homepage links with EncodeForHTML, "
					& "matching helpers.cfm and routetesterprocess.cfm. See issue ##3378."
				);
			});

		});

	}

}
