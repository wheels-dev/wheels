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

			describe("$randomOrder", () => {

				it("returns DBMS_RANDOM.VALUE", () => {
					// RANDOM() is not an Oracle function (ORA-00904); DBMS_RANDOM.VALUE
					// is the Oracle-native ORDER BY expression for findAll(order="random").
					expect(adapter.$randomOrder()).toBe("DBMS_RANDOM.VALUE");
				});
			});

			describe("CURRVAL fallback", () => {

				it("resolves the identity sequence and reads CURRVAL instead of MAX(ROWID)", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", [{sequence_name: "ISEQ$$_12345"}]));
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 42}]));
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("lastId");
					expect(rv.lastId).toBe(42);
					expect(probe.capturedSql[1]).toInclude("user_tab_identity_cols");
					expect(probe.capturedSql[2]).toInclude("ISEQ$$_12345.CURRVAL");
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("MAX(ROWID)");
				});

				it("falls back to MAX(ROWID) when no identity sequence is discoverable", () => {
					// Pre-12c schemas have no user_tab_identity_cols rows — the legacy
					// last-resort lookup must survive for them.
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", []));
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 9}]));
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv).toHaveKey("lastId");
					expect(rv.lastId).toBe(9);
					expect(probe.capturedSql[2]).toInclude("MAX(ROWID)");
				});

				it("rejects unsafe sequence names and falls back to MAX(ROWID)", () => {
					// $query has no parameter binding, so the discovered sequence name is
					// whitelisted before interpolation — anything unexpected is discarded.
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", [{sequence_name: "BAD;NAME"}]));
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("BAD;NAME");
					expect(probe.capturedSql[2]).toInclude("MAX(ROWID)");
				});
			});
		});
	}

}
