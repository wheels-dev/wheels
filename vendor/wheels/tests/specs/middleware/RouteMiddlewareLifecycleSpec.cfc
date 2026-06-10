/**
 * Regression tests for #2954: route-scoped middleware lifecycle contract.
 *
 * Global middleware is built once at $init via $buildMiddlewarePipeline and
 * the same instances handle every request — that contract is what makes
 * stateful middleware (RateLimiter in-memory store, RequestId per-process
 * counters, etc.) work. Route-scoped string middleware used to violate that
 * contract: $resolveMiddlewareInstance ran `CreateObject(...).init()` on
 * every request, $copyRouteForRequest deep-Duplicated instance middleware
 * sitting on the route table, and $hasPreflightCapableMiddleware re-scanned
 * the pipeline on every OPTIONS request.
 *
 * These tests pin the invariants:
 *   1. $resolveMiddlewareInstance returns the same instance for the same
 *      component path across repeated calls (cache survives across requests).
 *   2. $getRouteMiddleware returns identical instance references when the
 *      same route is matched twice.
 *   3. $copyRouteForRequest preserves instance-form route middleware by
 *      reference instead of Duplicating it.
 *   4. The preflight-capability boolean is computed once at $init, not
 *      re-scanned on every OPTIONS request.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Route-scoped middleware caching", () => {

			beforeEach(() => {
				_savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
				_savedCache = StructKeyExists(application.wheels, "$middlewareInstanceCache")
					? application.wheels.$middlewareInstanceCache : "";
				_savedRoutes = Duplicate(application.wheels.routes);
				_savedCurrentRoute = StructKeyExists(request.wheels, "currentRoute")
					? Duplicate(request.wheels.currentRoute) : "";
				application.wheels.middleware = [];
				// Clear any pre-existing instance cache so each test starts fresh.
				if (StructKeyExists(application.wheels, "$middlewareInstanceCache")) {
					StructDelete(application.wheels, "$middlewareInstanceCache");
				}
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
				application.wheels.routes = _savedRoutes;
				if (IsStruct(_savedCache)) {
					application.wheels.$middlewareInstanceCache = _savedCache;
				} else if (StructKeyExists(application.wheels, "$middlewareInstanceCache")) {
					StructDelete(application.wheels, "$middlewareInstanceCache");
				}
				if (IsStruct(_savedCurrentRoute)) {
					request.wheels.currentRoute = _savedCurrentRoute;
				} else if (StructKeyExists(request.wheels, "currentRoute")) {
					StructDelete(request.wheels, "currentRoute");
				}
			});

			it("returns the same instance for repeated $resolveMiddlewareInstance calls with the same string path", () => {
				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				var path = "wheels.tests._assets.middleware.TestMiddlewareA";
				var first = d.$resolveMiddlewareInstance(middleware = path);
				// Mark the instance via a probe field that survives only if both calls
				// return the same component reference.
				first["$cacheProbe"] = "marked";
				var second = d.$resolveMiddlewareInstance(middleware = path);

				expect(StructKeyExists(second, "$cacheProbe")).toBeTrue();
				expect(second["$cacheProbe"]).toBe("marked");
			});

			it("returns the same instance across repeated $getRouteMiddleware calls on the same route", () => {
				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				request.wheels.currentRoute = {
					middleware = ["wheels.tests._assets.middleware.TestMiddlewareA"]
				};

				var first = d.$getRouteMiddleware(params = {})[1];
				first["$cacheProbe"] = "marked";

				var second = d.$getRouteMiddleware(params = {})[1];

				expect(StructKeyExists(second, "$cacheProbe")).toBeTrue();
				expect(second["$cacheProbe"]).toBe("marked");
			});

			it("preserves instance-form route middleware by reference across $copyRouteForRequest", () => {
				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				var sharedInstance = new wheels.tests._assets.middleware.TestMiddlewareA();
				sharedInstance["$cacheProbe"] = "marked";

				var routeTable = {
					pattern = "/dummy",
					middleware = [sharedInstance],
					controller = "x",
					action = "y"
				};

				var copyA = d.$copyRouteForRequest(route = routeTable);
				var copyB = d.$copyRouteForRequest(route = routeTable);

				// Both copies must point at the original instance — Duplicate() would
				// strip the probe field (and silently reset any stateful middleware).
				expect(StructKeyExists(copyA.middleware[1], "$cacheProbe")).toBeTrue();
				expect(copyA.middleware[1]["$cacheProbe"]).toBe("marked");
				expect(StructKeyExists(copyB.middleware[1], "$cacheProbe")).toBeTrue();
				expect(copyB.middleware[1]["$cacheProbe"]).toBe("marked");
			});

		});

		describe("Preflight-capability caching", () => {

			beforeEach(() => {
				_savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
			});

			it("computes the preflight-capability boolean at $init when CORS is registered", () => {
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "*")
				];

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				expect(d.$hasPreflightCapableMiddleware()).toBeTrue();
			});

			it("computes the preflight-capability boolean at $init when no CORS middleware registered", () => {
				application.wheels.middleware = [];

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				expect(d.$hasPreflightCapableMiddleware()).toBeFalse();
			});

			it("returns the same answer on repeated calls even after the live application.wheels.middleware is mutated", () => {
				// Pin the contract: the pipeline (and the preflight boolean derived
				// from it) is owned by the Dispatch instance from $init onwards.
				// Mutating the application.wheels.middleware list afterwards must
				// not flip the answer — the boolean has to be tied to the snapshot
				// taken at construction, not to a live re-scan.
				application.wheels.middleware = [];

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				var beforeMutation = d.$hasPreflightCapableMiddleware();

				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "*")
				];

				expect(d.$hasPreflightCapableMiddleware()).toBe(beforeMutation);
			});

		});

	}

}
