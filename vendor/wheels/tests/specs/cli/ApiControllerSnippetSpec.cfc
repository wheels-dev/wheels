/**
 * Regression: app/snippets/ApiControllerContent.txt is consumed by the CLI
 * Templates service (cli/lucli/services/Templates.cfc) when `wheels generate
 * api-resource` is run. The processor only replaces pipe-delimited tokens
 * (e.g. |ObjectNameSingular|, |ObjectNamePlural|); the legacy ##objectName##
 * style is NOT substituted and lands verbatim in generated controllers.
 *
 * Issue #2468: the framework snippet still uses the legacy ##objectName##
 * tokens, so generated API controllers contain unresolved placeholders.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("app/snippets/ApiControllerContent.txt", function() {

			it("uses pipe-delimited tokens the CLI Templates processor understands", function() {
				var path = expandPath("/app/snippets/ApiControllerContent.txt");
				expect(fileExists(path)).toBeTrue("Snippet missing at " & path);

				var content = fileRead(path);

				// Hash literals must be doubled in CFML strings — these strings
				// represent the legacy, unresolved token forms.
				var legacyPlural = "##" & "objectNamePlural" & "##";
				var legacySingular = "##" & "objectNameSingular" & "##";

				expect(content contains legacyPlural).toBeFalse(
					"Snippet still contains legacy token " & legacyPlural
					& " — CLI Templates.processTemplate() doesn't substitute this form."
				);
				expect(content contains legacySingular).toBeFalse(
					"Snippet still contains legacy token " & legacySingular
					& " — CLI Templates.processTemplate() doesn't substitute this form."
				);

				expect(content contains "|ObjectNamePlural|").toBeTrue(
					"Snippet should use |ObjectNamePlural| — the token Templates.processTemplate() replaces."
				);
				expect(content contains "|ObjectNameSingular|").toBeTrue(
					"Snippet should use |ObjectNameSingular| — the token Templates.processTemplate() replaces."
				);
			});

		});

	}

}
