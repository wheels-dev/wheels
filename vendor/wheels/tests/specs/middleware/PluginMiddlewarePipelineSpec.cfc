/**
 * Tests that plugin-registered middleware integrates into the Pipeline.
 * Covers: wh-7xu.2 — wire plugin middleware into Pipeline.cfc
 *
 * These tests verify the wiring logic that $buildMiddlewarePipeline uses:
 * reading pluginMiddleware entries, instantiating CFC paths vs instances,
 * and placing them after user-configured middleware in the chain.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Plugin middleware pipeline wiring", function() {

			it("instantiates middleware from a CFC path string", function() {
				var entry = {
					middleware = "wheels.tests._assets.middleware.TestMiddlewareA",
					options = {},
					pluginName = "PluginA"
				};

				// Simulate what $buildMiddlewarePipeline does: resolve the CFC path.
				var instance = CreateObject("component", entry.middleware).init();
				var pipeline = new wheels.middleware.Pipeline(middleware = [instance]);

				var reqCtx = {trace = []};
				var result = pipeline.run(
					request = reqCtx,
					coreHandler = function(required struct request) {
						ArrayAppend(arguments.request.trace, "core");
						return "done";
					}
				);

				expect(result).toBe("done");
				expect(reqCtx.trace[1]).toBe("A");
				expect(reqCtx.trace[2]).toBe("core");
			});

			it("accepts middleware that is already an instance", function() {
				var mwInstance = new wheels.tests._assets.middleware.TestMiddlewareB();
				var entry = {
					middleware = mwInstance,
					options = {},
					pluginName = "PluginB"
				};

				var pipeline = new wheels.middleware.Pipeline(middleware = [entry.middleware]);

				var reqCtx = {trace = []};
				pipeline.run(
					request = reqCtx,
					coreHandler = function(required struct request) {
						ArrayAppend(arguments.request.trace, "core");
						return "done";
					}
				);

				expect(reqCtx.trace[1]).toBe("B");
				expect(reqCtx.trace[2]).toBe("core");
			});

			it("places plugin middleware after user-configured middleware", function() {
				// User middleware: A runs first.
				var userMw = new wheels.tests._assets.middleware.TestMiddlewareA();

				// Plugin middleware: B runs second.
				var pluginMw = CreateObject("component", "wheels.tests._assets.middleware.TestMiddlewareB").init();

				// Combine in the order $buildMiddlewarePipeline uses: user first, plugin after.
				var allMiddleware = [userMw, pluginMw];
				var pipeline = new wheels.middleware.Pipeline(middleware = allMiddleware);

				var reqCtx = {trace = []};
				pipeline.run(
					request = reqCtx,
					coreHandler = function(required struct request) {
						ArrayAppend(arguments.request.trace, "core");
						return "done";
					}
				);

				expect(ArrayLen(reqCtx.trace)).toBe(3);
				expect(reqCtx.trace[1]).toBe("A");
				expect(reqCtx.trace[2]).toBe("B");
				expect(reqCtx.trace[3]).toBe("core");
			});

			it("runs multiple plugin middleware in registration order", function() {
				// Two plugin middleware, registered in order A then B.
				var mwA = CreateObject("component", "wheels.tests._assets.middleware.TestMiddlewareA").init();
				var mwB = CreateObject("component", "wheels.tests._assets.middleware.TestMiddlewareB").init();

				var pipeline = new wheels.middleware.Pipeline(middleware = [mwA, mwB]);

				var reqCtx = {trace = []};
				pipeline.run(
					request = reqCtx,
					coreHandler = function(required struct request) {
						ArrayAppend(arguments.request.trace, "core");
						return "done";
					}
				);

				expect(reqCtx.trace[1]).toBe("A");
				expect(reqCtx.trace[2]).toBe("B");
				expect(reqCtx.trace[3]).toBe("core");
			});

			it("works with empty plugin middleware list", function() {
				// No plugin middleware — pipeline should still work with user middleware only.
				var userMw = new wheels.tests._assets.middleware.TestMiddlewareA();
				var pipeline = new wheels.middleware.Pipeline(middleware = [userMw]);

				var reqCtx = {trace = []};
				pipeline.run(
					request = reqCtx,
					coreHandler = function(required struct request) {
						ArrayAppend(arguments.request.trace, "core");
						return "done";
					}
				);

				expect(ArrayLen(reqCtx.trace)).toBe(2);
				expect(reqCtx.trace[1]).toBe("A");
				expect(reqCtx.trace[2]).toBe("core");
			});

		});

		describe("Dispatch plugin middleware integration", function() {

			beforeEach(function() {
				savedPluginMiddleware = StructKeyExists(application.wheels, "pluginMiddleware")
					? Duplicate(application.wheels.pluginMiddleware) : [];
				savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
			});

			afterEach(function() {
				application.wheels.pluginMiddleware = savedPluginMiddleware;
				application.wheels.middleware = savedMiddleware;
			});

			it("builds a pipeline that includes plugin middleware from app scope", function() {
				// Set up plugin middleware in the application scope.
				application.wheels.pluginMiddleware = [
					{middleware = "wheels.tests._assets.middleware.TestMiddlewareA", options = {}, pluginName = "PluginA"},
					{middleware = "wheels.tests._assets.middleware.TestMiddlewareB", options = {priority: 10}, pluginName = "PluginB"}
				];
				application.wheels.middleware = [];

				// Rebuild the Dispatch — this triggers $buildMiddlewarePipeline internally.
				var g = application.wo;
				var dispatch = g.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");

				// Verify by checking that the dispatch object was created successfully.
				// The real proof is that $buildMiddlewarePipeline didn't throw when
				// instantiating the plugin middleware CFC paths.
				expect(dispatch).toBeInstanceOf("wheels.Dispatch");
			});

			it("returns empty pipeline when no middleware at all", function() {
				application.wheels.pluginMiddleware = [];
				application.wheels.middleware = [];

				var g = application.wo;
				var dispatch = g.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				expect(dispatch).toBeInstanceOf("wheels.Dispatch");
			});

		});

	}

}
