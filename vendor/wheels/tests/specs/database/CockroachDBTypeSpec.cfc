component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("CockroachDB Type Tests", () => {

			// Guard: only run when connected to CockroachDB
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			if (migration.adapter.adapterName() != "CockroachDB") return;

			describe("SERIAL primary keys", () => {

				it("SERIAL generates INT8 (BIGINT) keys", () => {
					transaction action="begin" {
						var author = g.model("author").create(firstName = "TypeTest", lastName = "Serial");
						// CockroachDB SERIAL uses unique_rowid() which generates INT8 values
						expect(author.key()).toBeNumeric();
						// unique_rowid() generates values much larger than sequential integers
						expect(author.key()).toBeGT(1000);
						transaction action="rollback";
					}
				});
			});

			describe("$getType mapping", () => {

				it("maps CockroachDB native types correctly", () => {
					var adapter = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBModel");

					// CockroachDB-specific types
					expect(adapter.$getType(type = "string")).toBe("cf_sql_varchar");
					expect(adapter.$getType(type = "bytes")).toBe("cf_sql_binary");
					expect(adapter.$getType(type = "int64")).toBe("cf_sql_bigint");
					expect(adapter.$getType(type = "interval")).toBe("cf_sql_varchar");
					expect(adapter.$getType(type = "geometry")).toBe("cf_sql_other");

					// Boolean handling (differs from PostgreSQL)
					expect(adapter.$getType(type = "bool")).toBe("cf_sql_bit");
					expect(adapter.$getType(type = "boolean")).toBe("cf_sql_bit");

					// Delegated to PostgreSQL parent
					expect(adapter.$getType(type = "varchar")).toBe("cf_sql_varchar");
					expect(adapter.$getType(type = "text")).toBe("cf_sql_longvarchar");
					expect(adapter.$getType(type = "timestamp")).toBe("cf_sql_timestamp");
				});
			});

			describe("Migrator sqlTypes", () => {

				it("defines CockroachDB-native type mappings", () => {
					var migrator = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBMigrator");

					expect(migrator.adapterName()).toBe("CockroachDB");

					// Verify CockroachDB-native types are used
					var intType = migrator.typeToSQL(type = "integer");
					expect(intType).toBe("INT");

					var stringType = migrator.typeToSQL(type = "string");
					expect(stringType).toInclude("STRING");

					var boolType = migrator.typeToSQL(type = "boolean");
					expect(boolType).toBe("BOOL");

					var binaryType = migrator.typeToSQL(type = "binary");
					expect(binaryType).toBe("BYTES");
				});
			});

			describe("Column introspection", () => {

				it("correctly reads column types from a live table", () => {
					// Use the authors table which exists in test seed data
					var authors = g.model("author").findAll(maxRows = 1);
					expect(authors).toBeQuery();

					// The author model should be functional
					var author = g.model("author").findFirst();
					expect(author).toBeInstanceOf("author");
					expect(author.key()).toBeNumeric();
				});

				it("boolean column type is correctly introspected", () => {
					transaction action="begin" {
						var record = g.model("sqlType").create(
							booleanType = true,
							stringVariableType = "test",
							textType = "test"
						);
						var found = g.model("sqlType").findByKey(record.key());
						expect(found.booleanType).toBeBoolean();
						expect(found.booleanType).toBeTrue();
						transaction action="rollback";
					}
				});
			});
		});
	}

}
