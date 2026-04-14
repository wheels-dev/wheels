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

				it("interface bindings are registered in wheels.Bindings", () => {
					// Create a fresh Injector with the default Bindings to verify
					// all interface bindings are present (avoids relying on
					// application.wheelsdi which may be reset during test lifecycle).
					var di = new wheels.Injector(binderPath="wheels.Bindings");
					var bindings = [
						"ModelFinderInterface",
						"ModelPersistenceInterface",
						"ModelValidationInterface",
						"ModelErrorInterface",
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

				it("all interface bindings resolve to real components", () => {
					// This test catches broken bindings (e.g., pointing to non-existent CFCs)
					// by actually instantiating each bound component, not just checking the mapping.
					var di = new wheels.Injector(binderPath="wheels.Bindings");
					var bindings = [
						"ModelFinderInterface",
						"ModelPersistenceInterface",
						"ModelValidationInterface",
						"ModelErrorInterface",
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
						if (di.containsInstance(name)) {
							expect(function() {
								di.getInstance(name);
							}).notToThrow("getInstance('#name#') should resolve without error");
						}
					}
				});

			});

		});

	}

}
