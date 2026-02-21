component extends="wheels.Testbox" {
	
	function run() {

		describe("Tests that $request", () => {

			beforeEach(() => {
				_params = {controller = "test", action = "index"}
				_originalRoutes = Duplicate(application.wheels.routes)
				_originalRouteIndex = StructKeyExists(application.wheels, "routeIndex") ? Duplicate(application.wheels.routeIndex) : {}
				_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? Duplicate(application.wheels.staticRoutes) : {}
				application.wheels.routes = []
				application.wheels.routeIndex = {}
				application.wheels.staticRoutes = {}
				dispatch = CreateObject("component", "wheels.Dispatch")
			})

			afterEach(() => {
				application.wheels.routes = _originalRoutes
				application.wheels.routeIndex = _originalRouteIndex
				application.wheels.staticRoutes = _originalStaticRoutes
			})

			it("is getting route with format", () => {
				application.wo.mapper().$match(pattern = "users/[username].[format]", controller = "test", action = "test").end()
				args = {}
				args.pathinfo = "/users/foo.bar"
				args.urlScope["username"] = "foo.bar"
				_params = dispatch.$paramParser(argumentCollection = args)

				expect(_params.controller).toBe("Test")
				expect(_params.action).toBe("test")
				expect(_params.username).toBe("foo")
				expect(_params.format).toBe("bar")
			})

			it("is getting route with format only", () => {
				application.wo.mapper().$match(pattern = "contact/export.[format]", controller = "test", action = "test").end()
				args = {}
				args.pathinfo = "/contact/export.csv"
				args.urlScope = {}
				_params = dispatch.$paramParser(argumentCollection = args)

				expect(_params.controller).toBe("Test")
				expect(_params.action).toBe("test")
				expect(_params.format).toBe("csv")
			})

			it("should ignore fullstops when getting route without format", () => {
				application.wo.mapper()
					.$match(pattern = "users/[username]", controller = "test", action = "test", constraints = {"username" = "[^/]+"})
					.end()
				args = {}
				args.pathinfo = "/users/foo.bar"
				args.urlScope["username"] = "foo.bar"
				_params = dispatch.$paramParser(argumentCollection = args)

				expect(_params.username).toBe("foo.bar")
			})

			it("is getting route with format and format not specified", () => {
				application.wo.mapper().$match(pattern = "users/[username](.[format])", controller = "test", action = "test").end()
				args = {}
				args.pathinfo = "/users/foo"
				args.urlScope["username"] = "foo"
				_params = dispatch.$paramParser(argumentCollection = args)

				expect(_params.controller).toBe("Test")
				expect(_params.action).toBe("test")
				expect(_params.username).toBe("foo")
				expect(_params).notToHaveKey('format')
			})
		})
	}
}