component extends="wheels.WheelsTest" {

	function run() {

		describe("application.wheels.protectedControllerMethods", () => {

			it("is populated at application start", () => {
				expect(Len(application.wheels.protectedControllerMethods)).toBeGT(0)
			})

			it("includes the env() global helper", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "env")).toBeGT(0)
			})

			it("includes the model() global helper", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "model")).toBeGT(0)
			})

			it("includes the redirectTo controller mixin method", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "redirectTo")).toBeGT(0)
			})

			it("includes the linkTo view helper", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "linkTo")).toBeGT(0)
			})

			it("does not include $-prefixed internal methods", () => {
				var dollarCount = 0
				for (var item in ListToArray(application.wheels.protectedControllerMethods)) {
					if (Left(item, 1) == "$") {
						dollarCount++
					}
				}
				expect(dollarCount).toBe(0)
			})
		})

		describe("$callAction action-dispatch gate", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
			})

			it("rejects dispatch to env() with Wheels.ActionNotAllowed", () => {
				expect(function(){
					_controller.$callAction(action = "env")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("rejects dispatch to model() with Wheels.ActionNotAllowed", () => {
				expect(function(){
					_controller.$callAction(action = "model")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("rejects dispatch to redirectTo() with Wheels.ActionNotAllowed", () => {
				expect(function(){
					_controller.$callAction(action = "redirectTo")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("rejects dispatch to $-prefixed internal methods", () => {
				expect(function(){
					_controller.$callAction(action = "$callAction")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("dispatches a legitimate user-defined action without throwing ActionNotAllowed", () => {
				// Guards against future regressions in $buildProtectedControllerMethods()
				// that would accidentally over-block by listing user actions like `test`.
				var state = {thrown = false}
				try {
					_controller.$callAction(action = "test")
				} catch (Wheels.ActionNotAllowed e) {
					state.thrown = true
				} catch (any e) {
					// Other downstream errors (e.g. view rendering) are not what
					// this spec is asserting against — only the protection gate.
				}
				expect(state.thrown).toBeFalse()
			})
		})

		// GH #3075: #2845's PR body and CLAUDE.md Anti-Pattern 8 both promise
		// that a helper-named action "falls through to the missing-action / 404
		// path, matching every other non-existent action." The block itself
		// worked, but the status contract was broken — the gate raw-threw
		// Wheels.ActionNotAllowed, which the EventMethods status map sent to a
		// 500 (only ^Wheels\.*NotFound$ mapped to 404). Routing the gate through
		// $throwErrorOrShow404Page (mirroring RecordNotFound / ViewNotFound) sets
		// the 404 header at the throw site and renders the production 404 page.
		describe("$callAction protected-method gate HTTP status (#chr(35)#3075)", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
				// Reset to a non-404 sentinel so a prior spec's status can't mask a
				// regression (the gate must set 404 itself).
				try { application.wo.$header(statusCode = 200) } catch (any e) {}
			})

			it("sets HTTP 404 (not 500) when a helper-named action is blocked", () => {
				try {
					_controller.$callAction(action = "env")
				} catch (Wheels.ActionNotAllowed e) {
					// expected — in dev/test ($get('showErrorInformation') = true)
					// $throwErrorOrShow404Page re-throws after setting the 404 header.
				}
				expect($responseStatus()).toBe(404)
			})

			it("sets HTTP 404 when a $-prefixed internal method is blocked", () => {
				try {
					_controller.$callAction(action = "$callAction")
				} catch (Wheels.ActionNotAllowed e) {
				}
				expect($responseStatus()).toBe(404)
			})
		})
	}

	// Reads the committed response status across engines. getStatus() is part
	// of the Servlet 3.0+ HttpServletResponse contract, honored by Lucee, Adobe,
	// and BoxLang.
	private numeric function $responseStatus() {
		return GetPageContext().getResponse().getStatus()
	}
}
