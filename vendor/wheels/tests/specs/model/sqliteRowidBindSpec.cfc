/**
 * SQLite stores every integer as up to 64 bits, and an INTEGER PRIMARY KEY id is the
 * 64-bit rowid. Wheels typed INTEGER columns as cf_sql_integer, so an id or value
 * above 2,147,483,647 was rejected on Adobe ColdFusion, clamped to 2,147,483,647 on
 * Lucee and wrapped on BoxLang: a lookup by such an id could hit a different row
 * (#4142). INTEGER columns are now typed cf_sql_bigint.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.isSQLite = variables.migration.adapter.adapterName() == "SQLite";
		variables.table = "c_o_r_e_rowidbigs";
	}

	function afterAll() {
		variables.migration.dropTable(variables.table);
	}

	// Drops the model and its memoized column metadata, so the next model() call
	// re-reads the table after a schema change.
	function reloadRowidBig(required string tableName) {
		StructDelete(application.wheels.models, "RowidBig");
		if (StructKeyExists(application.wheels, "schemaColumnCache")) {
			StructDelete(application.wheels.schemaColumnCache, Hash(application.wo.get("dataSourceName") & Chr(31) & arguments.tableName));
		}
	}

	function run() {

		describe("SQLite INTEGER columns", () => {

			it("are typed as 64-bit integers", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
				expect(adapter.$getType(type = "INTEGER")).toBe("cf_sql_bigint");
				expect(adapter.$getType(type = "INT")).toBe("cf_sql_bigint");
				expect(adapter.$getValidationType("CF_SQL_BIGINT")).toBe("integer");
			});

		});

		describe("A SQLite row whose id is above 2^31", () => {

			beforeEach(() => {
				if (!variables.isSQLite) {
					return;
				}
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.string(columnNames = "label");
				t.integer(columnNames = "counter");
				t.create();
				// 2147483647 is where Lucee clamps; 410065408 is 9000000000 wrapped mod 2^32 (BoxLang).
				variables.migration.execute("INSERT INTO #variables.table# (id, label, counter) VALUES (2147483647, 'clamp target', 1)");
				variables.migration.execute("INSERT INTO #variables.table# (id, label, counter) VALUES (410065408, 'wrap target', 1)");
				variables.migration.execute("INSERT INTO #variables.table# (id, label, counter) VALUES (9000000000, 'big', 1)");
				reloadRowidBig(variables.table);
			});

			it("is found by key", () => {
				if (!variables.isSQLite) {
					skip("Rowid ids are SQLite-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				var row = model("RowidBig").findByKey(9000000000);
				expect(IsObject(row)).toBeTrue("no row found for id 9000000000");
				expect(row.label).toBe("big");
			});

			it("updates only that row", () => {
				if (!variables.isSQLite) {
					skip("Rowid ids are SQLite-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				var row = model("RowidBig").findByKey(9000000000);
				row.update(counter = 2);
				var counters = QueryExecute("SELECT id, counter FROM #variables.table# ORDER BY id", [], {datasource = application.wo.get("dataSourceName")});
				expect(ValueList(counters.counter)).toBe("1,1,2");
			});

			it("deletes only that row", () => {
				if (!variables.isSQLite) {
					skip("Rowid ids are SQLite-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				model("RowidBig").deleteByKey(9000000000);
				var labels = QueryExecute("SELECT label FROM #variables.table# ORDER BY id", [], {datasource = application.wo.get("dataSourceName")});
				expect(ValueList(labels.label)).toBe("wrap target,clamp target");
			});

			it("stores an integer column value above 2^31", () => {
				if (!variables.isSQLite) {
					skip("SQLite-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				var row = model("RowidBig").create(label = "counted", counter = 9000000000);
				expect(model("RowidBig").findByKey(row.key()).counter).toBe(9000000000);
			});

		});

	}

}
