/**
 * t.bigInteger() must declare BIGINT on SQLite (#4089). It declared INTEGER, which
 * Wheels types as cf_sql_integer, so Adobe ColdFusion rejected values above
 * 2,147,483,647 at bind time. BIGINT has the same INTEGER affinity (64-bit storage)
 * and is typed cf_sql_bigint. A biginteger PRIMARY KEY stays INTEGER: only a column
 * declared exactly INTEGER PRIMARY KEY is SQLite's rowid alias, which auto-generates
 * ids and may carry AUTOINCREMENT.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.isSQLite = variables.migration.adapter.adapterName() == "SQLite";
		variables.sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteMigrator");
		variables.valueTable = "c_o_r_e_bigvalues";
		variables.pkTable = "c_o_r_e_sqlitebigpks";
	}

	function afterAll() {
		variables.migration.dropTable(variables.valueTable);
		variables.migration.dropTable(variables.pkTable);
	}

	// Drops a model and its memoized column metadata, so the next model() call
	// re-reads the table after a schema change.
	function reloadModel(required string modelName, required string tableName) {
		StructDelete(application.wheels.models, arguments.modelName);
		if (StructKeyExists(application.wheels, "schemaColumnCache")) {
			StructDelete(application.wheels.schemaColumnCache, Hash(application.wo.get("dataSourceName") & Chr(31) & arguments.tableName));
		}
	}

	function declaredType(required string tableName, required string columnName) {
		var info = QueryExecute("PRAGMA table_info(#arguments.tableName#)", [], {datasource = application.wo.get("dataSourceName")});
		for (var row in info) {
			if (CompareNoCase(row.name, arguments.columnName) == 0) {
				return UCase(row.type);
			}
		}
		return "missing";
	}

	function run() {

		describe("SQLite DDL for a biginteger column", () => {

			it("declares BIGINT", () => {
				expect(variables.sqlite.typeToSQL(type = "biginteger")).toBe("BIGINT");
			});

			it("keeps a biginteger primary key as INTEGER PRIMARY KEY, the rowid alias", () => {
				var auto = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = variables.sqlite, name = "id", type = "biginteger", autoIncrement = true);
				expect(auto.toPrimaryKeySQL()).toInclude("INTEGER PRIMARY KEY AUTOINCREMENT");
				expect(auto.toPrimaryKeySQL()).notToInclude("BIGINT");
				var plain = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = variables.sqlite, name = "id", type = "biginteger");
				expect(plain.toPrimaryKeySQL()).toInclude("INTEGER PRIMARY KEY");
				expect(plain.toPrimaryKeySQL()).notToInclude("BIGINT");
			});

		});

		describe("A bigInteger column created by the migrator", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.valueTable, force = true);
				t.bigInteger(columnNames = "amount");
				t.create();
				reloadModel("BigValue", variables.valueTable);
			});

			it("stores and reads back a value above the 32-bit range", () => {
				var row = model("BigValue").create(amount = 9000000000);
				expect(row.hasErrors()).toBeFalse(SerializeJSON(row.allErrors()));
				expect(model("BigValue").findByKey(row.key()).amount).toBe(9000000000);
				expect(model("BigValue").findOne(where = "amount = 9000000000").key()).toBe(row.key());
			});

			it("is typed as a 64-bit integer on SQLite", () => {
				if (!variables.isSQLite) {
					skip("Checks SQLite's declared type, not `#variables.migration.adapter.adapterName()#`.");
				}
				expect(declaredType(variables.valueTable, "amount")).toBe("BIGINT");
				expect(model("BigValue").$classData().properties.amount.type).toBe("cf_sql_bigint");
			});

		});

		describe("A biginteger primary key on SQLite", () => {

			it("still auto-generates ids", () => {
				if (!variables.isSQLite) {
					skip("The rowid alias is SQLite-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				var t = variables.migration.createTable(name = variables.pkTable, id = false, force = true);
				t.primaryKey(columnNames = "id", type = "biginteger", autoIncrement = true);
				t.string(columnNames = "label");
				t.create();
				reloadModel("SqliteBigPk", variables.pkTable);

				expect(declaredType(variables.pkTable, "id")).toBe("INTEGER");
				var first = model("SqliteBigPk").create(label = "a");
				var second = model("SqliteBigPk").create(label = "b");
				expect(IsNumeric(first.key()) && first.key() > 0).toBeTrue(first.key());
				expect(second.key()).toBeGT(first.key());
			});

		});

		// Upgrade path for a column an earlier version created as INTEGER.
		describe("A legacy SQLite INTEGER big-integer column", () => {

			it("becomes BIGINT through changeColumn() and keeps its data and index", () => {
				if (!variables.isSQLite) {
					skip("Legacy INTEGER columns are SQLite-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				var t = variables.migration.createTable(name = variables.valueTable, force = true);
				t.string(columnNames = "label");
				t.create();
				variables.migration.execute("ALTER TABLE #variables.valueTable# ADD COLUMN amount INTEGER");
				variables.migration.addIndex(table = variables.valueTable, columnNames = "amount", indexName = "idx_bigvalues_amount");
				variables.migration.execute("INSERT INTO #variables.valueTable# (label, amount) VALUES ('kept', 1234)");

				variables.migration.changeColumn(table = variables.valueTable, columnName = "amount", columnType = "biginteger");

				expect(declaredType(variables.valueTable, "amount")).toBe("BIGINT");
				var indexes = QueryExecute("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = '#variables.valueTable#'", [], {datasource = application.wo.get("dataSourceName")});
				expect(ValueList(indexes.name)).toInclude("idx_bigvalues_amount");
				reloadModel("BigValue", variables.valueTable);
				var row = model("BigValue").findOne(where = "label = 'kept'");
				expect(row.amount).toBe(1234);
				expect(model("BigValue").$classData().properties.amount.type).toBe("cf_sql_bigint");
			});

		});

	}

}
