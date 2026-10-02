/**
 * X-CSRF-Token on any non-GET request, and forms inside cached fragments (#3959).
 *
 * The header used to count only with X-Requested-With: XMLHttpRequest, so a
 * fetch()-based client (Turbo, a hand-written fetch) that sends the page's
 * current token in the header, but not X-Requested-With, was refused whenever
 * the form's hidden field was stale (a cached fragment). The token value is the
 * protection; X-Requested-With adds none.
 *
 * Rule when both are present: the request passes if EITHER the form field or
 * the header carries a valid token (Rails' behaviour). A stale field with a
 * valid header passes; a valid field with an invalid header passes too.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("X-CSRF-Token without X-Requested-With (session store, PATCH)", () => {

			beforeEach(() => {
				$oldCsrfStore = application.wheels.csrfStore
				$oldRequestMethod = request.cgi.request_method
				$oldHttpXRequestedWith = request.cgi.http_x_requested_with
				application.wheels.csrfStore = "session"
				request.cgi.request_method = "PATCH"
				request.cgi.http_x_requested_with = ""
				csrfToken = CsrfGenerateToken()
				// Invalid tokens: the valid one with its last character changed.
				badToken = Left(csrfToken, Len(csrfToken) - 1) & (Right(csrfToken, 1) == "A" ? "B" : "A")
				otherBadToken = Left(csrfToken, Len(csrfToken) - 1) & (Right(csrfToken, 1) == "C" ? "D" : "C")
			})

			afterEach(() => {
				application.wheels.csrfStore = $oldCsrfStore
				request.cgi.request_method = $oldRequestMethod
				request.cgi.http_x_requested_with = $oldHttpXRequestedWith
				StructDelete(request.$wheelsHeaders, "X-CSRF-TOKEN")
			})

			it("accepts a valid header with no form field", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Update ran.")
			})

			it("rejects an invalid header with no form field", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = badToken
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				var state = {type = ""}
				try {
					_controller.processAction("update", params)
				} catch (any e) {
					state.type = e.Type
				}
				expect(state.type).toBe("Wheels.InvalidAuthenticityToken")
			})

			it("accepts a stale form field when the header is valid (a cached form)", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken
				params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = "stale-token-from-another-session"}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Update ran.")
			})

			it("accepts a valid form field even when the header is invalid (either one is enough)", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = badToken
				params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = csrfToken}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				_controller.processAction("update", params)
				expect(_controller.response()).toBe("Update ran.")
			})

			it("rejects when both the field and the header are invalid", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = badToken
				params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = otherBadToken}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				var state = {type = ""}
				try {
					_controller.processAction("update", params)
				} catch (any e) {
					state.type = e.Type
				}
				expect(state.type).toBe("Wheels.InvalidAuthenticityToken")
			})

			it("rejects a valid token with extra characters appended, as a form field", () => {
				params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = csrfToken & "x"}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				var state = {type = ""}
				try {
					_controller.processAction("update", params)
				} catch (any e) {
					state.type = e.Type
				}
				expect(state.type).toBe("Wheels.InvalidAuthenticityToken")
			})

			it("rejects a valid token with extra characters appended, as a header", () => {
				request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken & "x"
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				var state = {type = ""}
				try {
					_controller.processAction("update", params)
				} catch (any e) {
					state.type = e.Type
				}
				expect(state.type).toBe("Wheels.InvalidAuthenticityToken")
			})

			it("rejects with neither a field nor a header", () => {
				params = {controller = "csrfProtectedExcept", action = "update"}
				_controller = application.wo.controller("csrfProtectedExcept", params)
				var state = {type = ""}
				try {
					_controller.processAction("update", params)
				} catch (any e) {
					state.type = e.Type
				}
				expect(state.type).toBe("Wheels.InvalidAuthenticityToken")
			})
		})

		describe("authenticityToken = false on form helpers (forms in cached fragments)", () => {

			beforeEach(() => {
				$oldProtected = StructKeyExists(request, "$wheelsProtectedFromForgery") ? request.$wheelsProtectedFromForgery : "unset"
				request.$wheelsProtectedFromForgery = true
				_controller = application.wo.controller("dummy", {controller = "dummy", action = "index"})
			})

			afterEach(() => {
				if ($oldProtected == "unset") {
					StructDelete(request, "$wheelsProtectedFromForgery")
				} else {
					request.$wheelsProtectedFromForgery = $oldProtected
				}
			})

			it("startFormTag still embeds the token by default", () => {
				expect(_controller.startFormTag(action = "update", method = "post")).toInclude('name="authenticityToken"')
			})

			it("startFormTag(authenticityToken = false) leaves the token out, and no stray attribute", () => {
				var html = _controller.startFormTag(action = "update", method = "post", authenticityToken = false)
				expect(html).notToInclude('name="authenticityToken"')
				expect(html).notToInclude('authenticitytoken="')
			})

			it("buttonTo still embeds the token by default", () => {
				expect(_controller.buttonTo(text = "Delete", action = "delete", method = "delete")).toInclude('name="authenticityToken"')
			})

			it("buttonTo(authenticityToken = false) leaves the token out, and no stray attribute", () => {
				var html = _controller.buttonTo(text = "Delete", action = "delete", method = "delete", authenticityToken = false)
				expect(html).notToInclude('name="authenticityToken"')
				expect(html).notToInclude('authenticitytoken="')
			})
		})
	}

}
