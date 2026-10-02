/**
 * renderNotFound() is the public entry point for app code and generated scaffolds
 * to produce a 404, so they stop depending on the $-prefixed internal
 * $throwErrorOrShow404Page. It must mirror that internal: a 404 status, the typed
 * error in development (showErrorInformation on) and the onmissingtemplate.cfm page
 * in production. (#3900)
 *
 * It is defined as a controller mixin (controller/rendering.cfc), not a wheels.Global
 * helper, so it is scoped to controllers and NOT mixed onto models. Because it is a
 * public controller helper it also joins the protected controller method surface — an
 * app action literally named renderNotFound would get Wheels.ActionNotAllowed. That is
 * the intended guard; the name does not collide with anything in the shipped examples
 * or guides.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("renderNotFound (##3900)", () => {

			it("is registered as a protected controller method name", () => {
				expect(StructKeyExists(application.wheels.protectedControllerMethodsLookup, "renderNotFound")).toBeTrue();
			});

			it("is a controller method, not mixed onto models", () => {
				var c = application.wo.controller("dummy", {controller = "dummy", action = "dummy"});
				expect(StructKeyExists(c, "renderNotFound")).toBeTrue("controllers must have renderNotFound");

				var m = application.wo.model("Author");
				expect(StructKeyExists(m, "renderNotFound")).toBeFalse("models must NOT have renderNotFound");
			});

			it("sets a 404 and throws the typed error in development", () => {
				var c = application.wo.controller("dummy", {controller = "dummy", action = "dummy"});
				var priorSetting = application.wo.$get("showErrorInformation");
				application.wo.$set(showErrorInformation = true);
				try {
					expect(() => {
						c.renderNotFound(message = "Widget not found for the requested key.");
					}).toThrow("Wheels.RecordNotFound");
				} finally {
					application.wo.$set(showErrorInformation = priorSetting);
				}
			});

			it("honours a custom error type", () => {
				var c = application.wo.controller("dummy", {controller = "dummy", action = "dummy"});
				var priorSetting = application.wo.$get("showErrorInformation");
				application.wo.$set(showErrorInformation = true);
				try {
					expect(() => {
						c.renderNotFound(message = "nope", type = "Wheels.CustomNotFound");
					}).toThrow("Wheels.CustomNotFound");
				} finally {
					application.wo.$set(showErrorInformation = priorSetting);
				}
			});
		});
	}

}
