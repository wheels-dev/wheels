component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that URLFor", () => {

			beforeEach(() => {
				config = {path = "wheels", fileName = "Mapper", method = "$init"}
				_params = {controller = "test", action = "index"}
				_originalRoutes = Duplicate(application.wheels.routes)
				_originalUrlRewriting = application.wheels.URLRewriting
				_originalObfuscateUrls = application.wheels.obfuscateUrls
			})

			afterEach(() => {
				application.wheels.routes = _originalRoutes
				application.wheels.URLRewriting = _originalUrlRewriting
				application.wheels.obfuscateUrls = _originalObfuscateUrls
			})

			it("issue 455", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.$match(name = "user_2", pattern = "user/[user_id]/[controller]/[action]")
					.end()
				g.$setNamedRoutePositions()
				application.wheels.URLRewriting = "Off"
				application.wheels.obfuscateUrls = true
				r = g.urlFor(route = "user_2", user_id = "5559", controller = "SurveyTemplates", action = "index")

				expect(r).toInclude("b24dae")
			})

			it("properly hyphenates the links", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.$match(name = "user_2", pattern = "user/[user_id]/[controller]/[action]")
					.end()
				g.$setNamedRoutePositions()
				application.wheels.URLRewriting = "On"
				e = "/user/5559/survey-templates/index"
				r = g.urlFor(route = "user_2", user_id = "5559", controller = "SurveyTemplates", action = "index")
				
				expect(r).toInclude(e)
			})

			it("properly adds route with format", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.$match(name = "user_2", pattern = "user/[user_id]/[controller]/[action].[format]")
					.end()
				g.$setNamedRoutePositions()
				application.wheels.URLRewriting = "On"
				e = "/user/5559/survey-templates/index.csv"
				r = g.urlFor(route = "user_2", user_id = "5559", controller = "SurveyTemplates", action = "index", format = "csv")

				expect(r).toInclude(e)
			})

			it("correctly detects https using onlypath", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.$match(name = "user_2", pattern = "user/[user_id]/[controller]/[action].[format]")
					.end()
				g.$setNamedRoutePositions()
				request.cgi.server_protocol = ""
				request.cgi.server_port_secure = 1
				r = g.urlFor(
					route = "user_2",
					user_id = "5559",
					controller = "SurveyTemplates",
					action = "index",
					format = "csv",
					onlyPath = false
				)

				expect(left(r,5)).toBe("https")
			})

			it("issue 1046 no route argument", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.wildcard(mapKey = true)
					.end()
				g.$setNamedRoutePositions()
				r1 = g.urlFor(controller = "Example")
				r2 = g.urlFor(controller = "Example", action = "MyAction")
				r3 = g.urlFor(controller = "Example", action = "MyAction", key = 123)

				if (application.wheels.URLRewriting eq 'On') {
					expect(r1).toBe("/example/index")
					expect(r2).toBe("/example/my-action")
					expect(r3).toBe("/example/my-action/123")
				} else if (application.wheels.URLRewriting eq 'Off') {
					expect(r1).toBe("/index.cfm?controller=example&action=index")
					expect(r2).toBe("/index.cfm?controller=example&action=my-action")
					expect(r3).toBe("/index.cfm?controller=example&action=my-action&key=123")
				} else {
					expect(r1).toBe("/index.cfm/example/index")
					expect(r2).toBe("/index.cfm/example/my-action")
					expect(r3).toBe("/index.cfm/example/my-action/123")
				}

			})

			it("encodes URL parameters with special characters when encode=true", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.wildcard(mapKey = true)
					.end()
				g.$setNamedRoutePositions()
				
				// Test with special characters in parameters
				htmlParam = "<strong>bold</strong>"
				ampParam = "first&second"
				quotesParam = 'quotes"in"param'
				
				// Test with encode=true
				r1 = g.urlFor(controller = "example", action = "show", key = htmlParam, encode = true)
				r2 = g.urlFor(controller = "example", action = "show", key = ampParam, encode = true)
				r3 = g.urlFor(controller = "example", action = "show", key = quotesParam, encode = true)
				
				// Expected encoded results
				if (application.wheels.URLRewriting eq 'On') {
					expect(r1).toBe("/example/show/%3Cstrong%3Ebold%3C%2Fstrong%3E")
					expect(r2).toBe("/example/show/first%26second")
					expect(r3).toBe("/example/show/quotes%22in%22param")
				} else if (application.wheels.URLRewriting eq 'Off') {
					expect(r1).toBe("/index.cfm?controller=example&action=show&key=%3Cstrong%3Ebold%3C%2Fstrong%3E")
					expect(r2).toBe("/index.cfm?controller=example&action=show&key=first%26second")
					expect(r3).toBe("/index.cfm?controller=example&action=show&key=quotes%22in%22param")
				} else {
					expect(r1).toBe("/index.cfm/example/show/%3Cstrong%3Ebold%3C%2Fstrong%3E")
					expect(r2).toBe("/index.cfm/example/show/first%26second")
					expect(r3).toBe("/index.cfm/example/show/quotes%22in%22param")
				}
			})
			
			it("does not encode URL parameters with special characters when encode=false", () => {
				mapper = $mapper()
				mapper
					.$draw()
					.wildcard(mapKey = true)
					.end()
				g.$setNamedRoutePositions()
				
				// Test with special characters in parameters
				htmlParam = "<strong>bold</strong>"
				ampParam = "first&second"
				quotesParam = 'quotes"in"param'
				
				// Test with encode=false
				r1 = g.urlFor(controller = "example", action = "show", key = htmlParam, encode = false)
				r2 = g.urlFor(controller = "example", action = "show", key = ampParam, encode = false)
				r3 = g.urlFor(controller = "example", action = "show", key = quotesParam, encode = false)
				
				// Expected unencoded results
				if (application.wheels.URLRewriting eq 'On') {
					expect(r1).toBe("/example/show/<strong>bold</strong>")
					expect(r2).toBe("/example/show/first&second")
					expect(r3).toBe('/example/show/quotes"in"param')
				} else if (application.wheels.URLRewriting eq 'Off') {
					expect(r1).toBe("/index.cfm?controller=example&action=show&key=<strong>bold</strong>")
					expect(r2).toBe("/index.cfm?controller=example&action=show&key=first&second")
					expect(r3).toBe('/index.cfm?controller=example&action=show&key=quotes"in"param')
				} else {
					expect(r1).toBe("/index.cfm/example/show/<strong>bold</strong>")
					expect(r2).toBe("/index.cfm/example/show/first&second")
					expect(r3).toBe('/index.cfm/example/show/quotes"in"param')
				}
			})
		})
	}

	public struct function $mapper() {
		local.args = Duplicate(config)
		StructAppend(local.args, arguments, true)
		return g.$createObjectFromRoot(argumentCollection = local.args)
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
	}
}