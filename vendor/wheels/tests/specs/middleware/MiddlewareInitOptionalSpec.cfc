/**
 * A middleware registered by component path (a string in set(middleware=[...])
 * or a route's middleware list) only has to implement handle():
 * wheels.middleware.MiddlewareInterface declares nothing else. Dispatch used to
 * call `.init()` on every string-registered component, so one without an init()
 * failed every request with "has no function with name [init]".
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("String-registered middleware and init()", () => {

			beforeEach(() => {
				// Same save/restore as RouteMiddlewareLifecycleSpec: shallow-copy the
				// middleware array (Duplicate() deep-clones CFCs on Adobe CF) and
				// start each test with an empty instance cache.
				_savedMiddleware = (StructKeyExists(application.wheels, "middleware") && ArrayLen(application.wheels.middleware))
					? ArraySlice(application.wheels.middleware, 1) : [];
				_savedCache = StructKeyExists(application.wheels, "$middlewareInstanceCache")
					? application.wheels.$middlewareInstanceCache : "";
				if (StructKeyExists(application.wheels, "$middlewareInstanceCache")) {
					StructDelete(application.wheels, "$middlewareInstanceCache");
				}
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
				if (IsStruct(_savedCache)) {
					application.wheels.$middlewareInstanceCache = _savedCache;
				} else if (StructKeyExists(application.wheels, "$middlewareInstanceCache")) {
					StructDelete(application.wheels, "$middlewareInstanceCache");
				}
			});

			it("loads a component that has handle() and no init()", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.NoInitMiddleware");
				expect(IsObject(instance)).toBeTrue();
				expect(StructKeyExists(instance, "handle")).toBeTrue();
			});

			it("caches the init-less instance like any other", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var path = "wheels.tests._assets.middleware.NoInitMiddleware";
				var first = d.$resolveMiddlewareInstance(middleware = path);
				first["$cacheProbe"] = "marked";
				var second = d.$resolveMiddlewareInstance(middleware = path);
				expect(StructKeyExists(second, "$cacheProbe")).toBeTrue();
			});

			it("still calls init() when the component has one", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.InitFlagMiddleware");
				expect(instance.wasInitialized()).toBeTrue();
			});

			it("calls an init() the component inherits", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.InheritedInitMiddleware");
				expect(instance.wasInitialized()).toBeTrue();
			});

			it("caches the component itself when init() returns nothing", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.VoidInitMiddleware");
				expect(IsObject(instance)).toBeTrue();
				expect(instance.wasInitialized()).toBeTrue();
			});

			it("caches the component itself when init() returns a non-object", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.ScalarInitMiddleware");
				expect(IsObject(instance)).toBeTrue();
				expect(instance.wasInitialized()).toBeTrue();
			});

			it("caches what init() returns when it returns another object, as before", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.ReplacingInitMiddleware");
				expect(ListLast(GetMetaData(instance).name, ".")).toBe("NoInitMiddleware");
			});

			it("runs an init-less component through the pipeline", () => {
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var instance = d.$resolveMiddlewareInstance(middleware = "wheels.tests._assets.middleware.NoInitMiddleware");
				var pipeline = new wheels.middleware.Pipeline(middleware = [instance]);
				var seen = {value = ""};
				var core = function(required struct request) {
					seen.value = arguments.request.noInit ?: "";
					return "core";
				};
				expect(pipeline.run(request = {}, coreHandler = core)).toBe("core");
				expect(seen.value).toBe("handled");
			});

		});

	}

}
