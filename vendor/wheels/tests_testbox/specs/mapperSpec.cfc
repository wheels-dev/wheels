component extends="wheels.Testbox" {

	function beforeAll() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"}
		_params = {controller = "test", action = "index"}
		_originalRoutes = Duplicate(application.wheels.routes)
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes
	}

	function run() {

		describe("Tests that initialization", () => {

			it("is setting init defaults", () => {
				mapper = $mapper()
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()

				expect(mapperVarScope.restful).toBeTrue()
				expect(mapperVarScope.methods).toBeTrue()
			})

			it("is setting init restful false", () => {
				mapper = $mapper(restful = false)
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()

				expect(mapperVarScope.restful).toBeFalse()
				expect(mapperVarScope.methods).toBeFalse()
			})

			it("is setting init restful false and methods true", () => {
				mapper = $mapper(restful = false, methods = true)
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()

				expect(mapperVarScope.restful).toBeFalse()
				expect(mapperVarScope.methods).toBeTrue()
			})
		})

		describe("Tests that mapping function", () => {

			it("draw is setting defaults", () => {
				mapper = $mapper().$draw()
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()

				expect(mapperVarScope.restful).toBeTrue()
				expect(mapperVarScope.methods).toBeTrue()
			})

			it("draw is setting restful false", () => {
				mapper = $mapper(restful = false).$draw(restful = false)
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()
				
				expect(mapperVarScope.restful).toBeFalse()
				expect(mapperVarScope.methods).toBeFalse()
			})

			it("draw is setting restful false and methods true", () => {
				mapper = $mapper(restful = false, methods = true).$draw(restful = false, methods = true)
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()
				
				expect(mapperVarScope.restful).toBeFalse()
				expect(mapperVarScope.methods).toBeTrue()
			})
			
			it("draw is setting mapFormat false", () => {
				mapper = $mapper(mapFormat = false).$draw()
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()
				
				expect(mapperVarScope.mapFormat).toBeFalse()
			})
			
			it("draw is resetting the stack", () => {
				mapper = $mapper().$draw()
				mapper.inspect = $inspect
				mapperVarScope = mapper.inspect()
				
				expect(mapperVarScope.scopeStack).toHaveLength(1)
			})
			
			it("end is removing top of stack", () => {
				mapper = $mapper().$draw()
				mapper.inspect = $inspect
				drawVarScope = mapper.inspect()
				drawLen = ArrayLen(drawVarScope.scopeStack)
				mapper.end()
				endVarScope = mapper.inspect()
				endLen = ArrayLen(endVarScope.scopeStack)
				
				expect(drawLen).toBe(1)
				expect(endLen).toBe(0)
			})
		})

		describe("Tests that match", () => {

			beforeEach(() => {
				$clearRoutes()
				mapper = $mapper()
			})

			it("works with basic arguments", () => {
				mapper
					.$draw()
					.$match(name = "signIn", method = "get", controller = "sessions", action = "new")
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works with to argument", () => {
				mapper
					.$draw()
					.$match(name = "signIn", method = "get", to = "sessions##new")
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works without name", () => {
				mapper
					.$draw()
					.$match(pattern = "/sign-in", method = "get", to = "sessions##new")
					.end()

				expect(application.wheels.routes[1]).notToHaveKey("name")
				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works with basic arguments and controller scoped", () => {
				mapper
					.$draw()
					.controller("sessions")
					.$match(name = "signIn", method = "get", action = "new")
					.end()
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works with basic arguments and package scoped", () => {
				mapper
					.$draw()
					.namespace("admin")
					.$match(name = "signIn", method = "get", action = "new", controller = "sessions")
					.end()
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("admin.Sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works with package scope and contoller scope", () => {
				mapper
					.$draw()
					.namespace("admin")
					.controller("sessions")
					.$match(name = "signIn", method = "get", action = "new")
					.end()
					.end()
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("admin.Sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works after disabling methods", () => {
				mapper
					.$draw(restful = false, methods = false)
					.$match(pattern = "/sign-in", method = "get", to = "sessions##new")
					.end()

				expect(application.wheels.routes[1]).notToHaveKey("method")
				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].controller).toBe("sessions")
				expect(application.wheels.routes[1].action).toBe("new")
			})

			it("works with single optional pattern segment", () => {
				mapper
					.$draw()
					.$match(pattern = "/sign-in(.[format])", method = "get", to = "sessions##new")
					.end()

				expect(application.wheels.routes).toHaveLength(2)
			})

			it("works with multiple optional pattern segment", () => {
				mapper
					.$draw()
					.$match(pattern = "/[controller](/[action](/[key](.[format])))", action = "index", method = "get")
					.end()

				expect(application.wheels.routes).toHaveLength(4)
			})

			it("works with globing", () => {
				mapper
					.$draw()
					.$match(name = "profile", pattern = "profiles/*[userseo]/[userid]", to = "profile##show")
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect("profiles/this/is/some/seo/text/id123").toMatch(application.wheels.routes[1].regex)
			})

			it("works with multiple globs", () => {
				mapper
					.$draw()
					.$match(name = "profile", pattern = "*[before]/foo/*[after]", to = "profile##show")
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect("this/is/before/foo/this/is/after").toMatch(application.wheels.routes[1].regex)
			})

			it("throws error without name or pattern", () => {
				mapper = $mapper().$draw()

				expect(function() {
					mapper.$match(method="get", controller="sessions", action="new")
				}).toThrow("Wheels.MapperArgumentMissing")
			})

			it("throws error with invalid route", () => {
				mapper = $mapper().$draw()

				expect(function() {
					mapper.$match(pattern="[controller](/[action])(/[key])")
				}).toThrow("Wheels.InvalidRoute")
			})
		})
	
		describe("Tests that package", () => {

			it("generates URL pattern without name", () => {
				$clearRoutes()
				$mapper()
					.$draw()
					.package("public")
					.root(to = "pages##home")
					.end()
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/.[format]")
				expect(application.wheels.routes[2].pattern).toBe("/")
			})

			it("scopes controller to subfolder", () => {
				$clearRoutes()
				$mapper()
					.$draw()
					.package("public")
					.root(to = "pages##home")
					.end()
					.end()

				expect(application.wheels.routes[1].controller).toBe("public.pages")
				expect(application.wheels.routes[2].controller).toBe("public.pages")
			})
		})

		describe("Tests that redirect", () => {

			it("argument is passed through", () => {
				$clearRoutes()
				$mapper()
					.$draw()
					.get(name = "testredirect1", redirect = "https://www.google.com")
					.post(name = "testredirect2", redirect = "https://www.google.com")
					.put(name = "testredirect3", redirect = "https://www.google.com")
					.patch(name = "testredirect4", redirect = "https://www.google.com")
					.delete(name = "testredirect5", redirect = "https://www.google.com")
					.end()

				expect(application.wheels.routes[1]).toHaveKey("redirect")
				expect(application.wheels.routes[2]).toHaveKey("redirect")
				expect(application.wheels.routes[3]).toHaveKey("redirect")
				expect(application.wheels.routes[4]).toHaveKey("redirect")
				expect(application.wheels.routes[5]).toHaveKey("redirect")
			})
		})

		describe("Tests that resourcing function", () => {

			beforeEach(() => {
				$clearRoutes()
				mapper = $mapper()
			})

			it("resource produces routes", () => {
				mapper
					.$draw()
					.resource(name = "pigeon")
					.end()

				expect(application.wheels.routes).toHaveLength(14)
			})

			it("resource produces routes with list", () => {
				mapper
					.$draw()
					.resource(name = "pigeon,pudding")
					.end()

				expect(application.wheels.routes).toHaveLength(28)
			})

			it("resource throws error with list and nesting", () => {
				expect(function() {
					$mapper().$draw().resource(name="pigeon,pudding", nested=true).end()
				}).toThrow("Wheels.InvalidResource")
			})

			it("resources produces routes", () => {
				mapper
					.$draw()
					.resources(name = "pigeons")
					.end()

				expect(application.wheels.routes).toHaveLength(16)
			})

			it("resources produces routes without format", () => {
				mapper
					.$draw()
					.resources(name = "pigeons", mapFormat = false)
					.end()

				expect(application.wheels.routes).toHaveLength(8)
			})

			it("resources produces routes without format set by mapper", () => {
				mapper = $mapper(mapFormat = false)
				mapper
					.$draw()
					.resources(name = "pigeons")
					.end()

				expect(application.wheels.routes).toHaveLength(8)
			})

			it("resources produces routes without format set by mapper override", () => {
				mapper = $mapper(mapFormat = false)
				mapper
					.$draw()
					.resources(name = "pigeons", mapFormat = true)
					.end()

				expect(application.wheels.routes).toHaveLength(16)
			})

			it("resources produces routes with list", () => {
				mapper
					.$draw()
					.resources(name = "pigeons,birds")
					.end()

				expect(application.wheels.routes).toHaveLength(32)
			})

			it("resources produces routes with list without format", () => {
				mapper
					.$draw()
					.resources(name = "pigeons,birds", mapFormat = false)
					.end()

				expect(application.wheels.routes).toHaveLength(16)
			})

			it("resources produces no routes with only empty", () => {
				mapper
					.$draw()
					.resources(name = "pigeons", mapFormat = false, only = "")
					.end()

				expect(application.wheels.routes).toHaveLength(0)
			})

			it("resources produces no routes with only empty nested", () => {
				mapper
					.$draw()
					.resources(name = "pigeons", mapFormat = false, only = "", nested = true)
					.resources(name = "birds", mapFormat = false)
					.end()
					.end()

				expect(application.wheels.routes).toHaveLength(8)
			})

			it("resources throws error with list and nesting", () => {
				expect(function() {
					$mapper().$draw().resources(name="pigeon,birds", nested=true).end()
				}).toThrow("Wheels.InvalidResource")
			})
		})

		describe("Tests that root", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("is excluding format on top level but keeps it on sub level", () => {
				$mapper()
					.$draw()
					.namespace("test")
					.root(to = "test##test")
					.end()
					.root(to = "test##test")
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/test.[format]")
				expect(application.wheels.routes[2].pattern).toBe("/test")
				expect(application.wheels.routes[3].pattern).toBe("/")
			})

			it("is overriding default for map format", () => {
				$mapper()
					.$draw()
					.namespace("test")
					.root(to = "test##test", mapFormat = false)
					.end()
					.root(to = "test##test", mapFormat = true)
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/test")
				expect(application.wheels.routes[2].pattern).toBe("/.[format]")
				expect(application.wheels.routes[3].pattern).toBe("/")
			})
		})

		describe("Tests that utility function", () => {

			beforeEach(() => {
				mapper = $mapper()
			})

			it("compileregex is compiling successfully", () => {
				pattern = "[controller]/[action]/[key]"
				regex = mapper.$patternToRegex(pattern = pattern)
				output = mapper.$compileRegex(regex = regex, pattern = pattern)

				expect(variables).notToHaveKey("output")
			})

			it("compileregex is compiling with error", () => {
				pattern = "[controller]/[action]/[key]"

				expect(function() {
					mapper.$compileRegex(regex="*", pattern="*")
				}).toThrow("Wheels.InvalidRegex")
			})

			it("normalizePattern is working with no starting slash", () => {
				urlString = "controller/action"
				newString = mapper.$normalizePattern(urlString)

				expect(newString).toBe("/controller/action")
			})

			it("normalizePattern is working with double slash and no starting slash", () => {
				urlString = "controller//action"
				newString = mapper.$normalizePattern(urlString)

				expect(newString).toBe("/controller/action")
			})

			it("normalizePattern is working with ending slash and no starting slash", () => {
				urlString = "controller/action/"
				newString = mapper.$normalizePattern(urlString)

				expect(newString).toBe("/controller/action")
			})

			it("normalizePattern is working with slashes everywhere with format", () => {
				urlString = "////controller///action///.asdf/////"
				newString = mapper.$normalizePattern(urlString)

				expect(newString).toBe("/controller/action.asdf")
			})

			it("normalizePattern is working with single quote in pattern", () => {
				urlString = "////controller///action///.asdf'"
				newString = mapper.$normalizePattern(urlString)

				expect(newString).toBe("/controller/action.asdf'")
			})

			it("patternToRegex is working with root", () => {
				pattern = "/"
				regex = mapper.$patternToRegex(pattern)

				expect(regex).toBe("^\/?$")
				expect(validateRegexPattern(regex)).toBeTrue()
			})

			it("patternToRegex is working with root with format", () => {
				pattern = "/.[format]"
				regex = mapper.$patternToRegex(pattern)

				expect(regex).toBe("^\.(\w+)\/?$")
				expect(validateRegexPattern(regex)).toBeTrue()
			})

			it("patternToRegex is working with basic catch all patterns", () => {
				pattern = "/[controller]/[action]/[key].[format]"
				regex = mapper.$patternToRegex(pattern)

				expect(regex).toBe("^([^\/]+)\/([^\.\/]+)\/([^\.\/]+)\.(\w+)\/?$")
				expect(validateRegexPattern(regex)).toBeTrue()
			})

			it("stripRouteVariables is working with no variables", () => {
				pattern = "/"
				varList = mapper.$stripRouteVariables(pattern)

				expect(varList).toBe("")
			})

			it("stripRouteVariables is working with root with format", () => {
				pattern = "/.[format]"
				varList = mapper.$stripRouteVariables(pattern)

				expect(varList).toBe("format")
			})

			it("stripRouteVariables is working with basic catch all pattern", () => {
				pattern = "/[controller]/[action]/[key].[format]"
				varList = mapper.$stripRouteVariables(pattern)

				expect(varList).toBe("controller,action,key,format")
			})

			it("stripRouteVariables is working with nested restful route", () => {
				pattern = "/posts(/[id](/comments(/[commentid](.[format]))))"
				varList = mapper.$stripRouteVariables(pattern)

				expect(varList).toBe("id,commentid,format")
			})
		})

		describe("Tests that wildcard", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("produces routes by default", () => {
				$mapper()
					.$draw()
					.wildcard()
					.end();

				expect(application.wheels.routes).toHaveLength(2)
			})

			it("only allows GET requests by default", () => {
				$mapper()
					.$draw()
					.wildcard()
					.end();

				for (loc.route in application.wheels.routes) {
					expect(loc.route.methods).toBe("get")
				}
			})

			it("generates correct patterns by default", () => {
				$mapper()
					.$draw()
					.wildcard()
					.end();

				expect(application.wheels.routes[1].pattern).toBe("/[controller]/[action]")
				expect(application.wheels.routes[2].pattern).toBe("/[controller]")
			})

			it("produces routes with methods", () => {
				$mapper()
					.$draw()
					.wildcard(methods = "get,post")
					.end();

				expect(application.wheels.routes).toHaveLength(4)
			})

			it("only allows specified methods", () => {
				$mapper()
					.$draw()
					.wildcard(methods = "put")
					.end();

				for (loc.route in application.wheels.routes) {
					expect(loc.route.methods).toBe("put")
				}
			})

			it("generates correct patterns with methods", () => {
				$mapper()
					.$draw()
					.wildcard(methods = "get,post")
					.end();

				expect(application.wheels.routes[1].pattern).toBe("/[controller]/[action]")
				expect(application.wheels.routes[2].pattern).toBe("/[controller]")
				expect(application.wheels.routes[3].pattern).toBe("/[controller]/[action]")
				expect(application.wheels.routes[4].pattern).toBe("/[controller]")
			})

			it("produces routes with controller scope", () => {
				$mapper()
					.$draw()
					.controller("cats")
					.wildcard()
					.end()
					.end();

				expect(application.wheels.routes).toHaveLength(2)
			})

			it("only allows GET requests with controller scope", () => {
				$mapper()
					.$draw()
					.controller("cats")
					.wildcard()
					.end()
					.end();

				for (loc.route in application.wheels.routes) {
					expect(loc.route.methods).toBe("get")
				}
			})

			it("generates correct patterns with controller scope", () => {
				$mapper()
					.$draw()
					.controller("cats")
					.wildcard()
					.end()
					.end();

				expect(application.wheels.routes[1].pattern).toBe("/cats/[action]")
				expect(application.wheels.routes[2].pattern).toBe("/cats")
			})

			it("works with map format", () => {
				$mapper()
					.$draw()
					.controller("cats")
					.wildcard(mapFormat = true)
					.end()
					.end();

				expect(application.wheels.routes[1].pattern).toBe("/cats/[action].[format]")
				expect(application.wheels.routes[2].pattern).toBe("/cats/[action]")
				expect(application.wheels.routes[3].pattern).toBe("/cats.[format]")
				expect(application.wheels.routes[4].pattern).toBe("/cats")
				expect(application.wheels.routes).toHaveLength(4)
			})

			it("works with map key", () => {
				$mapper()
					.$draw()
					.controller("cats")
					.wildcard(mapKey = true)
					.end()
					.end();

				expect(application.wheels.routes[1].pattern).toBe("/cats/[action]/[key]")
				expect(application.wheels.routes[2].pattern).toBe("/cats/[action]")
				expect(application.wheels.routes[3].pattern).toBe("/cats")
				expect(application.wheels.routes).toHaveLength(3)
			})
		})
	}

	public struct function $mapper() {
		local.args = Duplicate(config)
		StructAppend(local.args, arguments, true)
		return application.wo.$createObjectFromRoot(argumentCollection = local.args)
	}

	public struct function $inspect() {
		return variables
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
	}

	public boolean function validateRegexPattern(required string pattern) {
		try {
			local.jPattern = CreateObject("java", "java.util.regex.Pattern").compile(arguments.pattern)
		} catch (any e) {
			return false
		}

		return true
	}
}