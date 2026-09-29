/**
 * The `wheels new` template's session cookie is Secure whenever the request that
 * creates the session is HTTPS (direct, or X-Forwarded-Proto: https behind a
 * TLS-terminating proxy), not only when WHEELS_ENV says "production". Going live
 * the documented way (config/environment.cfm) never changed WHEELS_ENV, and the
 * scaffold's .env says development, so the cookie stayed non-Secure. The Wheels
 * environment itself can't be read in the pseudo-constructor (the application
 * scope binds only after it runs).
 *
 * Structural (no runtime): the pseudo-constructor can't be driven from the suite.
 * Also pins the generated sessions spec's GET-logout case (wheels generate auth).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels new template: session cookie secure flag", () => {

			var repoRoot = expandPath("/wheels/../..");
			var content = fileRead(repoRoot & "/cli/lucli/templates/app/public/Application.cfc");

			it("turns Secure on for an HTTPS request, direct or through a TLS-terminating proxy", () => {
				var block = mid(content, findNoCase("this.sessionCookie = {", content), 700);
				expect(findNoCase("cgi.server_port_secure", block) > 0).toBeTrue("direct HTTPS (server_port_secure)");
				expect(findNoCase("cgi.https", block) > 0).toBeTrue("direct HTTPS (cgi.https)");
				expect(reFindNoCase("cgi\.http_x_forwarded_proto\s*==\s*""https""", block) > 0).toBeTrue("X-Forwarded-Proto: https");
			});

			it("still turns Secure on for WHEELS_ENV=production", () => {
				var block = mid(content, findNoCase("this.sessionCookie = {", content), 700);
				expect(reFindNoCase("currentEnv\s*==\s*""production""", block) > 0).toBeTrue();
			});

		});

		describe("wheels generate auth: generated sessions spec", () => {

			it("includes a behavioural GET-logout case", () => {
				var spec = fileRead(expandPath("/wheels/../..") & "/cli/lucli/templates/auth/spec-sessions-controller.txt");
				expect(findNoCase("does not log out on a GET to the delete action", spec) > 0).toBeTrue();
			});

		});

	}

}
