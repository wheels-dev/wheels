/**
 * Regression test for #2703: wheels.middleware.Cors cannot short-circuit
 * OPTIONS preflight because middleware runs AFTER route dispatch.
 *
 * The legacy `set(allowCorsRequests=true)` path aborted OPTIONS in
 * EventMethods.cfc BEFORE route matching. The new middleware pipeline must
 * preserve that behavior for cross-origin POST/PUT/PATCH/DELETE preflight
 * to function — browsers block the actual request when preflight 404s.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CORS preflight short-circuit in dispatch", () => {

			beforeEach(() => {
				_savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
				_savedRoutes = Duplicate(application.wheels.routes);
				_savedStaticRoutes = StructKeyExists(application.wheels, "staticRoutes")
					? StructCopy(application.wheels.staticRoutes) : {};
				_savedCgiMethod = request.cgi.request_method;
				application.wheels.routes = [];
				application.wheels.staticRoutes = {};
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
				application.wheels.routes = _savedRoutes;
				application.wheels.staticRoutes = _savedStaticRoutes;
				request.cgi["request_method"] = _savedCgiMethod;
			});

			it("does not 404 on OPTIONS preflight when CORS middleware is registered", () => {
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "https://portal.pai.com")
				];
				request.cgi["request_method"] = "OPTIONS";

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				var threw = false;
				var result = "preflight-not-reached";
				try {
					result = d.$request(
						pathInfo = "/api/v1/jvm",
						scriptName = "",
						formScope = {},
						urlScope = {}
					);
				} catch (any e) {
					threw = true;
				}

				expect(threw).toBeFalse();
				expect(result).toBe("");
			});

			it("still 404s on OPTIONS request when no CORS middleware is registered", () => {
				// Preserves existing dispatch behavior — we only short-circuit when
				// a CORS instance is actually configured.
				application.wheels.middleware = [];
				request.cgi["request_method"] = "OPTIONS";

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				expect(function() {
					d.$request(
						pathInfo = "/api/v1/jvm",
						scriptName = "",
						formScope = {},
						urlScope = {}
					);
				}).toThrow("Wheels.RouteNotFound");
			});

			it("still routes non-OPTIONS requests through normal dispatch when CORS is registered", () => {
				// Sanity check: GET requests should still go through $paramParser
				// → $findMatchingRoute and 404 normally when unmatched.
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "*")
				];
				request.cgi["request_method"] = "GET";

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				expect(function() {
					d.$request(
						pathInfo = "/api/v1/jvm",
						scriptName = "",
						formScope = {},
						urlScope = {}
					);
				}).toThrow("Wheels.RouteNotFound");
			});

		});

	}

}
