component extends="wheels.WheelsTest" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes)
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {}
		_originalNamedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions") ? StructCopy(application.wheels.namedRoutePositions) : {}
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes
		application.wheels.staticRoutes = _originalStaticRoutes
		application.wheels.namedRoutePositions = _originalNamedRoutePositions
	}

	function run() {

		describe("Tests that $loadRoutes", () => {

			it("clears the staticRoutes index so a route reload cannot serve stale entries", () => {
				if (!StructKeyExists(application.wheels, "staticRoutes")) {
					application.wheels.staticRoutes = {}
				}
				application.wheels.staticRoutes["GET:/stale-static-route-sentinel"] = {
					pattern = "/stale-static-route-sentinel",
					controller = "doesnotexist",
					action = "index"
				}

				application.wo.$loadRoutes()

				expect(StructKeyExists(application.wheels.staticRoutes, "GET:/stale-static-route-sentinel")).toBeFalse()
			})
		})
	}
}
