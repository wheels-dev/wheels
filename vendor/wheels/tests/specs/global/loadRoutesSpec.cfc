component extends="wheels.WheelsTest" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes)
		_hadStaticRoutes = StructKeyExists(application.wheels, "staticRoutes")
		_originalStaticRoutes = _hadStaticRoutes ? StructCopy(application.wheels.staticRoutes) : {}
		_hadNamedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions")
		_originalNamedRoutePositions = _hadNamedRoutePositions ? StructCopy(application.wheels.namedRoutePositions) : {}
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes
		// Restore only what existed: an unconditional assignment would leave a
		// spurious empty key behind when the spec ran before the app ever
		// populated these caches (#2933 review, #2977).
		if (_hadStaticRoutes) {
			application.wheels.staticRoutes = _originalStaticRoutes
		} else {
			StructDelete(application.wheels, "staticRoutes")
		}
		if (_hadNamedRoutePositions) {
			application.wheels.namedRoutePositions = _originalNamedRoutePositions
		} else {
			StructDelete(application.wheels, "namedRoutePositions")
		}
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
