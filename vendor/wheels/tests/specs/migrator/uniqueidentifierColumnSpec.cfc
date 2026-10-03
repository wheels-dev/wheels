/**
 * t.uniqueidentifier() must create a typed UUID column on every adapter (#4094).
 * Only SQL Server mapped the type; elsewhere typeToSQL() returned "" (Oracle: a
 * raw missing-key error) and the SQL Server-only `newid()` default was emitted
 * as is. Each adapter now declares a UUID type and swaps `newid()` for its own
 * generator; PostgreSQL binds `uuid` columns as cf_sql_other, which its driver
 * accepts for a string value.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.adapterName = variables.migration.adapter.adapterName();
		variables.table = "c_o_r_e_uuidthings";
		variables.keyedTable = "c_o_r_e_uuidkeyeds";
		// 8-4-4-4-12 hex; the version nibble varies by generator (Oracle's SYS_GUID() is not v4).
		variables.uuidPattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$";
		variables.v4Pattern = "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$";
	}

	function afterAll() {
		variables.migration.dropTable(variables.table);
		variables.migration.dropTable(variables.keyedTable);
	}

	// Drops a model and its memoized column metadata, so the next model() call
	// re-reads the table after a schema change.
	function reloadUuidModel(required string modelName, required string tableName) {
		StructDelete(application.wheels.models, arguments.modelName);
		if (StructKeyExists(application.wheels, "schemaColumnCache")) {
			StructDelete(application.wheels.schemaColumnCache, Hash(application.wo.get("dataSourceName") & Chr(31) & arguments.tableName));
		}
	}

	function run() {

		describe("typeToSQL() for a uniqueidentifier column", () => {

			it("declares a UUID type on every adapter", () => {
				var expected = {
					"MicrosoftSQLServer" = "UNIQUEIDENTIFIER",
					"PostgreSQL" = "UUID",
					"CockroachDB" = "UUID",
					"H2" = "UUID",
					"MySQL" = "CHAR(36)",
					"SQLite" = "CHAR(36)",
					"Oracle" = "CHAR(36)"
				};
				for (var name in expected) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Migrator");
					expect(adapter.typeToSQL(type = "uniqueidentifier")).toBe(expected[name], name);
				}
			});

			it("swaps the newid() default for each adapter's generator", () => {
				for (var name in ["MicrosoftSQLServer", "PostgreSQL", "CockroachDB", "H2", "MySQL", "SQLite", "Oracle"]) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Migrator");
					var column = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = adapter, name = "token", type = "uniqueidentifier", default = "newid()", allowNull = false);
					var sqlText = column.toSQL();
					expect(sqlText).toInclude("DEFAULT", name);
					if (name != "MicrosoftSQLServer") {
						expect(sqlText).notToInclude("newid()", name);
					}
				}
			});

			it("omits the default where the server has no generator, instead of emitting failing DDL", () => {
				for (var name in ["MySQL", "PostgreSQL"]) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Migrator");
					adapter.$setUuidDefaultSupported(false);
					var column = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = adapter, name = "token", type = "uniqueidentifier", default = "newid()", allowNull = false);
					expect(column.toSQL()).notToInclude("DEFAULT", name);
				}
			});

		});

		describe("The UUID default version floor", () => {

			it("reads PostgreSQL 13+, MySQL 8.0.13+ and MariaDB 10.2+ as able to generate one", () => {
				var probe = variables.migration;
				expect(probe.$uuidDefaultVersionSupported(dbType = "PostgreSQL", version = "12.17 (Debian 12.17-1)")).toBeFalse();
				expect(probe.$uuidDefaultVersionSupported(dbType = "PostgreSQL", version = "13.0")).toBeTrue();
				expect(probe.$uuidDefaultVersionSupported(dbType = "PostgreSQL", version = "18.4 (Debian 18.4-1.pgdg13+1)")).toBeTrue();
				expect(probe.$uuidDefaultVersionSupported(dbType = "MySQL", version = "5.7.44")).toBeFalse();
				expect(probe.$uuidDefaultVersionSupported(dbType = "MySQL", version = "8.0.12")).toBeFalse();
				expect(probe.$uuidDefaultVersionSupported(dbType = "MySQL", version = "8.0.13")).toBeTrue();
				expect(probe.$uuidDefaultVersionSupported(dbType = "MySQL", version = "9.7.0")).toBeTrue();
				expect(probe.$uuidDefaultVersionSupported(dbType = "MySQL", version = "10.1.48-MariaDB")).toBeFalse();
				expect(probe.$uuidDefaultVersionSupported(dbType = "MySQL", version = "10.11.6-MariaDB-1:10.11.6+maria")).toBeTrue();
				expect(probe.$serverSupportsUuidDefault(dbType = "SQLite")).toBeTrue();
			});

		});

		describe("generateUUID()", () => {

			it("returns distinct 36-character version 4 UUIDs", () => {
				var seen = {};
				for (var i = 1; i <= 50; i++) {
					var value = application.wo.generateUUID();
					expect(Len(value)).toBe(36);
					expect(ReFind(variables.v4Pattern, value)).toBe(1, value);
					seen[value] = true;
				}
				expect(StructCount(seen)).toBe(50);
			});

			it("formats a version 4 UUID without Java", () => {
				for (var i = 1; i <= 50; i++) {
					var value = application.wo.$randomUuidV4();
					expect(ReFind(variables.v4Pattern, value)).toBe(1, value);
				}
			});

		});

		describe("A uniqueidentifier column created by the migrator", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.string(columnNames = "label");
				t.uniqueidentifier(columnNames = "token", allowNull = false);
				t.create();
				reloadUuidModel("UuidThing", variables.table);
			});

			it("is filled by the database default when no value is given", () => {
				var thing = model("UuidThing").create(label = "defaulted");
				var reloaded = model("UuidThing").findByKey(thing.key());
				expect(ReFind(variables.uuidPattern, Trim(reloaded.token))).toBe(1, reloaded.token);
			});

			it("stores a given UUID and finds rows by it, including in a list", () => {
				var first = application.wo.generateUUID();
				var second = application.wo.generateUUID();
				model("UuidThing").create(label = "first", token = first);
				model("UuidThing").create(label = "second", token = second);

				expect(model("UuidThing").findOne(where = "token = '#first#'").label).toBe("first");
				expect(model("UuidThing").count(where = "token IN ('#first#','#second#')")).toBe(2);
			});

		});

		// A server too old to generate a UUID in a default (PostgreSQL before 13) gets the
		// column without one; the model then fills a required native UUID column itself.
		describe("A required native UUID column without a default", () => {

			it("is filled with a generated UUID on create", () => {
				var native = {"PostgreSQL" = "UUID", "CockroachDB" = "UUID", "H2" = "UUID", "MicrosoftSQLServer" = "UNIQUEIDENTIFIER"};
				if (!StructKeyExists(native, variables.adapterName)) {
					skip("Native UUID columns are not available on `#variables.adapterName#`.");
				}
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.string(columnNames = "label");
				t.create();
				variables.migration.execute("ALTER TABLE #variables.table# ADD token #native[variables.adapterName]# NOT NULL");
				reloadUuidModel("UuidThing", variables.table);

				var thing = model("UuidThing").create(label = "filled");
				expect(thing.hasErrors()).toBeFalse();
				expect(ReFind(variables.v4Pattern, LCase(Trim(model("UuidThing").findByKey(thing.key()).token)))).toBe(1);
			});

		});

		describe("A uniqueidentifier primary key", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.keyedTable, id = false, force = true);
				t.primaryKey(columnNames = "guid", type = "uniqueidentifier", autoIncrement = false);
				t.string(columnNames = "label");
				t.create();
				reloadUuidModel("UuidKeyed", variables.keyedTable);
			});

			it("is generated on create and found by key", () => {
				var keyed = model("UuidKeyed").create(label = "keyed");
				expect(ReFind(variables.uuidPattern, Trim(keyed.key()))).toBe(1, keyed.key());
				expect(model("UuidKeyed").findByKey(keyed.key()).label).toBe("keyed");
			});

		});

	}

}
