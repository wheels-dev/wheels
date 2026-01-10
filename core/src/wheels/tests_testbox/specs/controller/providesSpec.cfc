component extends="wheels.Testbox" {

	function run() {

		describe("Tests that $requestcontenttype", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				$$oldCGIScope = request.cgi
			})

			afterEach(() => {
				request.cgi = $$oldCGIScope
			})

			it("gets header cgi html", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "text/html"

				expect(_controller.$requestContentType()).toBe("html")
			})

			it("gets params html", () => {
				params.format = "html"
				_controller = application.wo.controller("dummy", params)

				expect(_controller.$requestContentType()).toBe("html")
			})

			it("gets header cgi xml", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "text/xml"

				expect(_controller.$requestContentType()).toBe("xml")
			})

			it("gets params xml", () => {
				params.format = "xml"
				_controller = application.wo.controller("dummy", params)

				expect(_controller.$requestContentType()).toBe("xml")
			})

			it("gets header cgi json", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "application/json"

				expect(_controller.$requestContentType()).toBe("json")
			})

			it("gets header cgi json and js", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "application/json, application/javascript"

				expect(_controller.$requestContentType()).toBe("json")
			})

			it("gets params json", () => {
				params.format = "json"
				_controller = application.wo.controller("dummy", params)

				expect(_controller.$requestContentType()).toBe("json")
			})

			it("gets header cgi csv", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "text/csv"

				expect(_controller.$requestContentType()).toBe("csv")
			})

			it("gets params csv", () => {
				params.format = "csv"
				_controller = application.wo.controller("dummy", params)

				expect(_controller.$requestContentType()).toBe("csv")
			})

			it("gets header cgi xls", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "application/vnd.ms-excel"

				expect(_controller.$requestContentType()).toBe("xls")
			})

			it("gets params xls", () => {
				params.format = "xls"
				_controller = application.wo.controller("dummy", params)

				expect(_controller.$requestContentType()).toBe("xls")
			})

			it("gets header cgi pdf", () => {
				_controller = application.wo.controller("dummy", params)
				request.cgi.http_accept = "application/pdf"

				expect(_controller.$requestContentType()).toBe("pdf")
			})

			it("gets params pdf", () => {
				params.format = "pdf"
				_controller = application.wo.controller("dummy", params)

				expect(_controller.$requestContentType()).toBe("pdf")
			})
		})

		describe("Tests that initialization", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "dummy"}
				_controller = application.wo.controller("dummy", params)
			})

			it("provides sets controller class data", () => {
				formats = "json,xml,csv"
				_controller.provides(formats = formats)
				expected = "html,#formats#"

				expect(_controller.$getControllerClassData().formats.default).toBe(expected)
			})

			it("only provides sets controller class data", () => {
				formats = "html"
				_controller.onlyProvides(formats = "html")

				expect(_controller.$getControllerClassData().formats.actions.dummy).toBe(formats)
				
			})
		})
	}
}