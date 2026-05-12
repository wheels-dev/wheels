/**
 * Regression: `wheels new <app> --no-sqlite` must NOT embed the SQLite
 * datasource entries in the scaffolded lucee.json. Issue 2621.
 *
 * The bug: `cli/lucli/templates/app/lucee.json` hardcoded the
 * `org.sqlite.JDBC` datasource pair for {{datasourceName}} and
 * {{datasourceName}}_test. `scaffoldNewApp()` honored `--no-sqlite` only
 * for `configureSQLiteDatabase()` (the db/*.sqlite + config/app.cfm
 * injection), so even with the flag set, the rendered lucee.json still
 * pointed Lucee at jdbc:sqlite paths and the engine auto-created empty
 * database files on first connection.
 *
 * Fix: the template now uses a `{{datasourcesBlock}}` placeholder and
 * `Module.cfc::scaffoldNewApp()` threads `opts.noSQLite` into the
 * context so the substituted block is either the SQLite pair (default)
 * or an empty `{}` object (when `--no-sqlite` is set).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels new --no-sqlite (issue 2621)", function() {

			it("lucee.json template uses a datasourcesBlock placeholder so --no-sqlite can suppress SQLite", function() {
				var templatePath = expandPath("/cli/lucli/templates/app/lucee.json");
				expect(fileExists(templatePath)).toBeTrue(
					"Template missing at " & templatePath
				);

				var template = fileRead(templatePath);
				var placeholder = "{{" & "datasourcesBlock" & "}}";

				expect(template contains placeholder).toBeTrue(
					"Template should use the " & placeholder & " placeholder so scaffoldNewApp() can substitute either the SQLite datasource pair (default) or an empty block (--no-sqlite). Issue 2621."
				);

				// The template must NOT hardcode the SQLite class — emitting it
				// has to go through the placeholder so --no-sqlite can suppress.
				expect(template contains "org.sqlite.JDBC").toBeFalse(
					"Template should not hardcode 'org.sqlite.JDBC' — emit it via the " & placeholder & " placeholder. Issue 2621."
				);
			});

			it("Module.cfc threads opts.noSQLite into the datasourcesBlock template context", function() {
				var modulePath = expandPath("/cli/lucli/Module.cfc");
				expect(fileExists(modulePath)).toBeTrue();

				var moduleSrc = fileRead(modulePath);

				expect(moduleSrc contains "datasourcesBlock").toBeTrue(
					"Module.cfc::scaffoldNewApp() should compute a 'datasourcesBlock' value into the template context based on opts.noSQLite so the rendered lucee.json honors --no-sqlite. Issue 2621."
				);
			});

		});

	}

}
