component extends="wheels.WheelsTest" {

	function beforeAll() {
		adapter = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBModel");
		migrator = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBMigrator");
	}

	function run() {

		describe("CockroachDB Adapter Unit Tests", () => {

			describe("$getType", () => {

				it("maps boolean to cf_sql_boolean", () => {
					expect(adapter.$getType(type = "boolean")).toBe("cf_sql_boolean");
				});

				it("maps bool to cf_sql_boolean", () => {
					expect(adapter.$getType(type = "bool")).toBe("cf_sql_boolean");
				});

				it("maps bit to cf_sql_bit", () => {
					expect(adapter.$getType(type = "bit")).toBe("cf_sql_bit");
				});

				it("maps varbit to cf_sql_bit", () => {
					expect(adapter.$getType(type = "varbit")).toBe("cf_sql_bit");
				});

				it("delegates varchar to PostgreSQL parent", () => {
					expect(adapter.$getType(type = "varchar")).toBe("cf_sql_varchar");
				});

				it("maps integer to cf_sql_bigint (CockroachDB default INT is 64-bit)", () => {
					expect(adapter.$getType(type = "integer")).toBe("cf_sql_bigint");
				});

				it("maps int to cf_sql_bigint", () => {
					expect(adapter.$getType(type = "int")).toBe("cf_sql_bigint");
				});

				it("maps int4 to cf_sql_bigint", () => {
					expect(adapter.$getType(type = "int4")).toBe("cf_sql_bigint");
				});

				it("maps serial to cf_sql_bigint", () => {
					expect(adapter.$getType(type = "serial")).toBe("cf_sql_bigint");
				});

				it("delegates text to PostgreSQL parent", () => {
					expect(adapter.$getType(type = "text")).toBe("cf_sql_longvarchar");
				});

				it("delegates timestamp to PostgreSQL parent", () => {
					expect(adapter.$getType(type = "timestamp")).toBe("cf_sql_timestamp");
				});
			});

			describe("$generatedKey", () => {

				it("returns lastId", () => {
					expect(adapter.$generatedKey()).toBe("lastId");
				});
			});

			describe("$identitySelect", () => {

				it("returns lastId from result.generatedKey", () => {
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')",
						generatedKey = "42"
					};
					var rv = adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("lastId");
					expect(rv.lastId).toBe("42");
				});

				it("returns lastId from returningIdentity query", () => {
					var mockQuery = QueryNew("id", "integer", [{id: 99}]);
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')"
					};
					var rv = adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = mockQuery
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("lastId");
					expect(rv.lastId).toBe(99);
				});

				it("returns void when primary key is in the INSERT column list", () => {
					var result = {
						sql = "INSERT INTO users (id, firstname) VALUES (1, 'test')"
					};
					// CFML void functions don't return null — the variable simply
					// won't exist. Use IsNull() on the raw call to verify no return.
					expect(IsNull(adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = ""
					))).toBeTrue();
				});

				it("returns void for non-INSERT statements", () => {
					var result = {
						sql = "SELECT * FROM users WHERE id = 1"
					};
					expect(IsNull(adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = ""
					))).toBeTrue();
				});

				it("returns lastId when result already has lastId key", () => {
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')",
						lastId = 10
					};
					var rv = adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv.lastId).toBe(10);
				});
			});

			describe("CockroachDB Migrator", () => {

				it("returns CockroachDB as adapter name", () => {
					expect(migrator.adapterName()).toBe("CockroachDB");
				});

				it("replaces INTEGER with unique_rowid() when autoIncrement is true", () => {
					var result = migrator.addPrimaryKeyOptions(
						sql = "id INTEGER",
						options = {autoIncrement: true}
					);
					expect(result).toBe("id INT DEFAULT unique_rowid() PRIMARY KEY");
				});

				it("does not replace INTEGER when autoIncrement is false", () => {
					var result = migrator.addPrimaryKeyOptions(
						sql = "id INTEGER",
						options = {autoIncrement: false}
					);
					expect(result).toBe("id INTEGER PRIMARY KEY");
				});

				it("appends PRIMARY KEY even without options", () => {
					var result = migrator.addPrimaryKeyOptions(sql = "id INTEGER");
					expect(result).toBe("id INTEGER PRIMARY KEY");
				});
			});
		});
	}

}
