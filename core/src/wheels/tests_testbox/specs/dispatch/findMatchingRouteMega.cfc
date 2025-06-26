component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes)
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
		})
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
	}
}