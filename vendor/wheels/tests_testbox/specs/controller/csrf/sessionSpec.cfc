component extends="wheels.Testbox" {

	function run() {

		describe("Tests CSRFProtectedExcept on PATCH request", () => {

			beforeEach(() => {
				$oldCsrfStore = application.wheels.csrfStore
				$oldRequestMethod = request.cgi.request_method
				$oldHttpXRequestedWith = request.cgi.http_x_requested_with
				application.wheels.csrfStore = "session"
				request.cgi.request_method = "PATCH"
				csrfToken = CsrfGenerateToken()
			})

			afterEach(() => {
				application.wheels.csrfStore = $oldCsrfStore
				request.cgi.request_method = $oldRequestMethod
				request.cgi.http_x_requested_with = $oldHttpXRequestedWith
				StructDelete(request.$wheelsHeaders, "X-CSRF-TOKEN")
			})

			it("performs csrf protection with valid authenticityToken", () => {
				params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = csrfToken}

				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)

				expect(_controller.response()).toBe("Update ran.")
			})

			it("performs csrf protection with no authenticityToken", () => {
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("performs csrf protection with invalid authenticityToken", () => {
				params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("performs csrf protection on ajax with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Update ran.")
			})
			
			it("performs csrf protection on ajax with no x csrf token header", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("performs csrf protection on ajax with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("skips csrf protection with valid authenticityToken", () => {
				params = {controller = "csrfProtectedExcept", action = "show", authenticityToken = csrfToken}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Show ran.")
			})
			
			it("skips csrf protection with no authenticityToken", () => {
				params = {controller = "csrfProtectedExcept", action = "show"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Show ran.")
			})
			
			it("skips csrf protection with invalid authenticityToken", () => {
				params = {controller = "csrfProtectedExcept", action = "show", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Show ran.")
			})
			
			it("skips csrf protection on ajax with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedExcept", action = "show"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Show ran.")
			})
			
			it("skips csrf protection on ajax with no x csrf token header", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedExcept", action = "show"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Show ran.")
			})
			
			it("skips csrf protection on ajax with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedExcept", action = "show"}
				_controller = application.wo.controller("csrfProtectedExcept", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Show ran.")
			})
		})

		describe("Tests CsrfProtectedOnly on POST request", () => {

			beforeEach(() => {
				$oldCsrfStore = application.wheels.csrfStore
				$oldRequestMethod = request.cgi.request_method
				$oldHttpXRequestedWith = request.cgi.http_x_requested_with
				application.wheels.csrfStore = "session"
				request.cgi.request_method = "POST"
				csrfToken = CsrfGenerateToken()
			})

			afterEach(() => {
				application.wheels.csrfStore = $oldCsrfStore
				request.cgi.request_method = $oldRequestMethod
				request.cgi.http_x_requested_with = $oldHttpXRequestedWith
				StructDelete(request.$wheelsHeaders, "X-CSRF-TOKEN")
			})

			it("performs csrf protection with valid authenticityToken", () => {
				params = {controller = "CsrfProtectedOnly", action = "create", authenticityToken = csrfToken}

				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)

				expect(_controller.response()).toBe("Create ran.")
			})

			it("performs csrf protection with no authenticityToken", () => {
				params = {controller = "CsrfProtectedOnly", action = "create"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("performs csrf protection with invalid authenticityToken", () => {
				params = {controller = "CsrfProtectedOnly", action = "create", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("performs csrf protection on ajax with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "CsrfProtectedOnly", action = "create"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Create ran.")
			})
			
			it("performs csrf protection on ajax with no x csrf token header", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "CsrfProtectedOnly", action = "create"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("performs csrf protection on ajax with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "CsrfProtectedOnly", action = "create"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
			
			it("skips csrf protection with valid authenticityToken", () => {
				params = {controller = "CsrfProtectedOnly", action = "index", authenticityToken = csrfToken}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Index ran.")
			})
			
			it("skips csrf protection with no authenticityToken", () => {
				params = {controller = "CsrfProtectedOnly", action = "index"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Index ran.")
			})
			
			it("skips csrf protection with invalid authenticityToken", () => {
				params = {controller = "CsrfProtectedOnly", action = "index", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Index ran.")
			})
			
			it("skips csrf protection on ajax with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "CsrfProtectedOnly", action = "index"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Index ran.")
			})
			
			it("skips csrf protection on ajax with no x csrf token header", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "CsrfProtectedOnly", action = "index"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Index ran.")
			})
			
			it("skips csrf protection on ajax with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "CsrfProtectedOnly", action = "index"}
				_controller = application.wo.controller("CsrfProtectedOnly", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Index ran.")
			})
		})
		
		describe("Tests CsrfProtectedWithException", () => {
			
			beforeEach(() => {
				$oldCsrfStore = application.wheels.csrfStore
				$oldRequestMethod = request.cgi.request_method
				$oldHttpXRequestedWith = request.cgi.http_x_requested_with
				application.wheels.csrfStore = "session"
				csrfToken = CsrfGenerateToken()
			})

			afterEach(() => {
				application.wheels.csrfStore = $oldCsrfStore
				request.cgi.request_method = $oldRequestMethod
				request.cgi.http_x_requested_with = $oldHttpXRequestedWith
				StructDelete(request.$wheelsHeaders, "X-CSRF-TOKEN")
			})

			it("skips csrf protection on GET request", () => {
				params = {controller = "csrfProtectedWithException", action = "index"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("index", params)
				expect(_controller.response()).toBe("Index ran.")
			})

			it("skips csrf protection on GET ajax request", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "index"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("index", params)
				expect(_controller.response()).toBe("Index ran.")
			})

			it("skips csrf protection on OPTIONS request", () => {
				request.cgi.request_method = "OPTIONS"
				params = {controller = "csrfProtectedWithException", action = "index"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("index", params)
				expect(_controller.response()).toBe("Index ran.")
			})

			it("skips csrf protection on OPTIONS ajax request", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				request.cgi.request_method = "OPTIONS"
				params = {controller = "csrfProtectedWithException", action = "index"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("index", params)
				expect(_controller.response()).toBe("Index ran.")
			})

			it("skips csrf protection on HEAD request", () => {
				request.cgi.request_method = "HEAD"
				params = {controller = "csrfProtectedWithException", action = "index"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("index", params)
				expect(_controller.response()).toBe("Index ran.")
			})

			it("skips csrf protection on HEAD ajax request", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				request.cgi.request_method = "HEAD"
				params = {controller = "csrfProtectedWithException", action = "index"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("index", params)
				expect(_controller.response()).toBe("Index ran.")
			})

			it("performs csrf protection on POST request with valid authenticityToken", () => {
				request.cgi.request_method = "POST"
				params = {controller = "csrfProtectedWithException", action = "create", authenticityToken = csrfToken}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Create ran.")
			})

			it("performs csrf protection on POST request with no authenticityToken", () => {
				request.cgi.request_method = "POST"
				params = {controller = "csrfProtectedWithException", action = "create"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on POST request with invalid authenticityToken", () => {
				request.cgi.request_method = "POST"
				params = {controller = "csrfProtectedWithException", action = "create", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on PATCH request with valid authenticityToken", () => {
				request.cgi.request_method = "PATCH"
				params = {controller = "csrfProtectedWithException", action = "update", authenticityToken = csrfToken}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Update ran.")
			})

			it("performs csrf protection on PATCH request with no authenticityToken", () => {
				request.cgi.request_method = "PATCH"
				params = {controller = "csrfProtectedWithException", action = "update"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on PATCH request with invalid authenticityToken", () => {
				request.cgi.request_method = "PATCH"
				params = {controller = "csrfProtectedWithException", action = "update", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on DELETE request with valid authenticityToken", () => {
				request.cgi.request_method = "DELETE"
				params = {controller = "csrfProtectedWithException", action = "delete", authenticityToken = csrfToken}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("delete", params)
				expect(_controller.response()).toBe("Delete ran.")
			})

			it("performs csrf protection on DELETE request with no authenticityToken", () => {
				request.cgi.request_method = "DELETE"
				params = {controller = "csrfProtectedWithException", action = "delete"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("delete", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on DELETE request with invalid authenticityToken", () => {
				request.cgi.request_method = "DELETE"
				params = {controller = "csrfProtectedWithException", action = "delete", authenticityToken = "#csrfToken#1"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("delete", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on ajax POST request with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.request_method = "POST"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "create"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("create", params)
				expect(_controller.response()).toBe("Create ran.")
			})

			it("performs csrf protection on ajax POST request with no x csrf token header", () => {
				request.cgi.request_method = "POST"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "create"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on ajax POST request with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.request_method = "POST"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "create"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("create", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on ajax PATCH request with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.request_method = "PATCH"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "update"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Update ran.")
			})

			it("performs csrf protection on ajax PATCH request with no x csrf token header", () => {
				request.cgi.request_method = "PATCH"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "update"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on ajax PATCH request with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.request_method = "PATCH"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "update"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("update", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on ajax DELETE request with valid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				request.cgi.request_method = "DELETE"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "delete"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				_controller.processAction("delete", params)
				expect(_controller.response()).toBe("Delete ran.")
			})

			it("performs csrf protection on ajax DELETE request with no x csrf token header", () => {
				request.cgi.request_method = "DELETE"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "delete"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("delete", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})

			it("performs csrf protection on ajax DELETE request with invalid x csrf token header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1"
				request.cgi.request_method = "DELETE"
				request.cgi.http_x_requested_with = "XMLHTTPRequest"
				params = {controller = "csrfProtectedWithException", action = "delete"}
				_controller = application.wo.controller("csrfProtectedWithException", params)

				try {
					_controller.processAction("delete", params)
				} catch (any e) {
					type = e.Type
					expect(type).toBe("Wheels.InvalidAuthenticityToken")
				}
			})
		})
	}
}