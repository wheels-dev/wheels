component extends="wheels.WheelsTest" {

	function beforeAll() {
		adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
	}

	function run() {

		describe("Oracle Adapter Unit Tests", () => {

			describe("$generatedKey", () => {

				it("returns lastId", () => {
					expect(adapter.$generatedKey()).toBe("lastId");
				});
			});

			describe("$identitySelect", () => {

				it("uses a numeric result.generatedKey directly", () => {
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

				it("uses a numeric result.rowid directly (ACF surface)", () => {
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')",
						rowid = "42"
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

				it("uses the first value when result.generatedKey is a numeric list", () => {
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')",
						generatedKey = "42,43"
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

				it("returns void when the primary key is in the insert column list", () => {
					var result = {
						sql = "INSERT INTO users (id, firstname) VALUES (1, 'test')",
						generatedKey = "42"
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

				it("returns void when result already has lastId key", () => {
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')",
						lastId = 10
					};
					expect(IsNull(adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = ""
					))).toBeTrue();
				});

				it("returns void for non-INSERT statements", () => {
					var result = {
						sql = "SELECT * FROM users WHERE id = 1",
						generatedKey = "42"
					};
					expect(IsNull(adapter.$identitySelect(
						queryAttributes = {},
						result = result,
						primaryKey = "id",
						returningIdentity = ""
					))).toBeTrue();
				});
			});
		});
	}

}
