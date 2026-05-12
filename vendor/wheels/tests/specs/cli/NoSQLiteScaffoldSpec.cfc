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
