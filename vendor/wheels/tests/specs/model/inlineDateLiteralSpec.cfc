/**
 * Date and timestamp values written into the SQL text (parameterize=false). Oracle
 * reads a quoted string compared with a date column through the session's NLS date
 * format, so the Oracle adapter writes an ISO value as an ANSI DATE / TIMESTAMP
 * literal instead (#4084).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Oracle $inlineValue for dates", () => {

			it("writes an ISO timestamp as a TIMESTAMP literal", () => {
				var adapter = new wheels.databaseAdapters.Oracle.OracleModel();
				expect(adapter.$inlineValue(str = "2000-01-01 00:00:00", sqlType = "cf_sql_timestamp")).toBe("TIMESTAMP '2000-01-01 00:00:00'");
				expect(adapter.$inlineValue(str = "2000-01-01 12:30:45.5", sqlType = "cf_sql_timestamp")).toBe("TIMESTAMP '2000-01-01 12:30:45.5'");
			})

			it("writes an ISO date as a DATE literal", () => {
				var adapter = new wheels.databaseAdapters.Oracle.OracleModel();
				expect(adapter.$inlineValue(str = "2000-01-01", sqlType = "cf_sql_date")).toBe("DATE '2000-01-01'");
				expect(adapter.$inlineValue(str = "2000-01-01", sqlType = "cf_sql_timestamp")).toBe("DATE '2000-01-01'");
			})

			it("leaves other values as quoted strings", () => {
				var adapter = new wheels.databaseAdapters.Oracle.OracleModel();
				expect(adapter.$inlineValue(str = "01/02/2000", sqlType = "cf_sql_timestamp")).toBe("'01/02/2000'");
				expect(adapter.$inlineValue(str = "2000-01-01'; x", sqlType = "cf_sql_timestamp")).toBe("'2000-01-01''; x'");
				expect(adapter.$inlineValue(str = "2000-01-01 00:00:00", sqlType = "cf_sql_varchar")).toBe("'2000-01-01 00:00:00'");
			})

		})

		describe("Inline date comparisons", () => {

			it("compares a timestamp column with a {ts} value under parameterize=false", () => {
				var total = g.model("post").count();
				expect(total).toBeGT(0);
				expect(g.model("post").count(where = "createdAt > {ts '2000-01-01 00:00:00'}", parameterize = false)).toBe(total);
				expect(g.model("post").count(where = "createdAt > {ts '2999-01-01 00:00:00'}", parameterize = false)).toBe(0);
			})

			it("compares a timestamp column with an ISO string under parameterize=false", () => {
				var total = g.model("post").count();
				expect(g.model("post").count(where = "createdAt > '2000-01-01 00:00:00'", parameterize = false)).toBe(total);
				expect(g.model("post").count(where = "createdAt < '2000-01-01'", parameterize = false)).toBe(0);
			})

			it("returns the same rows bound and inline", () => {
				var bound = g.model("post").count(where = "createdAt > {ts '2000-01-01 00:00:00'}");
				var inline = g.model("post").count(where = "createdAt > {ts '2000-01-01 00:00:00'}", parameterize = false);
				expect(inline).toBe(bound);
			})

		})

	}

}
