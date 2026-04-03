component extends="wheels.WheelsTest" {

	function run() {

		describe("View Interface Contracts", () => {

			beforeEach(() => {
				// Controller instances have view helpers mixed in
				ctrl = controller("wheels");
			});

			describe("ViewFormInterface", () => {

				it("exposes core form helpers", () => {
					var methods = [
						"startFormTag", "endFormTag", "textField", "textFieldTag",
						"passwordField", "hiddenField", "textArea", "select",
						"checkBox", "radioButton", "submitTag", "buttonTag"
					];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("View missing: #m#()");
					}
				});

				it("exposes HTML5 form helpers", () => {
					var methods = [
						"emailField", "emailFieldTag", "urlField", "urlFieldTag",
						"numberField", "numberFieldTag", "telField", "dateField",
						"colorField", "rangeField", "searchField"
					];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("View missing HTML5 helper: #m#()");
					}
				});

			});

			describe("ViewLinkInterface", () => {

				it("exposes all required link helpers", () => {
					var methods = ["linkTo", "buttonTo", "mailTo", "paginationLinks", "urlFor"];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("View missing: #m#()");
					}
				});

				it("linkTo has correct parameter names", () => {
					var expected = [
						"text", "route", "controller", "action", "key",
						"params", "anchor", "onlyPath", "host", "protocol",
						"port", "href", "encode"
					];
					assertParamsPresent(ctrl, "linkTo", expected);
				});

			});

			describe("ViewContentInterface", () => {

				it("exposes all required content helpers", () => {
					var methods = [
						"contentFor", "contentForLayout", "includeContent",
						"includePartial", "includeLayout", "cycle", "resetCycle"
					];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("View missing: #m#()");
					}
				});

			});

		});

	}

	private void function assertParamsPresent(required any obj, required string methodName, required array expectedParams) {
		var fn = arguments.obj[arguments.methodName];
		var meta = getMetaData(fn);
		var actualParams = [];
		if (structKeyExists(meta, "parameters")) {
			for (var p in meta.parameters) {
				arrayAppend(actualParams, p.name);
			}
		}
		for (var expected in arguments.expectedParams) {
			expect(arrayFindNoCase(actualParams, expected) > 0).toBeTrue(
				"#arguments.methodName#() missing parameter: #expected# (has: #arrayToList(actualParams)#)"
			);
		}
	}

}
