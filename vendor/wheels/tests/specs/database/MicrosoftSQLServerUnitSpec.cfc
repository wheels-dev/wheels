component extends="wheels.WheelsTest" {

	function beforeAll() {
		adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
	}

	function run() {

		describe("Microsoft SQL Server Adapter Unit Tests", () => {

			describe("$generatedKey", () => {

				it("returns identitycol", () => {
					expect(adapter.$generatedKey()).toBe("identitycol");
				});
			});

			describe("$identitySelect", () => {

				it("returns identitycol from result.generatedKey", () => {
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
					expect(rv).toHaveKey("identitycol");
					expect(rv.identitycol).toBe("42");
				});

				it("returns the first key when result.generatedKey is a list", () => {
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
					expect(rv).toHaveKey("identitycol");
					expect(rv.identitycol).toBe("42");
				});

				it("returns void when result already contains identitycol", () => {
					var result = {
						sql = "INSERT INTO users (firstname) VALUES ('test')",
						identitycol = "7"
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

				it("returns void when the primary key is in the insert column list", () => {
					var result = {
						sql = "INSERT INTO users (id, firstname) VALUES (1, 'test')",
						generatedKey = "42"
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
