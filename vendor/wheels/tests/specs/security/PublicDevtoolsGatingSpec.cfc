/**
 * Locks in the 2026-06-09 framework-review fixes for the public dev-tools
 * surface (SEC-3, SEC-6, P5, P6, P12, P13):
 *
 * - migrator command endpoint gated by localhost + anti-CSRF header (SEC-3)
 * - deprecated /wheels/mcp loopback check via InetAddress, cfexecute removed
 *   from the HTTP surface (SEC-6)
 * - migrator JSON payload no longer hidden behind an always-false
 *   structKeyExists(variables, "local") guard, and the JS refresh builds
 *   URLs from urlFor() templates instead of hardcoded paths (P5/P6)
 * - /wheels/ai no longer issues loopback HTTP self-requests (P12)
 * - MCP SessionManager purges expired sessions on the request path (P13)
 *
 * The .cfm endpoints cannot be driven from a unit test without a full
 * request fixture, so — like PublicComponentProductionSpec — those gates are
 * verified by source inspection; SessionManager is verified behaviorally.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Migrator command endpoint gating (SEC-3)", () => {

			it("restricts requests to loopback clients via InetAddress.isLoopbackAddress()", () => {
				var source = FileRead(ExpandPath("/wheels/public/migrator/command.cfm"));
				expect(Find("java.net.InetAddress", source) > 0).toBeTrue(
					"command.cfm must resolve cgi.REMOTE_ADDR through java.net.InetAddress"
				);
				expect(Find("isLoopbackAddress", source) > 0).toBeTrue(
					"command.cfm must gate on InetAddress.isLoopbackAddress() like consoleeval.cfm"
				);
			});

			it("rejects forwarded clients via X-Forwarded-For inspection", () => {
				var source = FileRead(ExpandPath("/wheels/public/migrator/command.cfm"));
				expect(FindNoCase("HTTP_X_FORWARDED_FOR", source) > 0).toBeTrue(
					"command.cfm must inspect X-Forwarded-For to prevent proxy bypass"
				);
			});

			it("requires the X-Wheels-Csrf-Token request header before running any command", () => {
				var source = FileRead(ExpandPath("/wheels/public/migrator/command.cfm"));
				expect(FindNoCase("X-Wheels-Csrf-Token", source) > 0).toBeTrue(
					"command.cfm must require the anti-CSRF custom request header"
				);
				expect(FindNoCase("$migratorCsrfToken", source) > 0).toBeTrue(
					"command.cfm must validate against the app-scoped migrator CSRF token (fail closed)"
				);
			});

			it("compares the CSRF token in constant time", () => {
				var source = FileRead(ExpandPath("/wheels/public/migrator/command.cfm"));
				expect(Find("java.security.MessageDigest", source) > 0).toBeTrue(
					"command.cfm must use MessageDigest.isEqual for the token comparison"
				);
			});

		});

		describe("Migrator GUI page payload + JS URLs (P5/P6)", () => {

			it("no longer uses the always-false structKeyExists(variables, 'local') guard", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));
				expect(REFindNoCase('structKeyExists\(\s*variables\s*,\s*"local"\s*\)', source)).toBe(
					0,
					"The include runs inside a CFC method where `local` is the function scope, never a key of `variables` — the guard could never pass"
				);
			});

			it("serializes remainingMigrations into the JSON payload", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));
				expect(REFindNoCase("migrator\.remainingMigrations\s*=\s*remainingMigrations", source) > 0).toBeTrue(
					"The page's own JS (updateActionButtons) depends on REMAININGMIGRATIONS in the JSON refresh payload"
				);
			});

			it("serializes outOfSequenceMigrations into the JSON payload", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));
				expect(REFindNoCase("migrator\.outOfSequenceMigrations\s*=\s*outOfSequenceMigrations", source) > 0).toBeTrue(
					"The page's own JS (updateOutOfSequenceBanner) depends on OUTOFSEQUENCEMIGRATIONS in the JSON refresh payload"
				);
			});

			it("builds JS refresh URLs from urlFor() templates instead of hardcoded routes", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));
				expect(Find("/wheels/migrator/migrateto/", source)).toBe(0);
				expect(FindNoCase("/wheels/migrator/migrateIndividual/", source)).toBe(0);
				expect(Find("/wheels/migrator/redomigration/", source)).toBe(0);
				expect(Find("/wheels/migrator/sql/", source)).toBe(0);
				expect(Find("wheelsMigratorUrl(", source) > 0).toBeTrue(
					"The JS must resolve command/SQL URLs through the urlFor()-generated templates"
				);
			});

			it("embeds the anti-CSRF token for the command XHRs", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));
				expect(FindNoCase("X-Wheels-Csrf-Token", source) > 0).toBeTrue(
					"Every command XHR must send the X-Wheels-Csrf-Token header"
				);
			});

		});

		describe("Deprecated HTTP MCP endpoint (SEC-6)", () => {

			it("mcp.cfm checks loopback via InetAddress instead of a literal-string list", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/mcp.cfm"));
				expect(Find("isLoopbackAddress", source) > 0).toBeTrue(
					"mcp.cfm must use InetAddress.isLoopbackAddress() so IPv4-mapped IPv6 (::ffff:127.0.0.1) is handled"
				);
				expect(Find("127.0.0.1,::1", source)).toBe(
					0,
					"The literal-string loopback list must be gone — it missed ::ffff:127.0.0.1 and the rest of 127.0.0.0/8"
				);
			});

			it("McpServer.cfc no longer shells out via cfexecute", () => {
				var source = FileRead(ExpandPath("/wheels/public/mcp/McpServer.cfc"));
				expect(REFindNoCase("cfexecute\s*\(", source)).toBe(
					0,
					"The deprecated HTTP MCP transport must not expose a command-execution primitive; CLI-backed tools belong to the stdio MCP server"
				);
			});

		});

		describe("/wheels/ai serves project context in-process (P12)", () => {

			it("ai.cfm no longer issues loopback HTTP self-requests", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/ai.cfm"));
				expect(FindNoCase("new http(", source)).toBe(
					0,
					"Mode handlers must use direct includes / application-scope reads, not serial loopback HTTP"
				);
				expect(FindNoCase("cgi.server_port", source)).toBe(
					0,
					"No self-request URL construction should remain"
				);
			});

		});

		describe("MCP SessionManager purging (P13)", () => {

			it("purges expired sessions when a new session is created", () => {
				// A negative timeout marks every existing session as expired
				// immediately, so the second createSession() must purge the first.
				var manager = CreateObject("component", "wheels.public.mcp.SessionManager").init(sessionTimeout = -1);
				var firstId = manager.createSession();
				expect(manager.sessionExists(firstId)).toBeTrue();
				var secondId = manager.createSession();
				expect(manager.sessionExists(firstId)).toBeFalse(
					"createSession() must call cleanupExpiredSessions() so the app-scoped store cannot grow unbounded"
				);
				expect(manager.sessionExists(secondId)).toBeTrue();
			});

			it("keeps live sessions when the timeout has not elapsed", () => {
				var manager = CreateObject("component", "wheels.public.mcp.SessionManager").init();
				var firstId = manager.createSession();
				var secondId = manager.createSession();
				expect(manager.sessionExists(firstId)).toBeTrue();
				expect(manager.sessionExists(secondId)).toBeTrue();
			});

		});

	}

}
