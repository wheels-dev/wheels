component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that verifies", () => {

			beforeEach(() => {
				$savedenv = Duplicate(request.cgi)
			})

			afterEach(() => {
				request.cgi = $savedenv
			})

			it("is valid", () => {
				request.cgi.request_method = "get"
				params = {controller = "verifies", action = "actionGet"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionGet", params)

				expect(_controller.response()).toBe("actionGet")
			})

			it("aborts invalid", () => {
				request.cgi.request_method = "post"
				params = {controller = "verifies", action = "actionGet"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionGet", params)

				// A failed verification without a handler/redirect now ends the
				// request with a 400 (previously it was a silent abort with no render).
				expect(_controller.$abortIssued()).toBeTrue()
				expect(_controller.$statusCode()).toBe(400)
			})

			it("redirects invalid", () => {
				request.cgi.request_method = "get"
				params = {controller = "verifies", action = "actionPostWithRedirect"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithRedirect", params)

				expect(_controller.$abortIssued()).toBeFalse()
				expect(_controller.$performedRenderOrRedirect()).toBeTrue()
				expect(_controller.getRedirect().$args.action).toBe("index")
				expect(_controller.getRedirect().$args.controller).toBe("somewhere")
				expect(_controller.getRedirect().$args.error).toBe("invalid")
			})

			it("checks valid types", () => {
				request.cgi.request_method = "post"
				params = {
					controller = "verifies",
					action = "actionPostWithTypesValid",
					userid = "0",
					authorid = "00000000-0000-0000-0000-000000000000"
				}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithTypesValid", params)

				expect(_controller.response()).toBe("actionPostWithTypesValid")
			})

			it("checks invalid types guid", () => {
				request.cgi.request_method = "post"
				params = {controller = "verifies", action = "actionPostWithTypesInValid", userid = "0", authorid = "invalidguid"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithTypesInValid", params)

				expect(_controller.$abortIssued()).toBeTrue()
			})

			it("checks invalid types integer", () => {
				request.cgi.request_method = "post"
				params = {
					controller = "verifies",
					action = "actionPostWithTypesInValid",
					userid = "1.234",
					authorid = "00000000-0000-0000-0000-000000000000"
				}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithTypesInValid", params)

				expect(_controller.$abortIssued()).toBeTrue()
			})

			it("checks that strings allow blank", () => {
				request.cgi.request_method = "post"
				params = {controller = "verifies", action = "actionPostWithString", username = "tony", password = ""}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithString", params)

				expect(_controller.$abortIssued()).toBeFalse()
			})

			it("checks that strings cannot be blank", () => {
				request.cgi.request_method = "post"
				params = {controller = "verifies", action = "actionPostWithString", username = "", password = ""}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithString", params)

				expect(_controller.$abortIssued()).toBeTrue()
			})

			it("returns 400 with an empty body for a failed verification without handler or redirect (html)", () => {
				// A bare abort (no handler, no redirect) previously left a 200 with an
				// empty text/html body for an unmet precondition. It now ends as a 400.
				request.cgi.request_method = "post"
				params = {controller = "verifies", action = "actionGet"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionGet", params)

				expect(_controller.$abortIssued()).toBeTrue()
				expect(_controller.$statusCode()).toBe(400)
				expect(_controller.response()).toBe("")
			})

			it("returns a 400 JSON error body for a json-format failed verification", () => {
				request.cgi.request_method = "post"
				params = {controller = "verifies", action = "actionGet", format = "json"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionGet", params)

				expect(_controller.$abortIssued()).toBeTrue()
				expect(_controller.$statusCode()).toBe(400)
				expect(IsJSON(_controller.response())).toBeTrue()
				expect(_controller.response()).toInclude("error")
			})

			it("leaves the handler branch unchanged (no 400) when a handler is declared", () => {
				// A declared handler owns the failed-verification response; the 400 path
				// must not run. Here the handler redirects, so no abort and no 400.
				request.cgi.request_method = "get"
				params = {controller = "verifies", action = "actionPostWithHandler"}
				_controller = application.wo.controller("verifies", params)
				_controller.processAction("actionPostWithHandler", params)

				// The handler branch never sets the abort flag, so the 400 path is not
				// taken — the handler owns the response (here, a redirect to login).
				// (Status code is request-global in the test runner and leaks between
				// specs, so the abort flag is the reliable discriminator here.)
				expect(_controller.$abortIssued()).toBeFalse()
				expect(_controller.$performedRedirect()).toBeTrue()
				expect(_controller.getRedirect().$args.action).toBe("login")
			})

			it("throws at declaration time when a types list length does not match its variable list", () => {
				params = {controller = "verifies", action = "actionGet"}
				_controller = application.wo.controller("verifies", params)

				expect(function() {
					_controller.verifies(params = "username,password", paramsTypes = "string")
				}).toThrow("Wheels.InvalidVerification")

				expect(function() {
					_controller.verifies(session = "userId", sessionTypes = "integer,string")
				}).toThrow("Wheels.InvalidVerification")

				expect(function() {
					_controller.verifies(post = "true", cookieTypes = "string")
				}).toThrow("Wheels.InvalidVerification")
			})
		})
	}
}