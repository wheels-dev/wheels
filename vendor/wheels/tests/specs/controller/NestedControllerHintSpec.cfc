/**
 * F14: a nested controller (app/controllers/<pkg>/X.cfc) that declares
 * extends="Controller" cannot find its base class — CF resolves a bare extends
 * name relative to the controller's own package, so it looks for
 * app/controllers/<pkg>/Controller.cfc, which does not exist. The fix is to
 * extend "app.controllers.Controller". When controller instantiation fails this
 * way, Wheels adds that hint to the error message (additive text only; the
 * status and control flow are unchanged).
 *
 * $missingBaseControllerHint is pure (exception struct + controller name ->
 * hint string or ""), so it is unit-tested here against each engine's
 * component-not-found phrasing without depending on live component resolution.
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

			it("hints for a nested controller, Adobe phrasing", () => {
				var e = {type = "", message = "Could not find the ColdFusion component or interface Controller.", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toInclude("app.controllers.Controller");
			});

			it("hints for a deeply nested controller, BoxLang-ish phrasing", () => {
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

			it("stays silent when a different component (not Controller) is missing", () => {
				var e = {type = "expression", message = "invalid component definition, can't find component [SomeService]", detail = ""};
				var hint = application.wo.$missingBaseControllerHint(exception = e, name = "admin.Users");
				expect(hint).toBe("");
			});

		});
	}

}
