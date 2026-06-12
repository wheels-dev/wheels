/**
 * Regression spec for the legacy CommandBox-module generator (`cli/src/`).
 *
 * The legacy model template (`cli/src/templates/ModelContent.txt`) carries a
 * `{{enums}}` placeholder, but `cli/src/models/TemplateService.cfc::processTemplate`
 * historically substituted only `{{belongsToRelationships}}`, `{{hasManyRelationships}}`,
 * `{{hasOneRelationships}}`, and `{{validations}}` — there was no `{{enums}}` branch, so
 * the literal placeholder leaked into the generated `config()` body as invalid CFML.
 *
 * The legacy path has no enum codegen, so the safe fix is to STRIP the placeholder
 * (matching the no-validations fallback). This spec pins that behavior.
 *
 * See https://github.com/wheels-dev/wheels/issues/3180.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("Legacy TemplateService — {{enums}} placeholder", () => {

			it("strips the {{enums}} placeholder so it never leaks into generated CFML", () => {
				// Instantiate the legacy generator directly (resolves from the test webroot).
				var svc = new cli.src.models.TemplateService();
				makePublic(svc, "processTemplate");

				// Mirror the model template body that ships with the legacy module.
				var template = 'component extends="Model" {' & chr(10) &
					chr(9) & "function config() {" & chr(10) &
					chr(9) & chr(9) & "{{belongsToRelationships}}" & chr(10) &
					chr(9) & chr(9) & "{{hasManyRelationships}}" & chr(10) &
					chr(9) & chr(9) & "{{hasOneRelationships}}" & chr(10) &
					chr(9) & chr(9) & "{{validations}}" & chr(10) &
					chr(9) & chr(9) & "{{enums}}" & chr(10) &
					chr(9) & "}" & chr(10) &
					"}";

				var result = svc.processTemplate(template, {});

				// The placeholder must be gone — a leaked {{enums}} is invalid CFML.
				expect(result).notToInclude("{{enums}}");
				// Sanity: the sibling placeholders are still being handled (already stripped).
				expect(result).notToInclude("{{validations}}");
				expect(result).notToInclude("{{belongsToRelationships}}");
			});

		});

	}

}
