/**
 * A long integer IN list parses without overflowing the stack. The WHERE
 * parser's numeric-list pattern used to recurse once per list element, so a
 * few thousand keys threw java.lang.StackOverflowError. Issue #3907.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Large integer IN lists", () => {

			beforeEach(() => {
				keys = [];
				for (var i = 1; i <= 5000; i++) {
					ArrayAppend(keys, i);
				}
			})

			// The parser runs before any query, so this holds on every database,
			// including SQL Server and Oracle, which cap how many values a query binds.
			it("parses a 5000-key IN list into one bound list parameter", () => {
				var where = "id IN (#ArrayToList(keys)#)";
				var parts = g.model("author").$whereClause(where = where);
				parts = g.model("author").$addWhereClauseParameters(sql = parts, where = where);
				var lists = [];
				for (var part in parts) {
					if (IsStruct(part) && StructKeyExists(part, "list") && part.list) {
						ArrayAppend(lists, part);
					}
				}
				expect(ArrayLen(lists)).toBe(1);
				expect(ListLen(lists[1].value)).toBe(5000);
			})

			it("parses a 5000-key whereIn", () => {
				// Running the query binds one parameter per key: SQL Server allows 2100 per
				// statement and Oracle 1000 per IN list (ORA-01795). Chunking is #3906.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server caps a query at 2100 bound parameters (##3906)");
				} else if (g.get("adapterName") == "OracleModel") {
					skip("Oracle caps an IN list at 1000 values, ORA-01795 (##3906)");
				}
				expect(g.model("author").whereIn("id", keys).count()).toBe(g.model("author").count());
			})

			it("parses a 5000-key whereNotIn", () => {
				// Running the query binds one parameter per key: SQL Server allows 2100 per
				// statement and Oracle 1000 per IN list (ORA-01795). Chunking is #3906.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server caps a query at 2100 bound parameters (##3906)");
				} else if (g.get("adapterName") == "OracleModel") {
					skip("Oracle caps an IN list at 1000 values, ORA-01795 (##3906)");
				}
				expect(g.model("author").whereNotIn("id", keys).count()).toBe(0);
			})

			it("parses a 5000-key IN list in a hand-written where string", () => {
				// Running the query binds one parameter per key: SQL Server allows 2100 per
				// statement and Oracle 1000 per IN list (ORA-01795). Chunking is #3906.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server caps a query at 2100 bound parameters (##3906)");
				} else if (g.get("adapterName") == "OracleModel") {
					skip("Oracle caps an IN list at 1000 values, ORA-01795 (##3906)");
				}
				var rows = g.model("author").findAll(where = "id IN (#ArrayToList(keys)#)", returnAs = "query");
				expect(rows.recordCount).toBe(g.model("author").count());
			})

			it("still binds a short signed list next to other conditions", () => {
				var rows = g.model("author").findAll(where = "id IN (-1,1,2) AND lastName <> ''", returnAs = "query");
				var expected = g.model("author").findAll(where = "id IN (1,2) AND lastName <> ''", returnAs = "query");
				expect(rows.recordCount).toBe(expected.recordCount);
			})

		});

	}

}
