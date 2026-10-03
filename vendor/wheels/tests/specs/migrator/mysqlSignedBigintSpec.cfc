/**
 * t.bigInteger() must create a signed BIGINT on MySQL, like every other adapter
 * (#4121). It created BIGINT UNSIGNED, which rejects negative values, binds as a
 * decimal and validates as a float, and cannot take part in a foreign key with a
 * signed BIGINT. `unsigned = true` (t.bigInteger / t.integer) keeps an UNSIGNED
 * column for a foreign key to an existing unsigned id; other adapters ignore it.
 * changeColumn() keeps a column's current signedness, because MySQL refuses to
 * change the signedness of a column in a foreign key.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.isMySQL = variables.migration.adapter.adapterName() == "MySQL";
		variables.table = "c_o_r_e_bigcounts";
		variables.mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
	}

	function afterAll() {
		if (variables.isMySQL) {
			variables.migration.execute("DROP TABLE IF EXISTS c_o_r_e_bigcountchildren");
			variables.migration.execute("DROP TABLE IF EXISTS c_o_r_e_bigcountparents");
		}
		variables.migration.dropTable(variables.table);
	}

	// Drops the model and its memoized column metadata, so the next model() call
	// re-reads the table after a schema change.
	function reloadBigCount(required string tableName) {
		StructDelete(application.wheels.models, "BigCount");
		if (StructKeyExists(application.wheels, "schemaColumnCache")) {
			StructDelete(application.wheels.schemaColumnCache, Hash(application.wo.get("dataSourceName") & Chr(31) & arguments.tableName));
		}
	}

	function mysqlColumnType(required string tableName, required string columnName) {
		var q = QueryExecute(
			"SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '#arguments.tableName#' AND COLUMN_NAME = '#arguments.columnName#'",
			[],
			{datasource = application.wo.get("dataSourceName")}
		);
		return q.recordCount ? LCase(q.COLUMN_TYPE) : "missing";
	}

	function run() {

		describe("MySQL typeToSQL() for integer columns", () => {

			it("declares a signed BIGINT for biginteger", () => {
				expect(variables.mysql.typeToSQL(type = "biginteger")).toBe("BIGINT");
				expect(variables.mysql.typeToSQL(type = "integer")).toBe("INT");
			});

			it("adds UNSIGNED when unsigned is passed", () => {
				expect(variables.mysql.typeToSQL(type = "biginteger", options = {unsigned = true})).toBe("BIGINT UNSIGNED");
				expect(variables.mysql.typeToSQL(type = "integer", options = {unsigned = true})).toBe("INT UNSIGNED");
				expect(variables.mysql.typeToSQL(type = "biginteger", options = {unsigned = false})).toBe("BIGINT");
			});

			it("ignores unsigned on adapters without unsigned types", () => {
				for (var name in ["PostgreSQL", "SQLite", "H2", "Oracle", "MicrosoftSQLServer", "CockroachDB"]) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Migrator");
					expect(adapter.typeToSQL(type = "biginteger", options = {unsigned = true})).notToInclude("UNSIGNED", name);
				}
			});

		});

		describe("A bigInteger column created by the migrator", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.bigInteger(columnNames = "total");
				t.create();
				reloadBigCount(variables.table);
			});

			it("validates as an integer, rejects a fraction and stores a negative value", () => {
				expect(model("BigCount").$classData().properties.total.validationtype).toBe("integer");
				expect(model("BigCount").new(total = 1.5).valid()).toBeFalse();
				var row = model("BigCount").create(total = -5);
				expect(row.hasErrors()).toBeFalse();
				expect(model("BigCount").findByKey(row.key()).total).toBe(-5);
			});

		});

		describe("MySQL unsigned integer columns", () => {

			// The upgrade case: an id created by an earlier version is BIGINT UNSIGNED.
			beforeEach(() => {
				if (!variables.isMySQL) {
					return;
				}
				variables.migration.execute("DROP TABLE IF EXISTS c_o_r_e_bigcountchildren");
				variables.migration.execute("DROP TABLE IF EXISTS c_o_r_e_bigcountparents");
				variables.migration.execute("CREATE TABLE c_o_r_e_bigcountparents (id BIGINT UNSIGNED NOT NULL PRIMARY KEY)");
				variables.migration.execute("INSERT INTO c_o_r_e_bigcountparents (id) VALUES (1)");
			});

			it("creates an UNSIGNED column that can reference an existing unsigned id", () => {
				if (!variables.isMySQL) {
					skip("Unsigned columns are MySQL-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				var t = variables.migration.createTable(name = "c_o_r_e_bigcountchildren", force = true);
				t.bigInteger(columnNames = "parentId", unsigned = true);
				t.integer(columnNames = "position", unsigned = true);
				t.create();
				variables.migration.execute("ALTER TABLE c_o_r_e_bigcountchildren ADD FOREIGN KEY (parentId) REFERENCES c_o_r_e_bigcountparents (id)");
				variables.migration.execute("INSERT INTO c_o_r_e_bigcountchildren (parentId, position) VALUES (1, 1)");

				expect(mysqlColumnType("c_o_r_e_bigcountchildren", "parentId")).toBe("bigint unsigned");
				expect(mysqlColumnType("c_o_r_e_bigcountchildren", "position")).toBe("int unsigned");
			});

			it("keeps a legacy unsigned foreign key column unsigned through changeColumn()", () => {
				if (!variables.isMySQL) {
					skip("Unsigned columns are MySQL-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				variables.migration.execute("CREATE TABLE c_o_r_e_bigcountchildren (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, parentId BIGINT UNSIGNED, FOREIGN KEY (parentId) REFERENCES c_o_r_e_bigcountparents (id))");
				variables.migration.execute("INSERT INTO c_o_r_e_bigcountchildren (parentId) VALUES (1)");

				variables.migration.changeColumn(table = "c_o_r_e_bigcountchildren", columnName = "parentId", columnType = "biginteger", allowNull = true);

				expect(mysqlColumnType("c_o_r_e_bigcountchildren", "parentId")).toBe("bigint unsigned");
			});

		});

	}

}
