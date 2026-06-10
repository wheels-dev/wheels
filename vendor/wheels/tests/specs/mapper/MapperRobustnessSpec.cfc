/**
 * Mapper robustness specs:
 * - resources() only/except normalization (case + whitespace) so excluded
 *   destructive routes cannot stay registered, plus development-mode validation
 *   of unknown REST action names.
 * - namespace()/package()/group()/api()/version() forwarding scope() options
 *   such as middleware and binding instead of silently dropping them.
 * - end() scope-stack underflow guard.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Mapper.$addRoute() also appends to the application-scoped route data,
		// so snapshot and restore it to avoid polluting other specs.
		_originalRoutes = Duplicate(application.wheels.routes);
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(
			application.wheels.staticRoutes
		) : {};
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes;
		application.wheels.staticRoutes = _originalStaticRoutes;
	}

	function run() {
		describe("resources() only/except normalization", function() {
			beforeEach(function(currentSpec) {
				m = new wheels.Mapper();
				m.$init();
			});

			afterEach(function(currentSpec) {
				StructDelete(variables, "m");
			});

			it("excludes destructive routes when except uses different casing", function() {
				m.$draw().resources(name = "users", except = "Delete", mapFormat = false).end();
				var routes = m.getRoutes();
				var found = false;
				for (var route in routes) {
					if (StructKeyExists(route, "action") && route.action == "delete") {
						found = true;
					}
				}
				expect(found).toBeFalse();
				expect(routes).toBeArray().toHaveLength(7);
			});

			it("excludes routes listed with surrounding whitespace in except", function() {
				m.$draw().resources(name = "users", except = "new, delete", mapFormat = false).end();
				var routes = m.getRoutes();
				var found = false;
				for (var route in routes) {
					if (StructKeyExists(route, "action") && ListFindNoCase("new,delete", route.action)) {
						found = true;
					}
				}
				expect(found).toBeFalse();
				expect(routes).toBeArray().toHaveLength(6);
			});

			it("trims and lowercases items in only", function() {
				m.$draw().resources(name = "users", only = "Index, Show", mapFormat = false).end();
				var routes = m.getRoutes();
				expect(routes).toBeArray().toHaveLength(2);
				var actions = "";
				for (var route in routes) {
					if (StructKeyExists(route, "action")) {
						actions = ListAppend(actions, route.action);
					}
				}
				expect(ListFindNoCase(actions, "index")).toBeGT(0);
				expect(ListFindNoCase(actions, "show")).toBeGT(0);
			});

			it("throws on unknown action names when showErrorInformation is enabled", function() {
				var originalSetting = application.wheels.showErrorInformation;
				application.wheels.showErrorInformation = true;
				try {
					expect(function() {
						m.$draw().resources(name = "users", except = "destroy", mapFormat = false).end();
					}).toThrow(type = "Wheels.InvalidResource");
				} finally {
					application.wheels.showErrorInformation = originalSetting;
				}
			});

			it("ignores unknown action names when showErrorInformation is disabled", function() {
				var originalSetting = application.wheels.showErrorInformation;
				application.wheels.showErrorInformation = false;
				try {
					m.$draw().resources(name = "users", except = "destroy", mapFormat = false).end();
					expect(m.getRoutes()).toBeArray().toHaveLength(8);
				} finally {
					application.wheels.showErrorInformation = originalSetting;
				}
			});
		});

		describe("scope wrapper option passthrough", function() {
			beforeEach(function(currentSpec) {
				m = new wheels.Mapper();
				m.$init();
			});

			afterEach(function(currentSpec) {
				StructDelete(variables, "m");
			});

			it("namespace() forwards middleware to child routes", function() {
				m.$draw()
					.namespace(name = "admin", middleware = ["AdminAuth"])
					.get(name = "dashboard", to = "dashboard##index")
					.end()
					.end();
				var routes = m.getRoutes();
				expect(routes[1]).toHaveKey("middleware");
				expect(routes[1].middleware).toBeArray().toHaveLength(1);
				expect(routes[1].middleware[1]).toBe("AdminAuth");
			});

			it("namespace() forwards binding to child routes", function() {
				m.$draw()
					.namespace(name = "admin", binding = true)
					.get(name = "users", to = "users##index")
					.end()
					.end();
				var routes = m.getRoutes();
				expect(routes[1]).toHaveKey("binding");
				expect(routes[1].binding).toBeTrue();
			});

			it("package() forwards middleware to child routes", function() {
				m.$draw()
					.package(name = "admin", middleware = ["AdminAuth"])
					.get(name = "dashboard", to = "dashboard##index")
					.end()
					.end();
				var routes = m.getRoutes();
				expect(routes[1]).toHaveKey("middleware");
				expect(routes[1].middleware[1]).toBe("AdminAuth");
			});

			it("group() forwards middleware to child routes", function() {
				m.$draw()
					.group(path = "admin", middleware = ["AdminAuth"], callback = function(map) {
						map.get(name = "dashboard", to = "admin##dashboard");
					})
					.end();
				var routes = m.getRoutes();
				expect(routes[1]).toHaveKey("middleware");
				expect(routes[1].middleware[1]).toBe("AdminAuth");
			});

			it("api() forwards middleware to child routes", function() {
				m.$draw()
					.api(middleware = ["ApiAuth"], callback = function(apiMap) {
						apiMap.get(name = "users", to = "users##index");
					})
					.end();
				var routes = m.getRoutes();
				expect(routes[1].pattern).toBe("/api/users");
				expect(routes[1]).toHaveKey("middleware");
				expect(routes[1].middleware[1]).toBe("ApiAuth");
			});

			it("version() forwards middleware to child routes", function() {
				m.$draw()
					.api(callback = function(apiMap) {
						apiMap.version(number = 1, middleware = ["V1Auth"], callback = function(v1) {
							v1.get(name = "users", to = "users##index");
						});
					})
					.end();
				var routes = m.getRoutes();
				expect(routes[1].pattern).toBe("/api/v1/users");
				expect(routes[1]).toHaveKey("middleware");
				expect(routes[1].middleware[1]).toBe("V1Auth");
			});
		});

		describe("end() scope-stack underflow", function() {
			beforeEach(function(currentSpec) {
				m = new wheels.Mapper();
				m.$init();
			});

			afterEach(function(currentSpec) {
				StructDelete(variables, "m");
			});

			it("throws a clear DSL error instead of a raw engine error on an extra end()", function() {
				m.$draw().end();
				expect(function() {
					m.end();
				}).toThrow(type = "Wheels.InvalidRoute");
			});
		});
	}

}
