/**
 * Regression test for #3114: running the legacy global CORS path
 * (`set(allowCorsRequests=true)`) alongside a `wheels.middleware.Cors`
 * instance stacks duplicate Access-Control-Allow-* headers. A duplicate
 * `Access-Control-Allow-Origin` makes browsers reject the response per the
 * Fetch spec.
 *
 * The fix makes the global `onRequestStart` emitter step aside when a Cors
 * middleware is registered, leaving the dispatch-level middleware as the
 * single source of truth. `$corsMiddlewareActive()` is the arbitration
 * signal the global path consults, and `$runOnRequestStart` is the wiring
 * that consults it — both are covered below. The wiring specs run the real
 * `$runOnRequestStart` on a test double (CorsArbitrationEventDouble) that
 * records `$setCORSHeaders` calls instead of emitting live headers.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Global CORS arbitration with wheels.middleware.Cors (##3114)", () => {

			beforeEach(() => {
				_savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
				_savedAllowCors = application.wheels.allowCorsRequests;
				_savedCacheModelConfig = application.wheels.cacheModelConfig;
				_savedCacheControllerConfig = application.wheels.cacheControllerConfig;
				_savedCacheDatabaseSchema = application.wheels.cacheDatabaseSchema;
				_savedMixins = application.wheels.mixins;
				_hadWarnedFlag = StructKeyExists(application.wheels, "$corsGlobalDeferredWarned");
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
				application.wheels.allowCorsRequests = _savedAllowCors;
				application.wheels.cacheModelConfig = _savedCacheModelConfig;
				application.wheels.cacheControllerConfig = _savedCacheControllerConfig;
				application.wheels.cacheDatabaseSchema = _savedCacheDatabaseSchema;
				application.wheels.mixins = _savedMixins;
				if (!_hadWarnedFlag) {
					StructDelete(application.wheels, "$corsGlobalDeferredWarned");
				}
			});

			it("reports a registered Cors middleware instance as active", () => {
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "https://app.example")
				];
				expect(application.wo.$corsMiddlewareActive()).toBeTrue();
			});

			it("reports a registered Cors middleware string path as active", () => {
				application.wheels.middleware = ["wheels.middleware.Cors"];
				expect(application.wo.$corsMiddlewareActive()).toBeTrue();
			});

			it("reports inactive when no middleware is registered", () => {
				application.wheels.middleware = [];
				expect(application.wo.$corsMiddlewareActive()).toBeFalse();
			});

			it("reports inactive when only non-Cors middleware is registered", () => {
				application.wheels.middleware = ["wheels.middleware.SecurityHeaders"];
				expect(application.wo.$corsMiddlewareActive()).toBeFalse();
			});

			it("onRequestStart skips the global CORS emitter when a Cors middleware is registered", () => {
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "https://app.example")
				];
				application.wheels.allowCorsRequests = true;
				// Keep $runOnRequestStart's cache-busting branches from clearing
				// the live test app's model/controller/schema caches mid-suite.
				application.wheels.cacheModelConfig = true;
				application.wheels.cacheControllerConfig = true;
				application.wheels.cacheDatabaseSchema = true;
				application.wheels.mixins = {};
				StructDelete(application.wheels, "$corsGlobalDeferredWarned");

				var em = CreateObject("component", "wheels.tests._assets.events.CorsArbitrationEventDouble").init();
				em.$runOnRequestStart(targetPage = "/index.cfm");

				expect(em.corsHeaderCalls).toBe(
					0,
					"the global $setCORSHeaders emitter must defer to the registered Cors middleware"
				);
				expect(StructKeyExists(application.wheels, "$corsGlobalDeferredWarned")).toBeTrue(
					"the one-time deferral warning must be recorded when the global path steps aside"
				);
			});

			it("onRequestStart still emits global CORS headers when no Cors middleware is registered", () => {
				application.wheels.middleware = [];
				application.wheels.allowCorsRequests = true;
				application.wheels.cacheModelConfig = true;
				application.wheels.cacheControllerConfig = true;
				application.wheels.cacheDatabaseSchema = true;
				application.wheels.mixins = {};

				var em = CreateObject("component", "wheels.tests._assets.events.CorsArbitrationEventDouble").init();
				em.$runOnRequestStart(targetPage = "/index.cfm");

				expect(em.corsHeaderCalls).toBe(
					1,
					"the legacy global CORS path must keep working when no Cors middleware is registered"
				);
			});

		});

	}

}
