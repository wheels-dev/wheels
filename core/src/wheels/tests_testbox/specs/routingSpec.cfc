component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that $findMatchingRoute", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
				SavedRoutes = Duplicate(application.wheels.routes)
				application.wheels.routes = []
			})

			afterEach(() => {
				application.wheels.routes = SavedRoutes
			})

			it("works with empty route", () => {
				g.mapper().root(to = "pages##index").end()
				r = dispatch.$findMatchingRoute(path = "", format = "")

				expect(r.controller).toBe("pages")
				expect(r.action).toBe("index")
			})

			it("works with controller only", () => {
				g.mapper().$match(pattern = "pages", to = "pages##index").end()
				r = dispatch.$findMatchingRoute(path = "pages", format = "")

				expect(r.controller).toBe("pages")
				expect(r.action).toBe("index")
			})

			it("controller and action required", () => {
				g.mapper().$match(pattern = "pages/blah", to = "pages##index").end()

				expect(function() {
					dispatch.$findMatchingRoute(path="/pages", format="")
				}).toThrow("Wheels.RouteNotFound")

				r = dispatch.$findMatchingRoute(path = "pages/blah", format = "")

				expect(r.controller).toBe("pages")
				expect(r.action).toBe("index")
			})

			it("works with extra variables passed", () => {
				g.mapper().$match(pattern = "pages/blah/[firstname]/[lastname]", to = "pages##index").end()
				r = dispatch.$findMatchingRoute(path = "pages/blah/tony/petruzzi", format = "")
				expect(r.controller).toBe("pages")
				expect(r.action).toBe("index")
				expect(r.foundvariables).toBe("firstname,lastname")
			})

			it("works with wildcard routes", () => {
				g.mapper().$match(pattern = "*", to = "pages##index").end()
				r = dispatch.$findMatchingRoute(path = "thisismyroute/therearemanylikeit/butthisoneismine", format = "")

				expect(r.controller).toBe("pages")
				expect(r.action).toBe("index")
			})
		})
	}
}