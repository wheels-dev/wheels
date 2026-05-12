component extends="wheels.WheelsTest" {

	function beforeAll() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};
	}

	function run() {

		describe("Routing Interface Contracts", () => {

			describe("RouteMapperInterface", () => {

				beforeEach(() => {
					// Create a fresh mapper instance — methods are mixed in via $integrateComponents
					mapper = $createMapper();
				});

				it("exposes resource definition methods", () => {
					var methods = ["resources", "resource", "member", "collection"];
					for (var m in methods) {
						expect(structKeyExists(mapper, m)).toBeTrue("Mapper missing: #m#()");
					}
				});

				it("exposes HTTP method matching methods", () => {
					var methods = ["get", "post", "put", "patch", "delete", "root", "wildcard", "health"];
					for (var m in methods) {
						expect(structKeyExists(mapper, m)).toBeTrue("Mapper missing: #m#()");
					}
				});

				it("exposes route constraint methods", () => {
					var methods = [
						"whereNumber", "whereAlpha", "whereAlphaNumeric",
						"whereUuid", "whereSlug", "whereIn", "whereMatch"
					];
					for (var m in methods) {
						expect(structKeyExists(mapper, m)).toBeTrue("Mapper missing: #m#()");
					}
				});

				it("exposes scoping methods", () => {
					var methods = [
						"scope", "namespace", "package", "controller",
						"constraints", "group", "api", "version"
					];
					for (var m in methods) {
						expect(structKeyExists(mapper, m)).toBeTrue("Mapper missing: #m#()");
					}
				});

				it("exposes lifecycle methods", () => {
					expect(structKeyExists(mapper, "end")).toBeTrue("Mapper missing: end()");
				});

				it("resources has correct parameter names", () => {
					var expected = [
						"name", "nested", "path", "controller", "singular",
						"plural", "only", "except", "shallow", "shallowPath",
						"shallowName", "constraints", "callback", "binding"
					];
					assertParamsPresent(mapper, "resources", expected);
				});

			});

			describe("RouteResolverInterface", () => {

				it("exposes route retrieval methods", () => {
					var m = $createMapper();
					expect(structKeyExists(m, "getRoutes")).toBeTrue("Mapper missing resolver method: getRoutes()");
				});

			});

		});

	}

	private struct function $createMapper() {
		local.args = Duplicate(config);
		StructAppend(local.args, arguments, true);
		return application.wo.$createObjectFromRoot(argumentCollection = local.args);
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
