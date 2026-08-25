component extends="wheels.WheelsTest" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes)
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {}
		_originalNamedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions") ? StructCopy(application.wheels.namedRoutePositions) : {}
		nounPlurals = [
			"people",
			"dogs",
			"cats",
			"pigs",
			"admins",
			"pages",
			"elements",
			"charts",
			"tabs",
			"categories",
			"cows",
			"services",
			"products",
			"pictures",
			"images",
			"routes",
			"cars",
			"vehicles",
			"bikes",
			"buses",
			"cups",
			"words",
			"cells",
			"phones",
			"speakers",
			"sneakers",
			"lions",
			"tigers",
			"elephants",
			"deers",
			"pandas",
			"places",
			"things",
			"mugs",
			"plants",
			"stars",
			"cards",
			"credits",
			"coins",
			"monitors",
			"books",
			"coats",
			"shirts",
			"jackets",
			"pants",
			"miners",
			"hangers",
			"plates",
			"spoons",
			"forks",
			"knives",
			"users"
		]

		$clearRoutes()


		dr = application.wo.mapper().root(to = "dashboard##index").namespace("admin")
		for (local.item in nounPlurals) {
			dr.resources(name = local.item, nested = true)
				.resources(name = "comments", shallow = true)
				.resources(name = "likes", shallow = true)
				.end()
		}
		dr.root(to = "dashboard##index").end()
		for (local.item in nounPlurals) {
			dr.resources(name = local.item, nested = true)
				.resources(name = "comments", shallow = true)
				.resources(name = "likes", shallow = true)
				.end()
		}
		dr.resource("profile").end()

		d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes
		application.wheels.staticRoutes = _originalStaticRoutes
		application.wheels.namedRoutePositions = _originalNamedRoutePositions
	}
	
	function run() {
		
		describe("Tests that $findMatchingRouteMega", () => {

			beforeEach(() => {
				_originalForm = Duplicate(form)
				_originalUrl = Duplicate(url)
				StructClear(form)
				StructClear(url)
				_originalCgiMethod = request.cgi.request_method
			})

			afterEach(() => {
				StructClear(form)
				StructClear(url)
				StructAppend(form, _originalForm, false)
				StructAppend(url, _originalUrl, false)
				request.cgi["request_method"] = _originalCgiMethod
			})

			it("raises error when route is not found", () => {
				expect(function() {
					d.$findMatchingRoute(path="scouts")
				}).toThrow("Wheels.RouteNotFound")
			})

			it("finds nested get collection route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users")

				expect(route.name).toBe("adminUsers")
				expect(route.methods).toBe("GET")
			})

			it("S10: matches top-level users, not the admin namespaced collection", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users")

				expect(route.name).toBe("users")
				expect(route.controller).toBe("users")
				expect(route.action).toBe("index")
				expect(route.methods).toBe("GET")
			})

			it("S10: matches a top-level member show on the fixture", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/1")

				expect(route.name).toBe("user")
				expect(route.action).toBe("show")
			})

			it("S10: matches POST collection create, not the GET index on the same path", () => {
				request.cgi["request_method"] = "POST"
				route = d.$findMatchingRoute(path = "users")

				expect(route.name).toBe("users")
				expect(route.action).toBe("create")
				expect(route.methods).toBe("POST")
			})

			it("S10: matches a nested admin member, not the top-level user show", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/1")

				expect(route.name).toBe("adminUser")
				expect(route.action).toBe("show")
			})

			it("S10: matches nested comments under users on the fixture", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/1/comments")

				expect(route.controller).toBe("comments")
				expect(route.action).toBe("index")
			})

			it("S10: matches a shallow comment member off the fixture", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "comments/1")

				expect(route.controller).toBe("comments")
				expect(route.action).toBe("show")
			})

			it("S10: matches the singular profile resource on the fixture", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "profile")

				expect(route.controller).toBe("profiles")
				expect(route.action).toBe("show")
			})

			it("S10: matches the fixture root, not a later resource collection", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "")

				expect(route.controller).toBe("dashboard")
				expect(route.action).toBe("index")
			})

			it("S10: matches another noun from the 50-resource fixture", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "miners")

				expect(route.name).toBe("miners")
				expect(route.action).toBe("index")
			})

			it("S10: HEAD aliases GET on a nested admin collection from the fixture", () => {
				request.cgi["request_method"] = "HEAD"
				route = d.$findMatchingRoute(path = "admin/dogs")

				expect(route.name).toBe("adminDogs")
				expect(ListFindNoCase(route.methods, "GET")).toBeGT(0)
			})
		})
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
		application.wheels.staticRoutes = {}
	}
}