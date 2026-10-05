/**
 * What middleware attaches to the request context reaches the controller: the
 * AuthMiddleware result as request.auth (as its docs say), and the whole context as
 * request.wheels.middlewareContext. Exercised end to end through Dispatch.$request().
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("middleware results reach the controller", () => {

			beforeEach(() => {
				variables.saved = {
					routes = Duplicate(application.wheels.routes),
					staticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {},
					namedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions") ? StructCopy(application.wheels.namedRoutePositions) : {},
					middleware = (StructKeyExists(application.wheels, "middleware") && ArrayLen(application.wheels.middleware)) ? ArraySlice(application.wheels.middleware, 1) : [],
					method = request.cgi.request_method,
					hadAuth = StructKeyExists(request, "auth")
				};
				application.wheels.routes = [];
				application.wheels.staticRoutes = {};
				application.wo.mapper().$match(pattern = "mwcontext", controller = "middlewareContextProbe", action = "show").end();
				request.cgi["request_method"] = "GET";
			});

			afterEach(() => {
				application.wheels.routes = variables.saved.routes;
				application.wheels.staticRoutes = variables.saved.staticRoutes;
				application.wheels.namedRoutePositions = variables.saved.namedRoutePositions;
				application.wheels.middleware = variables.saved.middleware;
				request.cgi["request_method"] = variables.saved.method;
				if (!variables.saved.hadAuth) {
					StructDelete(request, "auth");
				}
				if (StructKeyExists(request.wheels, "middlewareContext")) {
					StructDelete(request.wheels, "middlewareContext");
				}
			});

			it("gives the controller the AuthMiddleware result as request.auth", () => {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());
				application.wheels.middleware = [new wheels.middleware.AuthMiddleware(authenticator = auth)];

				var seen = dispatchProbe();

				expect(seen.hasAuth).toBeTrue();
				expect(seen.authSuccess).toBeTrue();
				expect(seen.principalId).toBe(1);
				expect(seen.strategy).toBe("alwaysPass");
			});

			it("lets an allowAnonymous controller see that authentication failed", () => {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
				application.wheels.middleware = [new wheels.middleware.AuthMiddleware(authenticator = auth, allowAnonymous = true)];

				var seen = dispatchProbe();

				expect(seen.hasAuth).toBeTrue();
				expect(seen.authSuccess).toBeFalse();
			});

			it("gives the controller what any middleware added to the context", () => {
				application.wheels.middleware = [new wheels.tests._assets.middleware.NoteMiddleware()];

				var seen = dispatchProbe();

				expect(seen.note).toBe("from-middleware");
			});

		});

	}

	private struct function dispatchProbe() {
		var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
		var response = d.$request(pathInfo = "/mwcontext", scriptName = "", formScope = {}, urlScope = {});
		return DeserializeJSON(response);
	}

}
