/**
 * #4413: `wheels new --setup-h2` configures H2 in config/app.cfm but left the
 * SQLite JDBC datasource entries in lucee.json, so the two files disagreed about
 * the app's database. The lucee.json datasource block must be empty for --setup-h2,
 * the same as it already is for --no-sqlite.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	private any function mutedModule() {
		var m = new cli.lucli.Module(cwd = expandPath("/"));
		prepareMock(m);
		m.$("out");
		makePublic(m, "$newTemplateContext");
		return m;
	}

	private struct function contextWith(required struct overrides) {
		var opts = {
			port: 59213,
			datasource: "h2app",
			reloadPassword: "r",
			luceeAdminPassword: "a",
			openBrowser: false,
			noSQLite: false,
			setupH2: false
		};
		structAppend(opts, arguments.overrides, true);
		return mutedModule().$newTemplateContext("h2app", opts);
	}

	function run() {

		describe("wheels new lucee.json datasources", () => {

			it("writes no datasource entries for --setup-h2", () => {
				expect(contextWith({setupH2: true}).datasourcesBlock).toBe("{}");
			});

			it("writes no datasource entries for --no-sqlite (unchanged)", () => {
				expect(contextWith({noSQLite: true}).datasourcesBlock).toBe("{}");
			});

			it("still writes the SQLite datasource pair for a default embedded DB", () => {
				var block = contextWith({}).datasourcesBlock;
				expect(block).notToBe("{}");
				expect(block).toInclude("h2app");
			});

		});

	}

}
