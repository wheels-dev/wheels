component extends="wheels.WheelsTest" {
	
	function run() {

		describe("Tests that $request", () => {

			beforeEach(() => {
				_params = {controller = "test", action = "index"}
				_originalRoutes = Duplicate(application.wheels.routes)
				_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {}
				application.wheels.routes = []
				application.wheels.staticRoutes = {}
				dispatch = CreateObject("component", "wheels.Dispatch")
			})

			afterEach(() => {
				application.wheels.routes = _originalRoutes
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

		describe("S5 $request abort content, OPTIONS swallow, wheels hijack", () => {

			beforeEach(() => {
				_originalRoutes = Duplicate(application.wheels.routes)
				_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(application.wheels.staticRoutes) : {}
				_originalNamedRoutePositions = StructKeyExists(application.wheels, "namedRoutePositions") ? StructCopy(application.wheels.namedRoutePositions) : {}
				_savedMiddleware = (StructKeyExists(application.wheels, "middleware") && ArrayLen(application.wheels.middleware))
					? ArraySlice(application.wheels.middleware, 1) : []
				_savedCgiMethod = request.cgi.request_method
				_hadCgiOrigin = StructKeyExists(request.cgi, "http_origin")
				_savedCgiOrigin = _hadCgiOrigin ? request.cgi.http_origin : ""
				_savedEnablePublic = application.wheels.enablePublicComponent
				_savedPublic = application.wheels.public
				_savedCurrentRoute = StructKeyExists(request.wheels, "currentRoute") ? request.wheels.currentRoute : ""
				application.wheels.routes = []
				application.wheels.staticRoutes = {}
			})

			afterEach(() => {
				application.wheels.routes = _originalRoutes
				application.wheels.staticRoutes = _originalStaticRoutes
				application.wheels.namedRoutePositions = _originalNamedRoutePositions
				application.wheels.middleware = _savedMiddleware
				application.wheels.enablePublicComponent = _savedEnablePublic
				application.wheels.public = _savedPublic
				request.cgi["request_method"] = _savedCgiMethod
				if (IsStruct(_savedCurrentRoute)) {
					request.wheels.currentRoute = _savedCurrentRoute
				} else if (StructKeyExists(request.wheels, "currentRoute")) {
					StructDelete(request.wheels, "currentRoute")
				}
				if (_hadCgiOrigin) {
					request.cgi["http_origin"] = _savedCgiOrigin
				} else {
					StructDelete(request.cgi, "http_origin")
				}
				if (StructKeyExists(request, "$wheelsAbortContent")) {
					StructDelete(request, "$wheelsAbortContent")
				}
			})

			it("S5: honors $wheelsAbortContent and skips routing", () => {
				request.$wheelsAbortContent = "s5-abort-body"
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
				var result = d.$request(
					pathInfo = "/no-such-route-s5",
					scriptName = "",
					formScope = {},
					urlScope = {}
				)

				expect(result).toBe("s5-abort-body")
			})

			it("S5: swallows OPTIONS preflight when CORS middleware is registered", () => {
				// Deny-all Cors still makes $hasPreflightCapableMiddleware true,
				// so Dispatch short-circuits OPTIONS before $findMatchingRoute.
				// Do not reflect an Origin header: cfheader leaks into later
				// $setCORSHeaders specs in this same request (getHeader returns
				// the first value written, not the last).
				application.wheels.middleware = [new wheels.middleware.Cors()]
				request.cgi["request_method"] = "OPTIONS"
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
				var threw = {flag = false}
				var result = "s5-preflight-not-reached"
				try {
					result = d.$request(
						pathInfo = "/s5/preflight",
						scriptName = "",
						formScope = {},
						urlScope = {}
					)
				} catch (any e) {
					threw.flag = true
				}

				expect(threw.flag).toBeFalse()
				expect(result).toBe("")
			})

			it("S5: hijacks a wheels controller path and returns empty string", () => {
				application.wheels.enablePublicComponent = true
				application.wheels.public = new wheels.tests._assets.dispatch.InvokeMethodFixture()
				application.wo.mapper()
					.$match(pattern = "s5hijack", controller = "wheels", action = "publicHandler")
					.end()
				request.cgi["request_method"] = "GET"
				var d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
				var result = d.$request(
					pathInfo = "/s5hijack",
					scriptName = "",
					formScope = {},
					urlScope = {}
				)

				expect(result).toBe("")
				expect(application.wheels.public.getState().handlerCompleted).toBeTrue()
			})
		})
	}
}