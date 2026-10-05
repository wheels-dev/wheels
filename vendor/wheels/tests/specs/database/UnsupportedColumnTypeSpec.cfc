/**
 * A column type a migrator has no SQL type for (#4095). typeToSQL() returned "" and the column
 * was emitted with no type: a DDL syntax error on most databases, a raw missing-key error on
 * Oracle, and on SQLite a typeless column whose model failed to load. The migrator now throws
 * Wheels.Migrator.UnsupportedColumnType, naming the type and the adapter, before any DDL runs.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.adapterNames = "CockroachDB,H2,MicrosoftSQLServer,MySQL,Oracle,PostgreSQL,SQLite";
		// Every type a TableDefinition helper emits (string(), integer(), char(), timestamps(), ...).
		variables.helperTypes = "biginteger,binary,boolean,char,date,datetime,decimal,float,integer,string,text,time,uniqueidentifier";
	}

	function afterAll() {
		// The spec expects the table never to be created; drop it in case a regression made it.
		try {
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			migration.dropTable("c_o_r_e_unmappedtypes");
		} catch (any e) {
		}
	}

	function migrator(required string name) {
		return CreateObject("component", "wheels.databaseAdapters.#arguments.name#.#arguments.name#Migrator");
	}

	// The error a column of this type throws when its SQL is built, or empty fields when it doesn't.
	function columnError(required any adapter, required string type) {
		var state = {type = "", message = "", extendedInfo = ""};
		var column = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = arguments.adapter, name = "c", type = arguments.type);
		try {
			column.toSQL();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
			state.extendedInfo = e.extendedInfo;
		}
		return state;
	}

	function run() {

		describe("A column type the migrator doesn't map", () => {

			it("throws Wheels.Migrator.UnsupportedColumnType naming the type and adapter on every adapter", () => {
				for (var name in ListToArray(variables.adapterNames)) {
					var adapter = migrator(name);
					var thrown = columnError(adapter, "jsonb");
					expect(thrown.type).toBe("Wheels.Migrator.UnsupportedColumnType", name);
					expect(thrown.message).toBe("Column type `jsonb` is not supported by the #adapter.adapterName()# migrator.", name);
					expect(thrown.extendedInfo).toInclude("Supported column types: ", name);
					expect(thrown.extendedInfo).toInclude("string", name);
				}
			});

			it("fails createTable() before the table is created", () => {
				var migration = CreateObject("component", "wheels.migrator.Migration").init();
				var state = {type = "", tableMissing = false};
				var t = migration.createTable(name = "c_o_r_e_unmappedtypes");
				t.string(columnNames = "name");
				t.column(columnName = "payload", columnType = "nonsense");
				try {
					t.create();
				} catch (any e) {
					state.type = e.type;
				}
				try {
					QueryExecute("SELECT COUNT(*) AS n FROM c_o_r_e_unmappedtypes", [], {datasource = application.wo.get("dataSourceName")});
				} catch (any e) {
					state.tableMissing = true;
				}
				expect(state.type).toBe("Wheels.Migrator.UnsupportedColumnType");
				expect(state.tableMissing).toBeTrue();
			});

		});

		describe("Every TableDefinition helper type", () => {

			// A regression lock: #4092 (t.char()) and #4094 (t.uniqueidentifier()) were types a
			// helper emitted that some adapter didn't map.
			it("maps to a SQL type on every adapter", () => {
				for (var name in ListToArray(variables.adapterNames)) {
					var adapter = migrator(name);
					for (var type in ListToArray(variables.helperTypes)) {
						expect(columnError(adapter, type).type).toBe("", name & " " & type);
						expect(Len(adapter.typeToSQL(type = type))).toBeGT(0, name & " " & type);
					}
				}
				var mysql = migrator("MySQL");
				for (var type in ["mediumtext", "longtext"]) {
					expect(Len(mysql.typeToSQL(type = type))).toBeGT(0, "MySQL " & type);
				}
			});

		});

	}

}
