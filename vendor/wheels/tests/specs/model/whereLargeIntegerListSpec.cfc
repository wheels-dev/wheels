/**
 * A long integer IN list parses without overflowing the stack. The WHERE
 * parser's numeric-list pattern used to recurse once per list element, so a
 * few thousand keys threw java.lang.StackOverflowError. Issue #3907.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Large integer IN lists", () => {

			// 5000 keys: every real author id, padded with negative numbers that can never
			// match an id. The ids come from the table rather than 1..5000, because
			// CockroachDB's SERIAL ids are large and non-sequential (unique_rowid()).
			beforeEach(() => {
				realIds = [];
				var authors = g.model("author").findAll(select = "id", order = "id", returnAs = "query");
				for (var r = 1; r <= authors.recordCount; r++) {
					ArrayAppend(realIds, authors.id[r]);
				}
				keys = [];
				for (var id in realIds) {
					ArrayAppend(keys, id);
				}
				for (var i = 1; ArrayLen(keys) < 5000; i++) {
					ArrayAppend(keys, -i);
				}
			})

			// The parser runs before any query, so this holds on every database. On Oracle
			// the list comes back split into groups of at most 1000 (#3906).
			it("parses a 5000-key IN list into bound list parameters", () => {
				var where = "id IN (#ArrayToList(keys)#)";
				var parts = g.model("author").$whereClause(where = where);
				parts = g.model("author").$addWhereClauseParameters(sql = parts, where = where);
				var lists = [];
				for (var part in parts) {
					if (IsStruct(part) && StructKeyExists(part, "list") && part.list) {
						ArrayAppend(lists, part);
					}
				}
				var maxSize = g.model("author").$classData().adapter.$maxInListSize();
				expect(ArrayLen(lists)).toBe(maxSize > 0 ? Ceiling(5000 / maxSize) : 1);
				var total = 0;
				for (var list in lists) {
					expect(ListLen(list.value)).toBeLTE(maxSize > 0 ? maxSize : 5000);
					total += ListLen(list.value);
				}
				expect(total).toBe(5000);
			})

			it("parses a 5000-key whereIn", () => {
				// SQL Server binds at most about 2100 parameters per statement, so the query
				// is refused with a clear error before it runs (#3906). Oracle splits the list
				// into groups of 1000 and runs it.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					expectTooManyParameters(() => {
						g.model("author").whereIn("id", keys).count();
					});
					return;
				}
				expect(g.model("author").whereIn("id", keys).count()).toBe(g.model("author").count());
			})

			it("parses a 5000-key whereNotIn", () => {
				// SQL Server binds at most about 2100 parameters per statement, so the query
				// is refused with a clear error before it runs (#3906). Oracle splits the list
				// into groups of 1000 and runs it.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					expectTooManyParameters(() => {
						g.model("author").whereNotIn("id", keys).count();
					});
					return;
				}
				expect(g.model("author").whereNotIn("id", keys).count()).toBe(0);
			})

			it("parses a 5000-key IN list in a hand-written where string", () => {
				// SQL Server binds at most about 2100 parameters per statement, so the query
				// is refused with a clear error before it runs (#3906). Oracle splits the list
				// into groups of 1000 and runs it.
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					expectTooManyParameters(() => {
						g.model("author").findAll(where = "id IN (#ArrayToList(keys)#)", returnAs = "query");
					});
					return;
				}
				var rows = g.model("author").findAll(where = "id IN (#ArrayToList(keys)#)", returnAs = "query");
				expect(rows.recordCount).toBe(g.model("author").count());
			})

			it("still binds a short signed list next to other conditions", () => {
				var pair = "#realIds[1]#,#realIds[2]#";
				var rows = g.model("author").findAll(where = "id IN (-1,#pair#) AND lastName IS NOT NULL", returnAs = "query");
				var expected = g.model("author").findAll(where = "id IN (#pair#) AND lastName IS NOT NULL", returnAs = "query");
				expect(expected.recordCount).toBe(2);
				expect(rows.recordCount).toBe(expected.recordCount);
			})

		});

	}

	// Runs the call and expects Wheels.TooManyParameters, with the limit and the count named.
	private void function expectTooManyParameters(required any callback) {
		var state = {type = "", message = ""};
		try {
			arguments.callback();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		expect(state.type).toBe("Wheels.TooManyParameters");
		var adapter = g.model("author").$classData().adapter;
		expect(state.message).toInclude("#adapter.$maxBoundParameters()#");
		expect(state.message).toInclude("5000");
	}

}
