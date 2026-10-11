/**
 * `wheels new` apps build their paths from public/Application.cfc's own directory, not
 * expandPath("../...") (4470). expandPath() resolves against the requested page's
 * directory, so a .cfm in a subfolder of public/ got mappings and SQLite/H2 paths
 * pointing inside public/ and failed to start.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.templateRoot = expandPath("/cli/lucli/templates/app/");
	}

	// Code lines (not // comments) of a file that call expandPath("../...").
	private array function $relativeExpandPathLines(required string content) {
		var hits = [];
		for (var line in listToArray(arguments.content, chr(10))) {
			if (left(trim(line), 2) != "//" && reFindNoCase('expandPath\(\s*["'']\.\./', line)) {
				arrayAppend(hits, trim(line));
			}
		}
		return hits;
	}

	// A scratch project holding a copy of the template's config/app.cfm.
	private string function $scratchProject() {
		var root = getTempDirectory() & "wheels-app-paths-" & createUUID();
		directoryCreate(root & "/config", true);
		fileCopy(templateRoot & "config/app.cfm", root & "/config/app.cfm");
		return root;
	}

	function run() {

		describe("wheels new paths anchored to public/Application.cfc (4470)", () => {

			it("builds every mapping in public/Application.cfc without expandPath(""../"")", () => {
				var content = fileRead(templateRoot & "public/Application.cfc");
				expect(arrayToList($relativeExpandPathLines(content), " | ")).toBe("");
				expect(content).toInclude("this.wheels.projectRoot = REReplace(this.wheels.rootPath");
			});

			it("writes the SQLite datasources from this.wheels.projectRoot", () => {
				var root = $scratchProject();
				var m = new cli.lucli.Module(cwd = root);
				makePublic(m, "configureSQLiteDatabase");
				try {
					m.configureSQLiteDatabase(root, "probe", "probe");
					var content = fileRead(root & "/config/app.cfm");
				} finally {
					directoryDelete(root, true);
				}
				expect(content).toInclude('this.wheels.projectRoot & "db/development.sqlite"');
				expect(content).toInclude('this.wheels.projectRoot & "db/test.sqlite"');
				expect(arrayToList($relativeExpandPathLines(content), " | ")).toBe("");
			});

			it("writes the H2 datasources from this.wheels.projectRoot", () => {
				var root = $scratchProject();
				var m = new cli.lucli.Module(cwd = root);
				makePublic(m, "configureH2Database");
				try {
					m.configureH2Database(root, "probe", "probe");
					var content = fileRead(root & "/config/app.cfm");
				} finally {
					directoryDelete(root, true);
				}
				expect(content).toInclude('this.wheels.projectRoot & "db/h2/probe;MODE=MySQL"');
				expect(arrayToList($relativeExpandPathLines(content), " | ")).toBe("");
			});

		});

	}

}
