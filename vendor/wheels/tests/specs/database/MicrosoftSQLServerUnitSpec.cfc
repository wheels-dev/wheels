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

			describe("$querySetup pagination", () => {

				it("retains GROUP BY in paginated SQL", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var sqlArr = [
						"SELECT users.id,users.name",
						"FROM users",
						"WHERE users.id > 0",
						"GROUP BY users.id,users.name",
						"ORDER BY users.id ASC"
					];
					var out = probe.$querySetup(sql = sqlArr, limit = 10, offset = 0, parameterize = true, $primaryKey = "id");
					var flat = ArrayToList(out.sql, " ");
					expect(flat).toInclude("GROUP BY");
					// The GROUP BY must precede the innermost ORDER BY inside the pagination sub-query.
					expect(REFindNoCase("GROUP BY.+ORDER BY", flat) > 0).toBeTrue();
				});

				it("keeps current pagination output for order columns absent from the select", () => {
					// Behavior-preservation pin: hoisting the $stripIdentifierQuotes
					// recompute out of the per-order-column loop must not change output.
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var sqlArr = [
						"SELECT users.id",
						"FROM users",
						"WHERE users.id > 0",
						"ORDER BY users.name ASC, users.createdat DESC"
					];
					var out = probe.$querySetup(sql = sqlArr, limit = 10, offset = 0, parameterize = true, $primaryKey = "id");
					var flat = ArrayToList(out.sql, " ");
					expect(flat).toBe(
						"SELECT id FROM (SELECT TOP 10 id,name,tmpSelect2 FROM (SELECT TOP 10 users.id,users.name, users.createdat AS tmpSelect2 FROM users WHERE users.id > 0 ORDER BY users.name ASC, users.createdat DESC) AS tmp1 ORDER BY name DESC,createdat ASC) AS tmp2 ORDER BY name ASC,createdat DESC"
					);
				});
			});

			describe("$querySetup same-batch identity retrieval", () => {

				it("appends a same-batch SCOPE_IDENTITY() select to INSERTs on engines without driver keys", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					probe.boxlangMode = true;
					var out = probe.$querySetup(
						sql = ["INSERT INTO users (firstname)", "VALUES ('x')"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = "id"
					);
					expect(out.sql[ArrayLen(out.sql)]).toBe(";SELECT SCOPE_IDENTITY() AS lastId");
				});

				it("leaves INSERTs untouched on engines that surface driver generated keys", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var out = probe.$querySetup(
						sql = ["INSERT INTO users (firstname)", "VALUES ('x')"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = "id"
					);
					expect(ArrayLen(out.sql)).toBe(2);
					expect(ArrayToList(out.sql, " ")).notToInclude("SCOPE_IDENTITY");
				});

				it("does not append on the bulk path (no primary key hint)", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					probe.boxlangMode = true;
					var out = probe.$querySetup(
						sql = ["INSERT INTO users (firstname)", "VALUES ('x'), ('y')"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = ""
					);
					expect(ArrayLen(out.sql)).toBe(2);
					expect(ArrayToList(out.sql, " ")).notToInclude("SCOPE_IDENTITY");
				});

				it("does not append to non-INSERT statements", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					probe.boxlangMode = true;
					var out = probe.$querySetup(
						sql = ["MERGE INTO users WITH (HOLDLOCK) AS target USING (VALUES ", "('x')", ") AS source (firstname) ON 1 = 0 WHEN NOT MATCHED THEN INSERT (firstname) VALUES (source.firstname);"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = "id"
					);
					expect(ArrayLen(out.sql)).toBe(3);
					expect(ArrayToList(out.sql, " ")).notToInclude("SCOPE_IDENTITY");
				});
			});

			describe("$lastIdLookup same-batch fallback", () => {

				it("reads the identity from the same-batch resultset without a second round-trip", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = QueryNew("lastId", "integer", [{lastId: 42}])
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("identitycol");
					expect(rv.identitycol).toBe(42);
					expect(ArrayLen(probe.capturedSql)).toBe(0);
				});

				it("falls back to @@IDENTITY when the batch surfaces no usable resultset", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 7}]));
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = QueryNew("lastId", "varchar", [])
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("identitycol");
					expect(rv.identitycol).toBe(7);
					expect(probe.capturedSql[1]).toInclude("@@IDENTITY");
				});
			});
		});
	}

}
