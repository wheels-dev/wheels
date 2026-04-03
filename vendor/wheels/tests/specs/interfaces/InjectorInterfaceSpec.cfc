component extends="wheels.WheelsTest" {

	function run() {

		describe("Injector Interface Contracts", () => {

			describe("InjectorInterface", () => {

				beforeEach(() => {
					di = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
				});

				it("exposes all required DI methods", () => {
					var methods = [
						"init", "map", "mapInstance", "to", "bind",
						"getInstance", "containsInstance", "asSingleton",
						"asRequestScoped", "getMappings", "isSingleton",
						"isRequestScoped"
					];
					for (var m in methods) {
						expect(structKeyExists(di, m)).toBeTrue("Injector missing: #m#()");
					}
				});

				it("getInstance has correct parameter names", () => {
					var meta = getMetaData(di.getInstance);
					var paramNames = [];
					for (var p in meta.parameters) {
						arrayAppend(paramNames, p.name);
					}
					expect(arrayFindNoCase(paramNames, "name") > 0).toBeTrue("Missing: name");
					expect(arrayFindNoCase(paramNames, "initArguments") > 0).toBeTrue("Missing: initArguments");
				});

			});

			describe("DI Binding Resolution", () => {

				it("interface bindings are registered in default configuration", () => {
					var di = application.wheelsdi;
					var bindings = [
						"ModelFinderInterface",
						"ModelPersistenceInterface",
						"ModelValidationInterface",
						"ModelCallbackInterface",
						"ModelAssociationInterface",
						"ModelPropertyInterface",
						"ControllerFilterInterface",
						"ControllerRenderingInterface",
						"ControllerFlashInterface",
						"ViewFormInterface",
						"ViewLinkInterface",
						"ViewContentInterface",
						"RouteMapperInterface",
						"RouteResolverInterface",
						"EventHandlerInterface",
						"InjectorInterface"
					];
					for (var name in bindings) {
						expect(di.containsInstance(name)).toBeTrue(
							"Missing DI binding: #name#"
						);
					}
				});

			});

		});

	}

}
