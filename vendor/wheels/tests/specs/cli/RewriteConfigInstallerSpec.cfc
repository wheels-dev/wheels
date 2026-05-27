/**
 * Regression: when a 3.x Wheels app is booted under Wheels 4.0 via `wheels
 * start`, LuCLI emits its bundled default rewrite.config (a narrow
 * `/(images|css|js|fonts|assets|static)/` allow-list plus negated
 * RewriteCond chains) into the per-server Catalina conf. That default
 * 404s static assets that live in 3.x-conventional dirs like
 * `/miscellaneous/`, `/javascripts/`, `/stylesheets/`, `/files/` —
 * every CSS/JS request gets rewritten through the front controller and
 * dispatched into Wheels with no matching route. See issue ##2626.
 *
 * Fix: `wheels start` provisions a project-level `rewrite.config` from the
 * working template at `cli/lucli/templates/app/rewrite.config` if the
 * project doesn't already have one. LuCLI's CatalinaBaseConfigGenerator
 * picks the project override up verbatim, sidestepping the buggy bundled
 * default. New apps already get the file via `wheels new`; this closes the
 * 3.x→4.x upgrade-path gap.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("cli.lucli.services.RewriteConfigInstaller", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			// Outer-describe `var` declarations aren't reliably captured by
			// inner closures on Adobe CF (CLAUDE.md "Closure gotcha"); share
			// them through a struct instead.
			var ctx = {};
			ctx.repoRoot = expandPath("/wheels/../..");
			ctx.templatePath = ctx.repoRoot & "/cli/lucli/templates/app/rewrite.config";

			it("writes the project-level rewrite.config when the project doesn't have one", () => {
				var installer = new cli.lucli.services.RewriteConfigInstaller();
				var projectRoot = getTempDirectory() & "wheels-rewriteinstaller-#createUUID()#";
				directoryCreate(projectRoot);
				try {
					expect(fileExists(projectRoot & "/rewrite.config")).toBeFalse(
						"Precondition: project should start without a rewrite.config"
					);

					var result = installer.install(projectRoot=projectRoot, sourceTemplate=ctx.templatePath);

					expect(result.installed).toBeTrue(
						"install() should report installed=true when it creates the file"
					);
					expect(fileExists(projectRoot & "/rewrite.config")).toBeTrue(
						"install() should write rewrite.config into the project root"
					);
				} finally {
					directoryDelete(projectRoot, true);
				}
			});

			it("is a no-op when the project already ships its own rewrite.config (idempotent)", () => {
				var installer = new cli.lucli.services.RewriteConfigInstaller();
				var projectRoot = getTempDirectory() & "wheels-rewriteinstaller-#createUUID()#";
				directoryCreate(projectRoot);
				try {
					fileWrite(projectRoot & "/rewrite.config", "## user-customized rules");
					// Baseline read AFTER write: Adobe CF 2025's fileWrite/fileRead
					// round-trip appends a trailing newline, so compare the
					// post-install content to this normalized baseline rather than
					// to the literal write string. The intent is "install() left the
					// file untouched", not "the engine round-trips bytes identically".
					var before = fileRead(projectRoot & "/rewrite.config");

					var result = installer.install(projectRoot=projectRoot, sourceTemplate=ctx.templatePath);

					expect(result.installed).toBeFalse(
						"install() should not overwrite a user-authored rewrite.config"
					);
					var preserved = fileRead(projectRoot & "/rewrite.config");
					expect(preserved).toBe(
						before,
						"Existing rewrite.config content must be preserved untouched"
					);
				} finally {
					directoryDelete(projectRoot, true);
				}
			});

			it("emits a rewrite.config that passes 3.x-convention static-asset dirs through to the default servlet", () => {
				var installer = new cli.lucli.services.RewriteConfigInstaller();
				var projectRoot = getTempDirectory() & "wheels-rewriteinstaller-#createUUID()#";
				directoryCreate(projectRoot);
				try {
					installer.install(projectRoot=projectRoot, sourceTemplate=ctx.templatePath);
					var content = fileRead(projectRoot & "/rewrite.config");

					// 3.x apps commonly use these directory names — each must
					// be in the allow-list so /miscellaneous/libs/bootstrap/...
					// is served by Tomcat's default servlet, not dispatched
					// into Wheels and 404'd.
					expect(content contains "miscellaneous").toBeTrue(
						"Static-dir allow-list must include 'miscellaneous' (3.x convention)"
					);
					expect(content contains "stylesheets").toBeTrue(
						"Static-dir allow-list must include 'stylesheets' (3.x convention)"
					);
					expect(content contains "javascripts").toBeTrue(
						"Static-dir allow-list must include 'javascripts' (3.x convention)"
					);
					expect(content contains "files").toBeTrue(
						"Static-dir allow-list must include 'files' (3.x convention)"
					);
				} finally {
					directoryDelete(projectRoot, true);
				}
			});

			it("emits a rewrite.config using positive-match [L]-flagged passthrough rules, not negated RewriteCond chains", () => {
				// Tomcat 9/11's RewriteValve does NOT honour stacked
				// `RewriteCond %{REQUEST_URI} !pattern` entries before a
				// single rewriting RewriteRule the way Apache mod_rewrite
				// does — the conditions effectively don't gate the rule, so
				// every static file 404s. The fix is positive-match skip
				// rules with the [L] flag.
				var installer = new cli.lucli.services.RewriteConfigInstaller();
				var projectRoot = getTempDirectory() & "wheels-rewriteinstaller-#createUUID()#";
				directoryCreate(projectRoot);
				try {
					installer.install(projectRoot=projectRoot, sourceTemplate=ctx.templatePath);
					var content = fileRead(projectRoot & "/rewrite.config");

					// Strip comment lines (Tomcat RewriteValve uses '#' for
					// comments at start-of-line). The template's documentation
					// block names the broken pattern in prose to explain why
					// we don't use it — that prose must not be matched.
					var activeRules = "";
					for (var line in listToArray(content, chr(10))) {
						if (!reFind("^\s*##", line) && len(trim(line))) {
							activeRules &= line & chr(10);
						}
					}

					expect(reFind("RewriteCond\s+%\{REQUEST_URI\}\s+!", activeRules) > 0).toBeFalse(
						"Active rules must not use negated RewriteCond chains — Tomcat's RewriteValve doesn't honour them and static files 404"
					);
					expect(activeRules contains "[L]").toBeTrue(
						"Active rules should use [L]-flagged passthrough"
					);
				} finally {
					directoryDelete(projectRoot, true);
				}
			});

			it("returns installed=false with a reason when the source template can't be read", () => {
				var installer = new cli.lucli.services.RewriteConfigInstaller();
				var projectRoot = getTempDirectory() & "wheels-rewriteinstaller-#createUUID()#";
				directoryCreate(projectRoot);
				try {
					var missing = getTempDirectory() & "wheels-no-such-template-#createUUID()#.config";

					var result = installer.install(projectRoot=projectRoot, sourceTemplate=missing);

					expect(result.installed).toBeFalse(
						"Missing template path should not silently 'succeed'"
					);
					expect(fileExists(projectRoot & "/rewrite.config")).toBeFalse(
						"Nothing should be written when the template is missing"
					);
				} finally {
					directoryDelete(projectRoot, true);
				}
			});

		});

	}

}
