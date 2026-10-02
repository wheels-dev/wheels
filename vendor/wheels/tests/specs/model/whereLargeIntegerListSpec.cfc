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
			// including SQL Server, which caps a query at 2100 bound parameters.
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
				// Running the query needs one bound parameter per key; SQL Server allows 2100.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server caps a query at 2100 bound parameters");
				}
				expect(g.model("author").whereIn("id", keys).count()).toBe(g.model("author").count());
			})

			it("parses a 5000-key whereNotIn", () => {
				// Running the query needs one bound parameter per key; SQL Server allows 2100.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server caps a query at 2100 bound parameters");
				}
				expect(g.model("author").whereNotIn("id", keys).count()).toBe(0);
			})

			it("parses a 5000-key IN list in a hand-written where string", () => {
				// Running the query needs one bound parameter per key; SQL Server allows 2100.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server caps a query at 2100 bound parameters");
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
