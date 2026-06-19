component extends="wheels.WheelsTest" {

	function run() {

		// Shared struct so nested closures can read `g` and the sentinel keys
		// on Adobe CF 2023/2025 (cross-engine invariant ##3).
		var ctx = {
			g: application.wo,
			modelKey: "FastPathSentinelModel",
			controllerKey: "FastPathSentinelController"
		};

		describe("Lock-free warm fast path for model() and controller() (issue ##2897)", () => {

			beforeEach(() => {
				StructDelete(application.wheels.models, ctx.modelKey, false);
				StructDelete(application.wheels.controllers, ctx.controllerKey, false);
			});

			afterEach(() => {
				StructDelete(application.wheels.models, ctx.modelKey, false);
				StructDelete(application.wheels.controllers, ctx.controllerKey, false);
			});

			it("$cachedModelLookup returns the cached struct when present", () => {
				application.wheels.models[ctx.modelKey] = {marker: "model-sentinel"};
				var actual = ctx.g.$cachedModelLookup(name = ctx.modelKey);
				expect(actual).toBeStruct();
				expect(actual.marker).toBe("model-sentinel");
			});

			it("$cachedModelLookup returns false when the key is absent", () => {
				expect(ctx.g.$cachedModelLookup(name = "NonExistentModelXYZ")).toBe(false);
			});

			it("$cachedControllerLookup returns the cached struct when present", () => {
				application.wheels.controllers[ctx.controllerKey] = {marker: "controller-sentinel"};
				var actual = ctx.g.$cachedControllerLookup(name = ctx.controllerKey);
				expect(actual).toBeStruct();
				expect(actual.marker).toBe("controller-sentinel");
			});

			it("$cachedControllerLookup returns false when the key is absent", () => {
				expect(ctx.g.$cachedControllerLookup(name = "NonExistentControllerXYZ")).toBe(false);
			});

			it("model() returns the cached struct via the warm fast path", () => {
				application.wheels.models[ctx.modelKey] = {marker: "model-sentinel"};
				var actual = ctx.g.model(ctx.modelKey);
				expect(actual).toBeStruct();
				expect(actual.marker).toBe("model-sentinel");
			});

			it("controller() returns the cached class via the warm fast path when params is empty", () => {
				application.wheels.controllers[ctx.controllerKey] = {marker: "controller-sentinel"};
				var actual = ctx.g.controller(name = ctx.controllerKey);
				expect(actual).toBeStruct();
				expect(actual.marker).toBe("controller-sentinel");
			});

			it("controller() preserves the params branch — cached class still receives $createControllerObject(params)", () => {
				// Cache a stub "class" whose $createControllerObject reports the
				// params it received. The fast path must return the cached class
				// only when params is empty; with params, it must dispatch to
				// $createControllerObject — never substitute the class for an
				// instance.
				var capturedParams = {captured: ""};
				application.wheels.controllers[ctx.controllerKey] = {
					$createControllerObject: function(required struct params) {
						capturedParams.captured = arguments.params;
						return {marker: "controller-instance", params: arguments.params};
					}
				};
				var actual = ctx.g.controller(name = ctx.controllerKey, params = {key: "v"});
				expect(actual).toBeStruct();
				expect(actual.marker).toBe("controller-instance");
				expect(actual.params.key).toBe("v");
				expect(capturedParams.captured.key).toBe("v");
			});

		});
	}
}
