/**
 * migrate diff accuracy (4405, 4406, 4419):
 * - on SQLite, DATETIME / DATE / TIME columns (bound as varchar by the model) are not
 *   reported as type changes;
 * - the all-models diff covers every model file, not only the models already loaded;
 * - a written migration uses the same 14-digit version as generated migrations.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
		variables.ds = application.wheels.dataSourceName;
		variables.table = "c_o_r_e_difftimestamps";
		variables.isSqlite = variables.autoMigrator.$getDBType() == "sqlite";
		if (variables.isSqlite) {
			$dropTable();
			QueryExecute(
				"CREATE TABLE #variables.table# (id INTEGER NOT NULL PRIMARY KEY, createdat DATETIME NOT NULL, birthday DATE NULL, alarm TIME NULL)",
				[],
				{datasource = variables.ds}
			);
		}
	}

	function afterAll() {
		if (variables.isSqlite) {
			$dropTable();
		}
		StructDelete(application.wheels.models, "DiffTimestamp");
	}

	private void function $dropTable() {
		try {
			QueryExecute("DROP TABLE #variables.table#", [], {datasource = variables.ds});
		} catch (any e) {
		}
	}

	function run() {

		describe("migrate diff on SQLite date columns (4405)", () => {

			beforeEach(() => {
				if (!variables.isSqlite) {
					skip("SQLite binds date columns as varchar; other adapters map them directly");
				}
			});

			it("treats datetime, date and time as equivalent to the model's string type", () => {
				expect(variables.autoMigrator.$normalizeMigTypeForDiff("datetime", "string")).toBe("string");
				expect(variables.autoMigrator.$normalizeMigTypeForDiff("date", "string")).toBe("string");
				expect(variables.autoMigrator.$normalizeMigTypeForDiff("time", "string")).toBe("string");
			});

			it("reports no change for DATETIME, DATE and TIME columns that match their model", () => {
				var result = variables.autoMigrator.diff("DiffTimestamp");
				var changed = [];
				for (var col in result.changeColumns) {
					ArrayAppend(changed, col.name & " (" & col.from.type & " -> " & col.to.type & ")");
				}
				expect(ArrayToList(changed, ", ")).toBe("");
			});

		});

		describe("migrate diff across all models (4406)", () => {

			it("includes a model file that has not been loaded yet", () => {
				var cache = application.wheels.models;
				var saved = StructKeyExists(cache, "Author") ? cache["Author"] : "";
				StructDelete(cache, "Author");
				try {
					var names = variables.autoMigrator.$diffableModelNames();
				} finally {
					if (!IsSimpleValue(saved)) {
						cache["Author"] = saved;
					}
				}
				expect(ArrayFindNoCase(names, "Author")).toBeGT(0);
			});

			it("lists each model once and skips the base Model.cfc", () => {
				var names = variables.autoMigrator.$diffableModelNames();
				var seen = {};
				var dupes = [];
				for (var name in names) {
					if (StructKeyExists(seen, name)) {
						ArrayAppend(dupes, name);
					}
					seen[name] = true;
				}
				expect(ArrayToList(dupes)).toBe("");
				expect(ArrayFindNoCase(names, "Model")).toBe(0);
			});

		});

		describe("migration file written by migrate diff (4419)", () => {

			it("uses a 14-digit version", () => {
				var dir = GetTempDirectory() & "wheels-diff-" & CreateUUID() & "/";
				DirectoryCreate(dir);
				try {
					var fileName = variables.autoMigrator.$migrationFileName("fix posts", dir);
				} finally {
					DirectoryDelete(dir, true);
				}
				expect(ReFind("^[0-9]{14}_fix_posts\.cfc$", fileName)).toBe(1);
			});

			it("moves to the next free second when the version is already taken", () => {
				var dir = GetTempDirectory() & "wheels-diff-" & CreateUUID() & "/";
				DirectoryCreate(dir);
				try {
					var first = variables.autoMigrator.$migrationFileName("one", dir);
					FileWrite(dir & first, "");
					var second = variables.autoMigrator.$migrationFileName("two", dir);
				} finally {
					DirectoryDelete(dir, true);
				}
				expect(Left(second, 14)).notToBe(Left(first, 14));
				expect(ReFind("^[0-9]{14}_two\.cfc$", second)).toBe(1);
			});

		});

	}

}
