/**
 * Verifies the `wheels new` project template is complete enough that a
 * scaffolded app can boot without hitting missing-file errors in the
 * framework's bootstrap path.
 *
 * Regression guard: an earlier template omitted these stub files, which
 * caused onApplicationStart to throw mid-bootstrap. The exception cascaded
 * into onError, which then failed on a missing application.wo — surfacing
 * the misleading "key [WO] doesn't exist" rather than the real root cause
 * (the hard include in vendor/wheels/Global.cfc:3404 of
 * /app/global/functions.cfm).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.templateRoot = expandPath("/cli/lucli/templates/app/");
	}

	function run() {

		describe("wheels new template completeness", () => {

			it("ships app/global/functions.cfm (hard-included by Global.cfc)", () => {
				expect(fileExists(templateRoot & "app/global/functions.cfm")).toBeTrue();
			});

			it("ships app/views/helpers.cfm (used by layout rendering)", () => {
				expect(fileExists(templateRoot & "app/views/helpers.cfm")).toBeTrue();
			});

			it("ships every app/events/*.cfm handler hard-included at boot", () => {
				// The framework's events/onapplicationstart.cfc unconditionally
				// includes each of these at boot (via EventMethods.cfc for
				// request/session events). Missing any one crashes
				// onApplicationStart.
				var requiredEvents = [
					"onapplicationstart", "onapplicationend",
					"onrequeststart",     "onrequestend",
					"onsessionstart",     "onsessionend",
					"onerror",            "onerror.json",     "onerror.xml",
					"onmissingtemplate",  "onmaintenance",    "onabort"
				];
				var missing = [];
				for (var evt in requiredEvents) {
					if (!fileExists(templateRoot & "app/events/" & evt & ".cfm")) {
						arrayAppend(missing, evt & ".cfm");
					}
				}
				expect(arrayToList(missing)).toBe("");
			});

		});

	}

}
