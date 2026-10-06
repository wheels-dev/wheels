/**
 * HTTP fixture for TestClientCsrfSpec: a forgery-protected controller with
 * pages that render a token (csrfMetaTags(), authenticityTokenField()), one
 * that renders none, protected POST/PUT/PATCH/DELETE actions, and a login that
 * rotates the session. Mounted under /_csrfclient in tests/routes.cfm.
 */
component extends="Controller" {

	function config() {
		protectsFromForgery();
	}

	function metaPage() {
		renderText("<html><head>" & csrfMetaTags() & "</head><body>meta</body></html>");
	}

	function fieldPage() {
		renderText("<html><body><form method=""post"">" & authenticityTokenField() & "</form></body></html>");
	}

	function plainPage() {
		renderText("<html><body>no token here</body></html>");
	}

	function save() {
		renderText("saved:" & request.cgi.request_method);
	}

	function login() {
		var auth = new wheels.auth.SessionStrategy();
		auth.login({id = 1, name = "spec"});
		renderText("logged in");
	}

}
