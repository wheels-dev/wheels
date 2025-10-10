component extends="wheels.Testbox" {

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

				expect(_controller.$abortIssued()).toBeTrue()
				expect(_controller.$performedRenderOrRedirect()).toBeFalse()
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
		})
	}
}