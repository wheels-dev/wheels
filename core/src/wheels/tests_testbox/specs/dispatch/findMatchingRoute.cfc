component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		_originalRoutes = Duplicate(application.wheels.routes)
		application.wheels.routes = []

		application.wo.mapper()
			.namespace("admin")
			.resources("users")
			.root(to = "dashboard##index")
			.end()
			.resources("users")
			.resource("profile")
			.root(to = "dashboard##index")
			.end()

		d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes
	}

	function run() {
		
		describe("Tests that $findMatchingRoute", () => {

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

			it("raises error when route not found", () => {
				expect(function() {
					d.$findMatchingRoute(path="scouts")
				}).toThrow("Wheels.RouteNotFound")
			})

			it("finds GET collection route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users")

				expect(route.name).toBe("users")
				expect(route.methods).toBe("GET")
			})

			it("finds GET collection route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users.csv")

				expect(route.name).toBe("users")
				expect(route.methods).toBe("GET")
			})

			it("finds POST collection route that exists", () => {
				request.cgi["request_method"] = "POST"
				route = d.$findMatchingRoute(path = "users")

				expect(route.name).toBe("users")
				expect(route.methods).toBe("POST")
			})

			it("finds POST collection route that exists with format", () => {
				request.cgi["request_method"] = "POST"
				route = d.$findMatchingRoute(path = "users.json")

				expect(route.name).toBe("users")
				expect(route.methods).toBe("POST")
			})

			it("finds GET member new route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/new")

				expect(route.name).toBe("newUser")
				expect(route.methods).toBe("GET")
			})

			it("finds GET member new route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/new.json")

				expect(route.name).toBe("newUser")
				expect(route.methods).toBe("GET")
			})

			it("finds GET member edit route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/1/edit")

				expect(route.name).toBe("editUser")
				expect(route.methods).toBe("GET")
			})

			it("finds GET member edit route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/1/edit.json")

				expect(route.name).toBe("editUser")
				expect(route.methods).toBe("GET")
			})

			it("finds GET member route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/1")

				expect(route.name).toBe("user")
				expect(route.methods).toBe("GET")
			})

			it("finds GET member route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "users/1.json")

				expect(route.name).toBe("user")
				expect(route.methods).toBe("GET")
			})
			
			it("finds PUT member route that exists", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PUT"
				route = d.$findMatchingRoute(path = "users/1")

				expect(route.name).toBe("user")
				expect(route.methods).toBe("PUT")
			})

			it("finds PUT member route that exists with format", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PUT"
				route = d.$findMatchingRoute(path = "users/1.json")

				expect(route.name).toBe("user")
				expect(route.methods).toBe("PUT")
			})
			
			it("finds DELETE member route that exists", () => {
				request.cgi["request_method"] = "POST"
				form._method = "delete"
				route = d.$findMatchingRoute(path = "users/1")

				expect(route.name).toBe("user")
				expect(route.methods).toBe("delete")
			})

			it("finds DELETE member route that exists with format", () => {
				request.cgi["request_method"] = "POST"
				form._method = "delete"
				route = d.$findMatchingRoute(path = "users/1.json")

				expect(route.name).toBe("user")
				expect(route.methods).toBe("delete")
			})
			
			it("finds nested GET collection route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users")

				expect(route.name).toBe("adminUsers")
				expect(route.methods).toBe("get")
			})

			it("finds nested GET collection route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users.csv")

				expect(route.name).toBe("adminUsers")
				expect(route.methods).toBe("get")
			})
			
			it("finds nested POST collection route that exists", () => {
				request.cgi["request_method"] = "POST"
				route = d.$findMatchingRoute(path = "admin/users")

				expect(route.name).toBe("adminUsers")
				expect(route.methods).toBe("POST")
			})

			it("finds nested POST collection route that exists with format", () => {
				request.cgi["request_method"] = "POST"
				route = d.$findMatchingRoute(path = "admin/users.json")

				expect(route.name).toBe("adminUsers")
				expect(route.methods).toBe("POST")
			})
			
			it("finds nested GET member new route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/new")

				expect(route.name).toBe("newAdminUser")
				expect(route.methods).toBe("GET")
			})

			it("finds nested GET member new route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/new.json")

				expect(route.name).toBe("newAdminUser")
				expect(route.methods).toBe("GET")
			})
			
			it("finds nested GET member edit route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/1/edit")

				expect(route.name).toBe("editAdminUser")
				expect(route.methods).toBe("GET")
			})

			it("finds nested GET member edit route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/1/edit.json")

				expect(route.name).toBe("editAdminUser")
				expect(route.methods).toBe("GET")
			})
			
			it("finds nested GET member route that exists", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/1")

				expect(route.name).toBe("adminUser")
				expect(route.methods).toBe("GET")
			})

			it("finds nested GET member route that exists with format", () => {
				request.cgi["request_method"] = "GET"
				route = d.$findMatchingRoute(path = "admin/users/1.json")

				expect(route.name).toBe("adminUser")
				expect(route.methods).toBe("GET")
			})

			it("finds nested PUT member route that exists", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PUT"
				route = d.$findMatchingRoute(path = "admin/users/1")

				expect(route.name).toBe("adminUser")
				expect(route.methods).toBe("PUT")
			})

			it("finds nested PUT member route that exists with format", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PUT"
				route = d.$findMatchingRoute(path = "admin/users/1.json")

				expect(route.name).toBe("adminUser")
				expect(route.methods).toBe("PUT")
			})

			it("finds nested DELETE member route that exists", () => {
				request.cgi["request_method"] = "POST"
				form._method = "delete"
				route = d.$findMatchingRoute(path = "admin/users/1")

				expect(route.name).toBe("adminUser")
				expect(route.methods).toBe("delete")
			})

			it("finds nested DELETE member route that exists with format", () => {
				request.cgi["request_method"] = "POST"
				form._method = "delete"
				route = d.$findMatchingRoute(path = "admin/users/1.json")

				expect(route.name).toBe("adminUser")
				expect(route.methods).toBe("delete")
			})

			it("gets HEAD request aliases", () => {
				request.cgi["request_method"] = "HEAD"
				route = d.$findMatchingRoute(path = "users")

				expect(route.name).toBe("users")
				expect(route.methods).toBe("get")
			})
		})
	}
}