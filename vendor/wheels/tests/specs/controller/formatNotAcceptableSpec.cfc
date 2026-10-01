/**
 * A request for a format the action does not provide (an explicit `format`
 * param, normally from the route's `.[format]` segment, e.g. GET /posts/2.json
 * on a controller that only provides html) must answer 406 Not Acceptable.
 * It used to skip rendering and return 200 with an empty body.
 *
 * The `test` asset controller provides html,xml,json,xls and its `test`
 * action has test.cfm, test.json.cfm, test.xml.cfm and test.pdf.cfm views.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Requesting a format the action does not provide", () => {

			beforeEach(() => {
				// Reset to a sentinel so an earlier spec's status cannot mask a regression.
				application.wo.$header(statusCode = 200)
				_savedShowError = application.wheels.showErrorInformation
			})

			afterEach(() => {
				application.wheels.showErrorInformation = _savedShowError
				application.wo.$header(statusCode = 200)
				application.wo.$header(name = "content-type", value = "text/html", charset = "utf-8")
			})

			it("throws Wheels.FormatNotAcceptable with status 406 from $callAction", () => {
				params = {controller = "test", action = "test", format = "csv"}
				_controller = application.wo.controller("test", params)

				expect(function() {
					_controller.$callAction(action = "test")
				}).toThrow("Wheels.FormatNotAcceptable")
				expect(application.wo.$statusCode()).toBe(406)
			})

			it("answers 406 even when a view template exists for the unprovided format", () => {
				// test.pdf.cfm exists, but the controller does not provide pdf.
				params = {controller = "test", action = "test", format = "pdf"}
				_controller = application.wo.controller("test", params)

				expect(function() {
					_controller.$callAction(action = "test")
				}).toThrow("Wheels.FormatNotAcceptable")
				expect(application.wo.$statusCode()).toBe(406)
			})

			it("answers 406 for a format excluded by onlyProvides", () => {
				params = {controller = "dummy", action = "noViewAction", format = "xml"}
				_controller = application.wo.controller("dummy", params)
				_controller.noViewAction = function() {
				}
				_controller.onlyProvides(formats = "json", action = "noViewAction")
				var state = {type = ""}
				try {
					_controller.$callAction(action = "noViewAction")
				} catch (any e) {
					state.type = e.type
				} finally {
					// Controller class data is cached and shared across specs.
					StructDelete(_controller.$getControllerClassData().formats.actions, "noViewAction")
				}

				expect(state.type).toBe("Wheels.FormatNotAcceptable")
				expect(application.wo.$statusCode()).toBe(406)
			})

			it("answers 406 for a provided json format the action never renders", () => {
				// The test controller provides json, but testResolved has no json
				// template and does not call renderWith(), so nothing is rendered.
				params = {controller = "test", action = "testResolved", format = "json"}
				_controller = application.wo.controller("test", params)

				expect(function() {
					_controller.$callAction(action = "testResolved")
				}).toThrow("Wheels.FormatNotAcceptable")
				expect(application.wo.$statusCode()).toBe(406)
			})

			it("rethrows the typed error from processAction in development", () => {
				application.wheels.showErrorInformation = true
				params = {controller = "test", action = "test", format = "csv"}
				_controller = application.wo.controller("test", params)

				expect(function() {
					_controller.processAction()
				}).toThrow("Wheels.FormatNotAcceptable")
				expect(application.wo.$statusCode()).toBe(406)
			})

			it("renders a non-empty 406 response from processAction in production", () => {
				application.wheels.showErrorInformation = false
				params = {controller = "test", action = "test", format = "csv"}
				_controller = application.wo.controller("test", params)
				_controller.processAction()

				expect(application.wo.$statusCode()).toBe(406)
				expect(_controller.response()).toInclude("Not Acceptable")
			})
		})

		describe("Requesting html or a provided format", () => {

			beforeEach(() => {
				application.wo.$header(statusCode = 200)
			})

			afterEach(() => {
				application.wo.$header(statusCode = 200)
				application.wo.$header(name = "content-type", value = "text/html", charset = "utf-8")
			})

			it("renders the html view when no format is requested", () => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
				_controller.$callAction(action = "test")

				expect(application.wo.$statusCode()).toBe(200)
				expect(_controller.response()).toInclude("variableForViewContent")
			})

			it("renders the html view when format=html is requested", () => {
				params = {controller = "test", action = "test", format = "html"}
				_controller = application.wo.controller("test", params)
				_controller.$callAction(action = "test")

				expect(application.wo.$statusCode()).toBe(200)
				expect(_controller.response()).toInclude("variableForViewContent")
			})

			it("does not 406 a provided json format on the automatic render", () => {
				params = {controller = "test", action = "test", format = "json"}
				_controller = application.wo.controller("test", params)
				_controller.$callAction(action = "test")

				expect(application.wo.$statusCode()).toBe(200)
			})

			it("renders a provided json format through renderWith", () => {
				params = {controller = "test", action = "test", format = "json"}
				_controller = application.wo.controller("test", params)
				_controller.renderWith(data = {a = 1})

				expect(application.wo.$statusCode()).toBe(200)
				expect(_controller.response()).toInclude("json template content")
			})

			it("does not 406 when the format comes from the Accept header", () => {
				// Only an explicit format param is a hard request. Accept-header
				// negotiation is left as it was.
				var savedAccept = request.cgi.http_accept
				try {
					request.cgi.http_accept = "text/csv"
					params = {controller = "test", action = "test"}
					_controller = application.wo.controller("test", params)
					_controller.$callAction(action = "test")
				} finally {
					request.cgi.http_accept = savedAccept
				}

				expect(application.wo.$statusCode()).toBe(200)
			})
		})
	}

}
