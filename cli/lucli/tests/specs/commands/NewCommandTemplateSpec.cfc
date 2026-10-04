/**
 * Verifies the `wheels new` project template is complete enough that a
 * scaffolded app can boot without hitting missing-file errors in the
 * framework's bootstrap path.
 *
 * Regression guard: an earlier template omitted these stub files, which
 * caused onApplicationStart to throw mid-bootstrap. The exception cascaded
 * into onError, which then failed on a missing application.wo — surfacing
 * the misleading "key [WO] doesn't exist" rather than the real root cause
 * (the hard include in vendor/wheels/Global.cfc:3404 of
 * /app/global/functions.cfm).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.templateRoot = expandPath("/cli/lucli/templates/app/");
	}

	function run() {

		describe("wheels new template completeness", () => {

			it("ships app/global/functions.cfm (hard-included by Global.cfc)", () => {
				expect(fileExists(templateRoot & "app/global/functions.cfm")).toBeTrue();
			});

			it("ships the consumer AI doc tier (CLAUDE.md / AGENTS.md / .ai/README.md)", () => {
				// Two-tier AI docs: every `wheels new` scaffold ships the
				// consumer application-developer docs (see
				// docs/superpowers/plans/2026-08-30-ai-docs-two-tier.md and
				// tools/build/scripts/ship-consumer-docs.sh).
				expect(fileExists(templateRoot & "CLAUDE.md")).toBeTrue();
				expect(fileExists(templateRoot & "AGENTS.md")).toBeTrue();
				expect(fileExists(templateRoot & ".ai/README.md")).toBeTrue();
			});

			it("ships app/views/helpers.cfm (used by layout rendering)", () => {
				expect(fileExists(templateRoot & "app/views/helpers.cfm")).toBeTrue();
			});

			it("ships every app/events/*.cfm handler hard-included at boot", () => {
				// The framework's events/onapplicationstart.cfc unconditionally
				// includes each of these at boot (via EventMethods.cfc for
				// request/session events). Missing any one crashes
				// onApplicationStart.
				var requiredEvents = [
					"onapplicationstart", "onapplicationend",
					"onrequeststart",     "onrequestend",
					"onsessionstart",     "onsessionend",
					"onerror",            "onerror.json",     "onerror.xml",
					"onmissingtemplate",  "onmaintenance",    "onabort"
				];
				var missing = [];
				for (var evt in requiredEvents) {
					if (!fileExists(templateRoot & "app/events/" & evt & ".cfm")) {
						arrayAppend(missing, evt & ".cfm");
					}
				}
				expect(arrayToList(missing)).toBe("");
			});

			it("ships a commented config/<environment>/settings.cfm for every environment", () => {
				// The guides and examples document per-environment overrides in
				// config/<environment>/settings.cfm; the framework includes the
				// file only when it exists. The stubs must stay comment-only so a
				// new app behaves exactly as it does without them.
				var missing = [];
				var active = [];
				for (var env in ["development", "testing", "production", "maintenance"]) {
					var path = templateRoot & "config/" & env & "/settings.cfm";
					if (!fileExists(path)) {
						arrayAppend(missing, env);
						continue;
					}
					for (var line in listToArray(fileRead(path), Chr(10))) {
						var trimmed = trim(line);
						if (len(trimmed) && left(trimmed, 2) != "//" && findNoCase("set(", trimmed)) {
							arrayAppend(active, env & ": " & trimmed);
						}
					}
				}
				expect(arrayToList(missing)).toBe("", "missing environments");
				expect(arrayToList(active, " | ")).toBe("", "uncommented set() calls");
			});

			it("commits vendor/: the generated .gitignore doesn't ignore it", () => {
				// A clone, CI checkout or image build needs vendor/wheels/ (the
				// framework) and any packages added with `wheels packages add`.
				var ignored = [];
				for (var line in listToArray(fileRead(templateRoot & "_gitignore"), Chr(10))) {
					var rule = trim(line);
					if (len(rule) && left(rule, 1) != "##" && reFindNoCase("^/?vendor(/|$)", rule)) {
						arrayAppend(ignored, rule);
					}
				}
				expect(arrayToList(ignored, " | ")).toBe("");
			});

			it("ships .env.example next to .env with the same keys and no secret values", () => {
				expect(fileExists(templateRoot & "_env.example")).toBeTrue();
				var keys = function(path) {
					var found = [];
					for (var line in listToArray(fileRead(path), Chr(10))) {
						if (reFind("^[A-Z_]+=", trim(line))) {
							arrayAppend(found, listFirst(trim(line), "="));
						}
					}
					return arrayToList(found);
				};
				expect(keys(templateRoot & "_env.example")).toBe(keys(templateRoot & "_env"));
				var example = fileRead(templateRoot & "_env.example");
				expect(example).notToInclude("{{reloadPassword}}");
				expect(example).notToInclude("{{luceeAdminPassword}}");
			});

			it("ships app/middleware/ and keeps the legacy plugins README in the root plugins/ the framework reads", () => {
				expect(directoryExists(templateRoot & "app/middleware")).toBeTrue();
				expect(fileExists(templateRoot & "app/middleware/README.md")).toBeTrue();
				// vendor/wheels/events/init/views.cfm loads plugins from /plugins,
				// which public/Application.cfc maps to the app root.
				expect(directoryExists(templateRoot & "app/plugins")).toBeFalse();
				expect(fileExists(templateRoot & "plugins/README.md")).toBeTrue();
			});

			it("ships the migrator's dbmigrate templates and no frozen generator overrides", () => {
				// vendor/wheels/Migrator.cfc reads /app/snippets/dbmigrate/ for the
				// development migrator UI. Generator .txt copies would shadow the
				// CLI's own templates (Templates.cfc findTemplate) and freeze them:
				// that is how the #3608 404 guard shipped in templates/codegen/
				// CRUDContent.txt yet was missing from stock `wheels new` apps.
				// Shipping no copies removes the drift instead of pinning one pair.
				var codegenDir = expandPath("/cli/lucli/templates/codegen/dbmigrate/");
				var dbmigrate = directoryList(templateRoot & "app/snippets/dbmigrate", false, "name", "*.txt");
				expect(arrayLen(dbmigrate)).toBe(arrayLen(directoryList(codegenDir, false, "name", "*.txt")));
				// The app copy and the one `wheels generate snippets templates` copies
				// from must not drift apart.
				var drifted = [];
				for (var name in dbmigrate) {
					if (compare(fileRead(templateRoot & "app/snippets/dbmigrate/" & name), fileRead(codegenDir & name)) != 0) {
						arrayAppend(drifted, name);
					}
				}
				expect(arrayToList(drifted)).toBe("");
				expect(arrayToList(directoryList(templateRoot & "app/snippets", false, "name", "*.txt"))).toBe("");
			});

			it("doesn't show an empty-string default in the dbmigrate templates", () => {
				// Since 4.1.0 the migrator rejects default='' on string, text and
				// char columns (Wheels.InvalidDefault), and every generated
				// migration copies these headers, so they must not teach it.
				var offenders = [];
				for (var dir in [templateRoot & "app/snippets/dbmigrate/", expandPath("/cli/lucli/templates/codegen/dbmigrate/")]) {
					for (var name in directoryList(dir, false, "name", "*.txt")) {
						if (reFind("default\s*=\s*(''|"""")", fileRead(dir & name))) {
							arrayAppend(offenders, name);
						}
					}
				}
				expect(arrayToList(offenders)).toBe("");
			});

			it("writes a lucee.json SQLite DSN with the ##project:path## placeholder LuCLI resolves", () => {
				var m = new cli.lucli.Module(cwd = expandPath("/"));
				makePublic(m, "buildSQLiteDatasourcesBlock");
				var block = m.buildSQLiteDatasourcesBlock("probe");
				expect(block).toInclude("jdbc:sqlite:##project:path##/db/development.sqlite");
				expect(block).toInclude("jdbc:sqlite:##project:path##/db/test.sqlite");
				expect(block).notToInclude("{project}");
			});

			it("links the template's comments to the current (v4-2-0) guides", () => {
				var stale = [];
				for (var path in directoryList(templateRoot, true, "path", "*.cfm|*.md|*.cfc")) {
					var content = fileRead(path);
					if (findNoCase("guides.wheels.dev/v4-0-0/", content) || findNoCase("guides.wheels.dev/v4-1-0/", content)) {
						arrayAppend(stale, replace(path, templateRoot, ""));
					}
				}
				expect(arrayToList(stale)).toBe("");
			});

			it("ships both public/Application.cfc and public/miscellaneous/Application.cfc", () => {
				// Issue #2311 reported a duplicate "create blog/Application.cfc"
				// line. The root cause was the copyTemplateDir() recursion bug
				// fixed in #2342 — both files exist on purpose (the empty one
				// in public/miscellaneous/ overrides the parent so requests to
				// that subtree don't run through Wheels) but flattened paths
				// printed both as the same string. This guards against a
				// future "cleanup" that mistakenly deletes one as a duplicate.
				expect(fileExists(templateRoot & "public/Application.cfc")).toBeTrue();
				expect(fileExists(templateRoot & "public/miscellaneous/Application.cfc")).toBeTrue();
			});

			it("hardens tests/populate.cfm so a failed migration fails the test run loudly", () => {
				// Migrator.cfc::migrateTo() swallows per-migration exceptions
				// into its returned string ("Error migrating to <version>...")
				// instead of rethrowing. A template that discards the return
				// value leaves a silently half-migrated test database — and
				// app-runner.cfm skips populate.cfm on every subsequent run
				// because the migrator-versions table exists after the partial
				// run, so all later `wheels test` runs hit the broken schema
				// with zero signal. The template must capture the result, drop
				// the versions table on failure (so the next run re-enters
				// populate and stays loud), and Throw so app-runner's populate
				// catch returns a structured 500.
				var content = fileRead(templateRoot & "tests/populate.cfm");
				expect(content).toInclude("migrateToLatest()");
				expect(content).toInclude("Error migrating");
				expect(content).toInclude("application.wheels.migratorTableName");
				expect(content).toInclude("PopulateCfm.MigrationFailed");
			});

			it("ships stacked form defaults, red validation errors, and boxed flash styles", () => {
				expect(fileExists(templateRoot & "public/stylesheets/wheels.css")).toBeTrue();
				var css = fileRead(templateRoot & "public/stylesheets/wheels.css");
				expect(css).toInclude(".error-message");
				expect(css).toInclude("width: 100%");
				expect(css).toInclude("⚠");
				// Boxed flash messages: success (green) and notice (blue) are
				// styled like the error box so created/updated/deleted confirmations
				// aren't bare text.
				expect(css).toInclude(".success-message");
				expect(css).toInclude(".notice-message");
				expect(css).toInclude("--wheels-success");
				expect(css).toInclude("--wheels-notice");
				// Action rows: the scaffold gives every action simple.css's
				// `.button` class, and this rule lays the row out. Without it
				// the buttons sit flush against each other with no gap.
				expect(css).toInclude(".wheels-actions");
				expect(css).toInclude("display: flex");
				// Top-aligned, and the button nested inside buttonTo's <form>
				// loses simple.css's 8px bottom margin. With `center` and that
				// margin intact, the form was 8px taller than the sibling links
				// and Delete floated 4px above Edit and "all posts".
				expect(css).toInclude("align-items: flex-start");
				expect(css).toInclude(".wheels-actions > form > .button");

				var layout = fileRead(templateRoot & "app/views/layout.cfm");
				expect(layout).toInclude('styleSheetLinkTag(sources="simple,wheels")');

				var settings = fileRead(templateRoot & "config/settings.cfm");
				expect(settings).toInclude("includeFormErrorMessages=true");
				expect(settings).toInclude('labelPlacement="before"');
			});

			describe("config reads WHEELS_ENV and WHEELS_DATASOURCE (##3946)", () => {

				// A hardcoded set(environment="development") left wheels deploy init
				// images (ENV WHEELS_ENV=production) running in development mode.
				var environmentFor = (struct envValues) => {
					return new cli.lucli.tests._helpers.TemplateConfigHarness(arguments.envValues)
						.includeConfig("/cli/lucli/templates/app/config/environment.cfm")
						.environment;
				};

				it("uses WHEELS_ENV=production", () => {
					expect(environmentFor({WHEELS_ENV: "production"})).toBe("production");
				});

				it("accepts each environment name, ignoring case and surrounding spaces", () => {
					expect(environmentFor({WHEELS_ENV: "testing"})).toBe("testing");
					expect(environmentFor({WHEELS_ENV: "maintenance"})).toBe("maintenance");
					expect(environmentFor({WHEELS_ENV: " Production "})).toBe("production");
					expect(environmentFor({WHEELS_ENV: "PRODUCTION"})).toBe("production");
				});

				it("falls back to development when WHEELS_ENV is unset or empty", () => {
					expect(environmentFor({})).toBe("development");
					expect(environmentFor({WHEELS_ENV: ""})).toBe("development");
					expect(environmentFor({WHEELS_ENV: "  "})).toBe("development");
				});

				it("refuses to start with any other WHEELS_ENV value", () => {
					expect(() => environmentFor({WHEELS_ENV: "prod"})).toThrow("Wheels.InvalidEnvironment");
					expect(() => environmentFor({WHEELS_ENV: "staging"})).toThrow("Wheels.InvalidEnvironment");
				});

				it("takes the datasource from WHEELS_DATASOURCE, otherwise the scaffolded name", () => {
					var settingsFile = "/cli/lucli/templates/app/config/settings.cfm";
					var harness = new cli.lucli.tests._helpers.TemplateConfigHarness({});
					expect(harness.includeConfig(settingsFile).dataSourceName).toBe("{{datasourceName}}");
					harness = new cli.lucli.tests._helpers.TemplateConfigHarness({WHEELS_DATASOURCE: "app"});
					expect(harness.includeConfig(settingsFile).dataSourceName).toBe("app");
				});
			});

			it("ships .gitkeep files in tests/specs subfolders so empty dirs survive git", () => {
				// Templates check — confirms the .gitkeep files exist on disk
				// in the template tree. Their copying into the scaffolded app
				// is verified by NewCommandGitkeepSpec. Three representative
				// paths chosen here; the same .gitkeep mechanism preserves
				// app/lib, app/jobs, app/mailers, public/images, etc. Found
				// during batch B (2026-04-29 fresh-VM triage sub-finding).
				expect(fileExists(templateRoot & "tests/specs/controllers/.gitkeep")).toBeTrue();
				expect(fileExists(templateRoot & "tests/specs/functional/.gitkeep")).toBeTrue();
				expect(fileExists(templateRoot & "tests/specs/models/.gitkeep")).toBeTrue();
			});

		});

	}

}
