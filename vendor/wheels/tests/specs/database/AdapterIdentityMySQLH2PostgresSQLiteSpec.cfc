component extends="wheels.WheelsTest" {

	function run() {

		describe("S4 MySQL identity unit specs", () => {

			it("uses generated_key as the published identity key", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				expect(adapter.$generatedKey()).toBe("generated_key");
			});

			it("publishes LAST_INSERT_ID under generated_key", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.MySQLProbe");
				ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 11}]));
				var rv = probe.$identitySelect(
					queryAttributes = {},
					result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
					primaryKey = "id",
					returningIdentity = ""
				);
				expect(rv).toBeStruct();
				expect(rv.generated_key).toBe(11);
				expect(probe.capturedSql[1]).toInclude("LAST_INSERT_ID()");
			});

			it("returns void when generated_key is already on the result", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.MySQLProbe");
				expect(
					IsNull(
						probe.$identitySelect(
							queryAttributes = {},
							result = {sql: "INSERT INTO users (firstname) VALUES ('x')", generated_key: 3},
							primaryKey = "id",
							returningIdentity = ""
						)
					)
				).toBeTrue();
				expect(ArrayLen(probe.capturedSql)).toBe(0);
			});

		});

		describe("S4 H2 identity unit specs", () => {

			it("uses generated_key as the published identity key", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.H2.H2Model");
				expect(adapter.$generatedKey()).toBe("generated_key");
			});

			it("publishes LAST_INSERT_ID under generated_key", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.H2Probe");
				ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 12}]));
				var rv = probe.$identitySelect(
					queryAttributes = {},
					result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
					primaryKey = "id",
					returningIdentity = ""
				);
				expect(rv).toBeStruct();
				expect(rv.generated_key).toBe(12);
				expect(probe.capturedSql[1]).toInclude("LAST_INSERT_ID()");
			});

		});

		describe("S4 PostgreSQL identity unit specs", () => {

			it("uses lastId as the published identity key", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
				expect(adapter.$generatedKey()).toBe("lastId");
			});

			it("reads currval from pg_get_serial_sequence", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.PostgreSQLProbe");
				ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 13}]));
				var rv = probe.$identitySelect(
					queryAttributes = {},
					result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
					primaryKey = "id",
					returningIdentity = ""
				);
				expect(rv).toBeStruct();
				expect(rv.lastId).toBe(13);
				expect(probe.capturedSql[1]).toInclude("currval");
				expect(probe.capturedSql[1]).toInclude("pg_get_serial_sequence");
				expect(probe.capturedSql[1]).toInclude("users");
			});

			it("returns void when lastId is already on the result", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.PostgreSQLProbe");
				expect(
					IsNull(
						probe.$identitySelect(
							queryAttributes = {},
							result = {sql: "INSERT INTO users (firstname) VALUES ('x')", lastId: 4},
							primaryKey = "id",
							returningIdentity = ""
						)
					)
				).toBeTrue();
				expect(ArrayLen(probe.capturedSql)).toBe(0);
			});

		});

		describe("S4 SQLite identity unit specs", () => {

			it("uses generated_key as the published identity key", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
				expect(adapter.$generatedKey()).toBe("generated_key");
			});

			it("reads last_insert_rowid", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.SQLiteProbe");
				ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 14}]));
				var rv = probe.$identitySelect(
					queryAttributes = {},
					result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
					primaryKey = "id",
					returningIdentity = ""
				);
				expect(rv).toBeStruct();
				expect(rv.generated_key).toBe(14);
				expect(probe.capturedSql[1]).toInclude("last_insert_rowid()");
			});

			it("returns void when the primary key is in the insert column list", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.SQLiteProbe");
				expect(
					IsNull(
						probe.$identitySelect(
							queryAttributes = {},
							result = {sql: "INSERT INTO users (id, firstname) VALUES (1, 'x')"},
							primaryKey = "id",
							returningIdentity = ""
						)
					)
				).toBeTrue();
				expect(ArrayLen(probe.capturedSql)).toBe(0);
			});

		});

	}

}
