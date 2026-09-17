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

			it("ships app/snippets/CRUDContent.txt identical to the bundled codegen template", () => {
				// `wheels new` copies every codegen template into the app's
				// app/snippets/, and Templates.cfc resolves THOSE first — they
				// shadow the bundled copy. So a fix to templates/codegen/
				// CRUDContent.txt is invisible to every freshly generated app
				// unless the snippet copy moves with it. That is exactly how the
				// 404 guard shipped in a release and then failed to appear in a
				// stock `wheels new` app: the two files had silently diverged.
				//
				// Only this pair is pinned. Two other twins differ on purpose
				// (the app copies read the reload password from .env), so a
				// blanket "all snippets match codegen" rule would be wrong.
				var bundled = fileRead(expandPath("/cli/lucli/templates/codegen/CRUDContent.txt"));
				var shipped = fileRead(templateRoot & "app/snippets/CRUDContent.txt");
				expect(compare(shipped, bundled)).toBe(0);
				// And the shipped copy must actually carry the guard.
				expect(shipped).toInclude('filters(through="requireRecord"');
			});

		});

	}

}
