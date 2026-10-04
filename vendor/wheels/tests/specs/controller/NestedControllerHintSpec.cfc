/**
 * F14: a nested controller (app/controllers/<pkg>/X.cfc) that declares
 * extends="Controller" cannot find its base class — a bare extends name resolves
 * relative to the controller's own package, so it looks for
 * app/controllers/<pkg>/Controller.cfc, which does not exist. The fix is to
 * extend "app.controllers.Controller".
 *
 * When controller instantiation fails this way, $createControllerClass carries a
 * hint on request.wheels.errorHint and logs it to wheels.log, then rethrows the
 * ORIGINAL exception unchanged (type, message, tag context and cause intact).
 * It does NOT splice the hint into the exception message.
 *
 * $missingBaseControllerHint is pure (exception struct + controller name -> hint
 * string or ""); it parses the missing-component operand and hints only when that
 * operand is the base Controller. Unit-tested against each engine's phrasing;
 * the catch path is exercised end-to-end against a real broken nested fixture.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("$missingBaseControllerHint", () => {

			it("hints app.controllers.Controller for a nested controller, Lucee phrasing", () => {
				var e = {type = "expression", message = "invalid component definition, can't find component [Controller]", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toInclude("app.controllers.Controller");
				expect(hint).toInclude("admin.Users");
			});

			it("hints for a nested controller, Adobe phrasing (trailing period)", () => {
				var e = {type = "", message = "Could not find the ColdFusion component or interface Controller.", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toInclude("app.controllers.Controller");
			});

			it("hints for a deeply nested controller, bracketed phrasing", () => {
				var e = {type = "", message = "Could not find component [Controller]", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.reports.Monthly");
				expect(hint).toInclude("app.controllers.Controller");
			});

			it("stays silent for a top-level (non-nested) controller name", () => {
				var e = {type = "expression", message = "invalid component definition, can't find component [Controller]", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "Users");
				expect(hint).toBe("");
			});

			it("stays silent for an unrelated error in a nested controller", () => {
				var e = {type = "expression", message = "Element FOO is undefined in a Java object", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toBe("");
			});

			it("stays silent when a DIFFERENT component (not Controller) is the missing operand", () => {
				var e = {type = "expression", message = "invalid component definition, can't find component [SomeService]", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toBe("");
			});

			it("stays silent when a different component is missing even if the detail mentions Controller", () => {
				// The missing operand is [SomeService]; "Controller" only appears in
				// the detail. Tying the hint to the parsed operand avoids this false
				// positive (rev1-r2).
				var e = {type = "expression", message = "can't find component [SomeService]", detail = "Controller initialization failed"};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toBe("");
			});

			it("stays silent when the missing operand is an already-qualified *.Controller", () => {
				// If a nested controller already extends the full path and that still
				// fails, "use app.controllers.Controller" would be wrong advice — only
				// the BARE base "Controller" operand gets the hint.
				var e = {type = "expression", message = "invalid component definition, can't find component [app.controllers.Controller]", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toBe("");
			});

		});

		describe("controller() catch path (end to end)", () => {

			afterEach(() => {
				if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "errorHint")) {
					StructDelete(request.wheels, "errorHint");
				}
			});

			it("rethrows the original error unchanged and carries the hint on request.wheels.errorHint where the engine names the missing base", () => {
				if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "errorHint")) {
					StructDelete(request.wheels, "errorHint");
				}
				// brokennest.Broken is a real fixture that declares extends="Controller"
				// from a nested package, so instantiation fails exactly as a user's
				// nested controller would. Keep the caught exception in the struct
				// (NOT a local.X var): a catch body runs under a nested local scope on
				// BoxLang, so only an outer-struct field survives the catch (Cross-Engine
				// Invariant 11).
				var state = {caught = false, type = "", hintInMessage = true, caughtException = {}};
				try {
					application.wo.controller(name = "brokennest.Broken");
				} catch (any e) {
					state.caught = true;
					state.caughtException = e;
					state.type = StructKeyExists(e, "type") ? e.type : "";
					state.hintInMessage = FindNoCase("app.controllers.Controller", StructKeyExists(e, "message") ? e.message : "") GT 0;
				}

				expect(state.caught).toBeTrue();
				// The ORIGINAL exception is rethrown unchanged on every engine: it is
				// NOT re-typed to a Wheels.* error and the hint was NOT spliced into its
				// message.
				expect(ReFindNoCase("^Wheels\.", state.type)).toBe(0);
				expect(state.hintInMessage).toBeFalse();

				// The hint is carried on request.wheels.errorHint ONLY when the engine's
				// error names the missing base as the operand. Lucee/Adobe phrase it as
				// "... component [Controller]" / "... component or interface Controller";
				// BoxLang reports a generic "Could not initialize class <child>" with no
				// operand (and the cause chain repeats the same text), so no hint is
				// produced there — and, crucially, no FALSE hint either. Drive the
				// expectation off the pure helper applied to the REAL caught exception,
				// so the assertion holds on every engine without hard-coding phrasing.
				var expectedHint = application.wo.$missingBaseControllerHint(exception = state.caughtException, name = "brokennest.Broken");
				if (Len(expectedHint)) {
					expect(StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "errorHint")).toBeTrue();
					expect(request.wheels.errorHint).toBe(expectedHint);
					expect(request.wheels.errorHint).toInclude("app.controllers.Controller");
				} else {
					expect(StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "errorHint")).toBeFalse();
				}
			});

		});
	}

}
