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

				it("throws Wheels.IdentityNotFound when the batch surfaces no usable resultset", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var state = {type = ""};
					try {
						probe.$identitySelect(
							queryAttributes = {},
							result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
							primaryKey = "id",
							returningIdentity = QueryNew("lastId", "varchar", [])
						);
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.IdentityNotFound");
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("@@IDENTITY");
				});
			});

			// #3647: an INSERT that supplies its own identity value needs IDENTITY_INSERT.
			// The live behaviour is covered by model/explicitIdentityInsertSpec on the
			// sqlserver legs; these pin the statement on every leg.
			describe("$identityInsertSQL", () => {

				it("leaves an INSERT that does not supply the primary key unchanged", () => {
					var sql = [
						"INSERT INTO [c_o_r_e_refparents] (", "[name]", ")",
						" VALUES (", {value = "Generated", type = "cf_sql_varchar"}, ")"
					];
					var wrapped = adapter.$identityInsertSQL(sql = sql, primaryKey = "id");
					expect(ArrayLen(wrapped)).toBe(6);
					expect(wrapped[1]).toBe("INSERT INTO [c_o_r_e_refparents] (");
				});

				it("wraps an INSERT that supplies the primary key in a guarded ON/OFF pair", () => {
					var sql = [
						"INSERT INTO [c_o_r_e_refparents] (", "[id]", ",", "[name]", ")",
						" VALUES (", {value = 41, type = "cf_sql_integer"}, ",", {value = "Explicit", type = "cf_sql_varchar"}, ")"
					];
					var wrapped = adapter.$identityInsertSQL(sql = sql, primaryKey = "id");

					// One statement: the prefix, the untouched INSERT, the suffix.
					expect(ArrayLen(wrapped)).toBe(12);
					expect(wrapped[2]).toBe("INSERT INTO [c_o_r_e_refparents] (");

					// ON only when the supplied key really is the table's identity column:
					// SET IDENTITY_INSERT on a table without one is an error.
					expect(wrapped[1]).toInclude("sys.identity_columns");
					expect(wrapped[1]).toInclude("OBJECT_ID(N'[c_o_r_e_refparents]')");
					expect(wrapped[1]).toInclude("name IN (N'id')");
					expect(wrapped[1]).toInclude("SET IDENTITY_INSERT [c_o_r_e_refparents] ON");

					// The OFF rides in the same batch, so it shares the connection.
					expect(wrapped[12]).toInclude("SET IDENTITY_INSERT [c_o_r_e_refparents] OFF");
				});

				it("only names the primary-key columns the INSERT supplies", () => {
					var sql = [
						"INSERT INTO [c_o_r_e_combikeys] (", "[id1]", ",", "[userId]", ")",
						" VALUES (", {value = 1, type = "cf_sql_integer"}, ",", {value = 2, type = "cf_sql_integer"}, ")"
					];
					var wrapped = adapter.$identityInsertSQL(sql = sql, primaryKey = "ID1,id2");
					expect(wrapped[1]).toInclude("name IN (N'ID1')");
					expect(wrapped[1]).notToInclude("id2");
				});

				it("escapes single quotes in the identifiers it embeds as literals", () => {
					var sql = [
						"INSERT INTO [odd'table] (", "[o'id]", ")",
						" VALUES (", {value = 1, type = "cf_sql_integer"}, ")"
					];
					var wrapped = adapter.$identityInsertSQL(sql = sql, primaryKey = "o'id");
					expect(wrapped[1]).toInclude("OBJECT_ID(N'[odd''table]')");
					expect(wrapped[1]).toInclude("name IN (N'o''id')");
				});

				it("leaves an INSERT with no column list unchanged", () => {
					var sql = ["INSERT INTO [c_o_r_e_refparents] DEFAULT VALUES"];
					var wrapped = adapter.$identityInsertSQL(sql = sql, primaryKey = "id");
					expect(ArrayLen(wrapped)).toBe(1);
				});
			});

			describe("$querySetup explicit identity insert", () => {

				it("wraps an INSERT whose column list carries the primary key", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var out = probe.$querySetup(
						sql = ["INSERT INTO [users] (", "[id]", ",", "[firstname]", ")", " VALUES (41, 'x')"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = "id"
					);
					expect(out.sql[1]).toInclude("SET IDENTITY_INSERT [users] ON");
					expect(out.sql[ArrayLen(out.sql)]).toInclude("SET IDENTITY_INSERT [users] OFF");
				});

				it("does not also append SCOPE_IDENTITY() on BoxLang, since the key is already known", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					probe.boxlangMode = true;
					var out = probe.$querySetup(
						sql = ["INSERT INTO [users] (", "[id]", ",", "[firstname]", ")", " VALUES (41, 'x')"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = "id"
					);
					expect(ArrayToList(out.sql, " ")).notToInclude("SCOPE_IDENTITY");
					expect(out.sql[ArrayLen(out.sql)]).toInclude("SET IDENTITY_INSERT [users] OFF");
				});

				it("ignores statements without a primary-key hint (the bulk paths)", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
					var out = probe.$querySetup(
						sql = ["INSERT INTO [users] (", "[id]", ",", "[firstname]", ")", " VALUES (41, 'x'), (42, 'y')"],
						limit = 0,
						offset = 0,
						parameterize = true,
						$primaryKey = ""
					);
					expect(ArrayLen(out.sql)).toBe(6);
					expect(ArrayToList(out.sql, " ")).notToInclude("IDENTITY_INSERT");
				});
			});
		});
	}

}
