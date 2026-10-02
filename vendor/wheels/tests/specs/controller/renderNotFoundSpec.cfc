/**
 * renderNotFound() is the public entry point for app code and generated scaffolds
 * to produce a 404, so they stop depending on the $-prefixed internal
 * $throwErrorOrShow404Page. It must mirror that internal: a 404 status, the typed
 * error in development (showErrorInformation on) and the onmissingtemplate.cfm page
 * in production. (#3900)
 *
 * Because it is a public controller helper it also joins the protected controller
 * method surface — an app action literally named renderNotFound would start getting
 * Wheels.ActionNotAllowed. That is the intended guard (a helper can't be an action);
 * the name does not collide with anything in the shipped examples or guides.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("renderNotFound (##3900)", () => {

			it("is registered as a protected controller method name", () => {
				expect(StructKeyExists(application.wheels.protectedControllerMethodsLookup, "renderNotFound")).toBeTrue();
			});

			it("sets a 404 and throws the typed error in development", () => {
				var priorSetting = application.wo.$get("showErrorInformation");
				application.wo.$set(showErrorInformation = true);
				try {
					expect(() => {
						application.wo.renderNotFound(message = "Widget not found for the requested key.");
					}).toThrow("Wheels.RecordNotFound");
				} finally {
					application.wo.$set(showErrorInformation = priorSetting);
				}
			});

			it("honours a custom error type", () => {
				var priorSetting = application.wo.$get("showErrorInformation");
				application.wo.$set(showErrorInformation = true);
				try {
					expect(() => {
						application.wo.renderNotFound(message = "nope", type = "Wheels.CustomNotFound");
					}).toThrow("Wheels.CustomNotFound");
				} finally {
					application.wo.$set(showErrorInformation = priorSetting);
				}
			});
		});
	}

}
