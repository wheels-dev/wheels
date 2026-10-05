/**
 * BIGINT columns are typed cf_sql_bigint on every adapter (#4086). SQLite reported a
 * declared BIGINT as cf_sql_integer, and Oracle had no column precision to tell
 * NUMBER(19) from NUMBER(10), so 64-bit values were bound as 32-bit integers.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		sqlite = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
		oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleModel");
		autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
	}

	function run() {

		g = application.wo

		describe("BIGINT column types (##4086)", () => {

			it("maps a declared SQLite BIGINT or INT8 to cf_sql_bigint", () => {
				expect(sqlite.$getType(type = "bigint")).toBe("cf_sql_bigint")
				expect(sqlite.$getType(type = "BIGINT")).toBe("cf_sql_bigint")
				expect(sqlite.$getType(type = "int8")).toBe("cf_sql_bigint")
			})

			it("types SQLite INTEGER as cf_sql_bigint, the 64-bit rowid width (##4142)", () => {
				expect(sqlite.$getType(type = "integer")).toBe("cf_sql_bigint")
				expect(sqlite.$getType(type = "int")).toBe("cf_sql_bigint")
				expect(sqlite.$getType(type = "smallint")).toBe("cf_sql_integer")
			})

			it("maps the portable bigint name on Oracle, as a calculated property's dataType", () => {
				expect(oracle.$getType(type = "bigint")).toBe("cf_sql_bigint")
				expect(oracle.$getType(type = "int8")).toBe("cf_sql_bigint")
			})

			it("maps Oracle NUMBER(11..38, 0), including INTEGER (NUMBER(38)), to cf_sql_bigint", () => {
				expect(oracle.$getType(type = "number", scale = 0, details = "", precision = 11)).toBe("cf_sql_bigint")
				expect(oracle.$getType(type = "number", scale = 0, details = "", precision = 19)).toBe("cf_sql_bigint")
				expect(oracle.$getType(type = "number", scale = 0, details = "", precision = 20)).toBe("cf_sql_bigint")
				expect(oracle.$getType(type = "number", scale = 0, details = "", precision = 38)).toBe("cf_sql_bigint")
			})

			it("keeps other Oracle NUMBER shapes as before", () => {
				expect(oracle.$getType(type = "number", scale = 0, details = "", precision = 10)).toBe("cf_sql_integer")
				expect(oracle.$getType(type = "number", scale = 0, details = "", precision = 1)).toBe("cf_sql_integer")
				expect(oracle.$getType(type = "number", scale = 0, details = "")).toBe("cf_sql_integer")
				expect(oracle.$getType(type = "number", scale = 2, details = "", precision = 19)).toBe("cf_sql_numeric")
			})

			it("types a BIGINT column as cf_sql_bigint on this database", () => {
				var props = g.model("bigKeyPost").$classData().properties
				expect(props.id.type).toBe("cf_sql_bigint")
				expect(props.viewcount.type).toBe("cf_sql_bigint")
			})

			it("reports no type change for an in-sync BIGINT column in migrate diff", () => {
				var result = autoMigrator.diff("BigKeyPost")
				var changed = []
				for (var c in result.changeColumns) {
					ArrayAppend(changed, c.name)
				}
				expect(ArrayFindNoCase(changed, "viewcount")).toBe(0, "changeColumns=" & ArrayToList(changed))
			})

		})

	}

}
