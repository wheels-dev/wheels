component extends="wheels.WheelsTest" {

	// Regression / extension-point guard for issue #2830.
	//
	// The built-in `/_browser/login-as` fixture (mounted when
	// `application.wheels.loadBrowserTestFixtures = true`) hard-coded its
	// session writes to `session.userId = 1` and `session.userEmail =
	// params.identifier`. Real apps store richer session shapes, so they
	// either had to skip the framework fixture and duplicate the route
	// themselves or patch the vendor tree on every upgrade.
	//
	// The fix introduces `application.wheels.browserLoginAsHandler` — a
	// `"Controller##action"` string the framework reads at route-
	// registration time and uses as the `/_browser/login-as` target in
	// place of `BrowserTestLogin##create`. Env-gating moves to a
	// `wheels.middleware.BrowserTestFixtureGuard` middleware that's
	// attached to the whole `/_browser` scope so the gate still applies
	// when an app supplies its own handler.
	//
	// These tests pin the routing contract: default points at the built-
	// in controller, override redirects to the app's controller, and
	// every `/_browser/*` route declares the env-gate middleware so app
	// handlers don't need to re-implement it.

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes);
		_originalNamed = StructCopy(application.wheels.namedRoutePositions);
		_originalEnv = application.wheels.environment;
		_originalLoadFixtures = StructKeyExists(application.wheels, "loadBrowserTestFixtures")
			? application.wheels.loadBrowserTestFixtures
			: false;
		_hadHandler = StructKeyExists(application.wheels, "browserLoginAsHandler");
		_originalHandler = _hadHandler ? application.wheels.browserLoginAsHandler : "";
		_originalControllerPath = application.wheels.controllerPath;
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes")
			? StructCopy(application.wheels.staticRoutes)
			: {};
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes;
		application.wheels.namedRoutePositions = _originalNamed;
		application.wheels.environment = _originalEnv;
		application.wheels.loadBrowserTestFixtures = _originalLoadFixtures;
		application.wheels.controllerPath = _originalControllerPath;
		if (_hadHandler) {
			application.wheels.browserLoginAsHandler = _originalHandler;
		} else if (StructKeyExists(application.wheels, "browserLoginAsHandler")) {
			StructDelete(application.wheels, "browserLoginAsHandler");
		}
		application.wheels.staticRoutes = _originalStaticRoutes;
	}

	function run() {
		describe("browserLoginAsHandler — app-level override of /_browser/login-as fixture (##2830)", () => {

			beforeEach(() => {
				application.wheels.environment = "testing";
				application.wheels.loadBrowserTestFixtures = true;
			});

			it("defaults /_browser/login-as to the framework's BrowserTestLogin##create when no override is set", () => {
				if (StructKeyExists(application.wheels, "browserLoginAsHandler")) {
					StructDelete(application.wheels, "browserLoginAsHandler");
				}

				application.wo.$lockedLoadRoutes();

				var loginRoute = $findRouteByName("browserTestLoginAs");
				expect(StructIsEmpty(loginRoute)).toBeFalse(
					"expected /_browser/login-as route to be registered when loadBrowserTestFixtures = true"
				);
				expect(loginRoute.controller).toBe("BrowserTestLogin");
				expect(loginRoute.action).toBe("create");
			});

			it("delegates /_browser/login-as to browserLoginAsHandler controller##action when the setting is configured", () => {
				application.wheels.browserLoginAsHandler = "MyAuthFixture##loginAs";

				application.wo.$lockedLoadRoutes();

				var loginRoute = $findRouteByName("browserTestLoginAs");
				expect(StructIsEmpty(loginRoute)).toBeFalse(
					"expected /_browser/login-as route to be registered when loadBrowserTestFixtures = true"
				);
				expect(loginRoute.controller).toBe(
					"MyAuthFixture",
					"expected /_browser/login-as to dispatch to the app's controller from application.wheels.browserLoginAsHandler, got controller=" & loginRoute.controller
				);
				expect(loginRoute.action).toBe("loginAs");
			});

			it("ignores an empty browserLoginAsHandler setting and falls back to BrowserTestLogin##create", () => {
				application.wheels.browserLoginAsHandler = "";

				application.wo.$lockedLoadRoutes();

				var loginRoute = $findRouteByName("browserTestLoginAs");
				expect(StructIsEmpty(loginRoute)).toBeFalse();
				expect(loginRoute.controller).toBe("BrowserTestLogin");
				expect(loginRoute.action).toBe("create");
			});

			it("env-gates the /_browser/* scope via BrowserTestFixtureGuard middleware so app handlers still get the gate", () => {
				if (StructKeyExists(application.wheels, "browserLoginAsHandler")) {
					StructDelete(application.wheels, "browserLoginAsHandler");
				}

				application.wo.$lockedLoadRoutes();

				var loginRoute = $findRouteByName("browserTestLoginAs");
				expect(StructIsEmpty(loginRoute)).toBeFalse();
				expect(StructKeyExists(loginRoute, "middleware")).toBeTrue(
					"expected /_browser scope to register env-gate middleware on each route"
				);

				var mw = loginRoute.middleware;
				if (IsSimpleValue(mw)) {
					mw = ListToArray(mw);
				}
				var found = false;
				for (var entry in mw) {
					if (FindNoCase("BrowserTestFixtureGuard", entry)) {
						found = true;
						break;
					}
				}
				expect(found).toBeTrue(
					"expected /_browser route middleware to include wheels.middleware.BrowserTestFixtureGuard, got: " & SerializeJSON(mw)
				);
			});

		});
	}

	private struct function $findRouteByName(required string name) {
		for (var route in application.wheels.routes) {
			if (StructKeyExists(route, "name") && route.name == arguments.name) {
				return route;
			}
		}
		return {};
	}

}
