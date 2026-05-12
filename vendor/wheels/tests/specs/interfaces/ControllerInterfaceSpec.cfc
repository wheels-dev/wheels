component extends="wheels.WheelsTest" {

	function run() {

		describe("Controller Interface Contracts", () => {

			beforeEach(() => {
				// Create a controller instance to test mixin methods
				ctrl = controller("wheels");
			});

			describe("ControllerFilterInterface", () => {

				it("exposes all required filter methods", () => {
					var methods = ["filters", "filterChain", "setFilterChain"];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("Controller missing: #m#()");
					}
				});

				it("filters has correct parameter names", () => {
					var expected = ["through", "type", "only", "except", "placement"];
					assertParamsPresent(ctrl, "filters", expected);
				});

			});

			describe("ControllerRenderingInterface", () => {

				it("exposes all required rendering methods", () => {
					var methods = [
						"renderView", "renderPartial", "renderText", "renderNothing",
						"renderWith", "redirectTo", "response", "setResponse"
					];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("Controller missing: #m#()");
					}
				});

				it("redirectTo has all 17 parameter names including back, method, and url", () => {
					var expected = [
						"back", "controller", "action", "route", "method", "key",
						"params", "anchor", "onlyPath", "host", "protocol", "port",
						"statusCode", "addToken", "url", "delay", "encode"
					];
					assertParamsPresent(ctrl, "redirectTo", expected);
				});

			});

			describe("ControllerFlashInterface", () => {

				it("exposes all required flash methods", () => {
					var methods = [
						"flash", "flashInsert", "flashClear", "flashCount",
						"flashDelete", "flashIsEmpty", "flashKeep", "flashKeyExists"
					];
					for (var m in methods) {
						expect(structKeyExists(ctrl, m)).toBeTrue("Controller missing: #m#()");
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
