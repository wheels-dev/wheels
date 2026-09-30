/**
 * Regression coverage for #3843.
 *
 * processRequest() applies its `csrf` option (default "ignore") to the controller it builds. It used
 * to do that through protectsFromForgery() on the instance, which writes to the controller's class
 * data, and that struct is the application-wide cached class. Every later real request to the same
 * controller then skipped CSRF protection until a reload. The option must only affect the request
 * processRequest() runs.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("processRequest() CSRF option stays on its own request (##3843)", () => {

			beforeEach(() => {
				saved = {method = request.cgi.request_method};
			})

			afterEach(() => {
				request.cgi["request_method"] = saved.method;
			})

			it("leaves the cached controller class's CSRF settings as configured", () => {
				g.processRequest(params = {controller = "csrfProtectedExcept", action = "update"}, method = "post");

				var classCsrf = application.wheels.controllers["csrfProtectedExcept"].$getControllerClassData().csrf;
				expect(classCsrf.type).toBe("exception");
				expect(classCsrf.except).toBe("show");
			})

			it("still enforces CSRF on a controller built after a default processRequest()", () => {
				g.processRequest(params = {controller = "csrfProtectedWithException", action = "create"}, method = "post");

				request.cgi["request_method"] = "post";
				var instance = g.controller(name = "csrfProtectedWithException", params = {controller = "csrfProtectedWithException", action = "create"});
				var thrown = {type = ""};
				try {
					instance.processAction();
				} catch (any e) {
					thrown.type = e.type;
				}
				expect(thrown.type).toBe("Wheels.InvalidAuthenticityToken");
			})

			it("keeps the historic default of ignoring CSRF for the processRequest() call itself", () => {
				var body = g.processRequest(params = {controller = "csrfProtectedWithException", action = "create"}, method = "post");
				expect(body).toBe("Create ran.");
			})

			it("applies csrf = exception to the processRequest() call", () => {
				var thrown = {type = ""};
				try {
					g.processRequest(params = {controller = "csrfProtectedExcept", action = "update"}, method = "post", csrf = "exception");
				} catch (any e) {
					thrown.type = e.type;
				}
				expect(thrown.type).toBe("Wheels.InvalidAuthenticityToken");
			})
		});
	}
}
