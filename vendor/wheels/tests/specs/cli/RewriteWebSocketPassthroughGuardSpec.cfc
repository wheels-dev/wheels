/**
 * Regression guard for wheels-dev/wheels-websockets##1: WebSocket upgrades to
 * lucee/extension-websocket's /ws/<name> endpoints (e.g. the wheels-websockets
 * package's /ws/wheels) must get past the Tomcat RewriteValve rules we ship.
 *
 * Without a pass-through, the front-controller catch-all rewrites the upgrade
 * to /index.cfm/ws/... before Tomcat's WsFilter can match the endpoint, and the
 * client receives a Wheels 404 instead of a 101. The pass-through is gated on
 * the Upgrade header so plain HTTP requests under /ws/ still reach the router
 * (an app route like /ws/status keeps working) — an unconditional
 * `RewriteRule ^/ws/.*$ - [L]` would hand those to Tomcat's default servlet.
 *
 * Structural guard: proving the upgrade needs a live servlet container plus
 * the websocket extension, so we assert the rule shape in every Tomcat
 * RewriteValve surface we ship — the `wheels new` rewrite.config template
 * and the `wheels deploy init` Dockerfile template. The Tuckey urlrewrite.xml
 * files (CommandBox/Undertow) are deliberately not covered: on Undertow the
 * extension accepts the upgrade but never runs the listener, so there is no
 * working WebSocket path there to protect yet.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Tomcat rewrite rules pass WebSocket upgrades through (wheels-websockets##1)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above. Shared through a
			// struct because outer-describe `var`s aren't reliably captured by
			// inner closures on Adobe CF.
			var ctx = {};
			ctx.repoRoot = expandPath("/wheels/../..");
			ctx.targets = [
				"cli/lucli/templates/app/rewrite.config",
				"cli/lucli/templates/deploy/init/Dockerfile.mustache"
			];
			ctx.condition = "RewriteCond %{HTTP:Upgrade} ^websocket$ [NC]";
			ctx.passthrough = "RewriteRule ^/ws/.*$ - [L]";
			ctx.catchAll = "RewriteRule ^/(.*)$ /index.cfm/$1 [L]";

			it("gates the /ws/ pass-through on the Upgrade header in every surface", () => {
				for (var relPath in ctx.targets) {
					var rules = $rewriteDirectives(ctx.repoRoot & "/" & relPath);
					var ruleAt = ArrayFind(rules, ctx.passthrough);
					expect(ruleAt > 1).toBeTrue(
						relPath & " is missing '" & ctx.passthrough & "' (or it is the first directive, "
						& "so nothing gates it)."
					);
					expect(rules[ruleAt - 1]).toBe(
						ctx.condition,
						relPath & ": the /ws/ pass-through must be immediately preceded by '"
						& ctx.condition & "' so plain HTTP requests under /ws/ still reach the router."
					);
				}
			});

			it("places the /ws/ pass-through before the front-controller catch-all", () => {
				for (var relPath in ctx.targets) {
					var rules = $rewriteDirectives(ctx.repoRoot & "/" & relPath);
					var ruleAt = ArrayFind(rules, ctx.passthrough);
					var catchAllAt = ArrayFind(rules, ctx.catchAll);
					expect(catchAllAt > 0).toBeTrue(relPath & " no longer has the catch-all '" & ctx.catchAll & "'.");
					expect(ruleAt > 0 && ruleAt < catchAllAt).toBeTrue(
						relPath & ": the /ws/ pass-through (directive " & ruleAt
						& ") must come before the catch-all (directive " & catchAllAt & ")."
					);
				}
			});

		});

	}

	/**
	 * The RewriteCond/RewriteRule directives of a file, in order, normalized so
	 * the plain rewrite.config and the Dockerfile's quoted `printf` arguments
	 * ('RewriteRule ...' \) compare equal. Comment lines are skipped.
	 */
	public array function $rewriteDirectives(required string path) {
		var directives = [];
		for (var line in ListToArray(FileRead(arguments.path), Chr(10))) {
			var text = REReplace(line, "^\s*'?", "");
			text = REReplace(text, "'?\s*\\?\s*$", "");
			if (Left(text, 7) == "Rewrite") {
				ArrayAppend(directives, text);
			}
		}
		return directives;
	}

}
