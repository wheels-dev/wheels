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

			describe("non-simple driver keys (##3708)", () => {

				// BoxLang surfaces Oracle's generated key as an oracle.sql.ROWID OBJECT, and
				// Len()/ListFirst() on it threw "Cannot determine length of object of type
				// oracle.sql.ROWID", aborting fixture population for the whole leg.

				it("reads a numeric key from an object's stringValue()", () => {
					var key = new wheels.tests._assets.adapters.GeneratedKeyStringValueStub("42");
					var rv = adapter.$identitySelect(
						queryAttributes = {},
						result = {sql = "INSERT INTO users (firstname) VALUES ('test')", generatedKey = key},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv.lastId).toBe("42");
				});

				it("reads a numeric key from an object's toString() (java.sql.RowId contract, ACF rowid surface)", () => {
					var key = new wheels.tests._assets.adapters.GeneratedKeyToStringStub("42");
					var rv = adapter.$identitySelect(
						queryAttributes = {},
						result = {sql = "INSERT INTO users (firstname) VALUES ('test')", rowid = key},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv.lastId).toBe("42");
				});

				it("resolves a ROWID object through the exact-row CHARTOROWID lookup", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 7}]));
					var key = new wheels.tests._assets.adapters.GeneratedKeyStringValueStub("AAAR3sAAEAAAACXAAA");
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql = "INSERT INTO users (firstname) VALUES ('x')", generatedKey = key},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv.lastId).toBe(7);
					expect(probe.capturedSql[1]).toInclude("CHARTOROWID('AAAR3sAAEAAAACXAAA')");
				});

				it("treats an unreadable key object as no key and falls back to CURRVAL", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", [{sequence_name: "ISEQ$$_12345"}]));
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 9}]));
					var key = new wheels.tests._assets.adapters.GeneratedKeyOpaqueStub();
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql = "INSERT INTO users (firstname) VALUES ('x')", generatedKey = key},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv).toBeStruct();
					expect(rv.lastId).toBe(9);
					expect(ArrayToList(probe.capturedSql, " ")).toInclude("ISEQ$$_12345.CURRVAL");
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("CHARTOROWID");
				});

				it("reads a real oracle.sql.ROWID when the Oracle driver is on the classpath", () => {
					var rowidText = "AAAR3sAAEAAAACXAAA";
					var state = {rowid = ""};
					try {
						state.rowid = CreateObject("java", "oracle.sql.ROWID").init(CharsetDecode(rowidText, "us-ascii"));
					} catch (any e) {
						state.rowid = "";
					}
					if (IsSimpleValue(state.rowid)) {
						skip("oracle.sql.ROWID is not on this engine's classpath (runs on the Oracle legs).");
						return;
					}
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 11}]));
					var rv = probe.$identitySelect(
						queryAttributes = {},
						result = {sql = "INSERT INTO users (firstname) VALUES ('x')", generatedKey = state.rowid},
						primaryKey = "id",
						returningIdentity = ""
					);
					expect(rv.lastId).toBe(11);
					expect(probe.capturedSql[1]).toInclude("CHARTOROWID('#rowidText#')");
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

				it("throws Wheels.IdentityNotFound when no identity sequence is discoverable", () => {
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", []));
					var state = {type = ""};
					try {
						probe.$identitySelect(
							queryAttributes = {},
							result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
							primaryKey = "id",
							returningIdentity = ""
						);
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.IdentityNotFound");
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("MAX(ROWID)");
				});

				it("rejects unsafe sequence names and throws Wheels.IdentityNotFound", () => {
					// $query has no parameter binding, so the discovered sequence name is
					// whitelisted before interpolation — anything unexpected is discarded.
					var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
					ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", [{sequence_name: "BAD;NAME"}]));
					var state = {type = ""};
					try {
						probe.$identitySelect(
							queryAttributes = {},
							result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
							primaryKey = "id",
							returningIdentity = ""
						);
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.IdentityNotFound");
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("BAD;NAME");
					expect(ArrayToList(probe.capturedSql, " ")).notToInclude("MAX(ROWID)");
				});
			});
		});
	}

}
