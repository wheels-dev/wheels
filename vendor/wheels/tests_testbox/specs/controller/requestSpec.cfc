component extends="wheels.Testbox" {

	function beforeAll() {
		$$oldCGIScope = request.cgi
		params = {controller = "dummy", action = "dummy"}
		_controller = application.wo.controller("dummy", params)
	}

	function afterAll() {
		request.cgi = $$oldCGIScope
	}

	function run() {

		describe("Tests that isAjax", () => {

			it("is valid", () => {
				request.cgi.http_x_requested_with = "XMLHTTPRequest"

				expect(_controller.isAjax()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.http_x_requested_with = ""

				expect(_controller.isAjax()).toBeFalse()
			})
		})

		describe("Tests that isDelete", () => {

			it("is valid", () => {
				request.cgi.request_method = "delete"

				expect(_controller.isDelete()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isDelete()).toBeFalse()
			})
		})

		describe("Tests that isGet", () => {

			it("is valid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isGet()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = ""

				expect(_controller.isGet()).toBeFalse()
			})
		})

		describe("Tests that isHead", () => {

			it("is valid", () => {
				request.cgi.request_method = "head"

				expect(_controller.isHead()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isHead()).toBeFalse()
			})
		})

		describe("Tests that isOptions", () => {

			it("is valid", () => {
				request.cgi.request_method = "options"

				expect(_controller.isOptions()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isOptions()).toBeFalse()
			})
		})

		describe("Tests that isPatch", () => {

			it("is valid", () => {
				request.cgi.request_method = "patch"

				expect(_controller.isPatch()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isPatch()).toBeFalse()
			})
		})

		describe("Tests that isPost", () => {

			it("is valid", () => {
				request.cgi.request_method = "post"

				expect(_controller.isPost()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isPost()).toBeFalse()
			})
		})

		describe("Tests that isPut", () => {

			it("is valid", () => {
				request.cgi.request_method = "put"

				expect(_controller.isPut()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.request_method = "get"

				expect(_controller.isPut()).toBeFalse()
			})
		})

		describe("Tests that isSecure", () => {

			it("is valid", () => {
				request.cgi.server_port_secure = "yes"

				expect(_controller.isSecure()).toBeTrue()
			})

			it("is invalid", () => {
				request.cgi.server_port_secure = ""

				expect(_controller.isSecure()).toBeFalse()

				request.cgi.server_port_secure = "no"

				expect(_controller.isSecure()).toBeFalse()
			})
		})

		describe("Tests that pagination", () => {

			beforeEach(() => {
				request.wheels["myhandle"] = {test = "true"}
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
			})

			afterEach(() => {
				StructDelete(request.wheels, "myhandle", false)
			})
			
			it("handle exists", () => {
				actual = _controller.pagination('myhandle')

				expect(actual).toBeStruct()
				expect(actual).toHaveKey("test")
				expect(actual.test).toBeTrue()
			})

			it("handle does not exist", () => {
				expect(function() {
					_controller.pagination("someotherhandle")
				}).toThrow("Wheels.QueryHandleNotFound")
			})
		})
	}
}