/**
 * IN lists past a database's limits (#3906). Oracle 19c and earlier accept at most
 * 1000 values in one IN list (ORA-01795), so Wheels splits a longer list into
 * parenthesised groups: OR-joined for IN, AND-joined for NOT IN, every value still
 * bound. Oracle 23ai has no such limit, but the split runs there too, which is how
 * these specs exercise it. SQL Server accepts at most 2100 parameters per request,
 * a few of which the driver uses itself, so a query that would bind more than the
 * adapter's limit (2097) is refused with Wheels.TooManyParameters before it runs.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("IN lists past a database's limits", () => {

			beforeEach(() => {
				realIds = [];
				var authors = g.model("author").findAll(select = "id", order = "id", returnAs = "query");
				for (var r = 1; r <= authors.recordCount; r++) {
					ArrayAppend(realIds, authors.id[r]);
				}
			});

			it("groups a list without losing or reordering its elements", () => {
				var groups = g.model("author").$inListGroups(value = "1,2,3,4,5", size = 2);
				expect(ArrayToList(groups, "|")).toBe("1,2|3,4|5");
				var quoted = g.model("author").$inListGroups(value = "'a','b','c'", size = 2);
				expect(ArrayToList(quoted, "|")).toBe("'a','b'|'c'");
				expect(ArrayLen(g.model("author").$inListGroups(value = "1,2", size = 1000))).toBe(1);
			});

			it("wraps a split list in parentheses and joins IN with OR and NOT IN with AND", () => {
				if (g.get("adapterName") != "OracleModel") {
					skip("Lists are split only where the adapter sets a size limit (Oracle).");
				}
				for (var op in ["IN", "NOT IN"]) {
					var where = "id #op# (#ArrayToList(paddedKeys(1500))#)";
					var parts = g.model("author").$whereClause(where = where);
					parts = g.model("author").$addWhereClauseParameters(sql = parts, where = where);
					var text = [];
					var lists = 0;
					for (var part in parts) {
						if (IsSimpleValue(part)) {
							ArrayAppend(text, Trim(part));
						} else if (StructKeyExists(part, "list") && part.list) {
							lists++;
						}
					}
					var joined = ArrayToList(text, " ");
					expect(lists).toBe(2, op);
					expect(joined).toInclude("(", op);
					expect(joined).toInclude(op == "IN" ? " OR " : " AND ", op);
					expect(Right(joined, 1)).toBe(")", op);
				}
			});

			it("returns the right rows for a split IN list next to another condition", () => {
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server does not split IN lists.");
				}
				var keys = paddedKeys(1500);
				var first = g.model("author").findByKey(realIds[1]);
				var rows = g.model("author").whereIn("id", keys).where("firstName", first.firstName).get();
				var expected = g.model("author").findAll(where = "firstName = '#Replace(first.firstName, "'", "''", "all")#'", returnAs = "query");
				expect(rows.recordCount).toBe(expected.recordCount);
				expect(g.model("author").whereIn("id", keys).count()).toBe(ArrayLen(realIds));
			});

			it("keeps NOT IN's NULL behaviour when the list is split", () => {
				if (g.get("adapterName") == "MicrosoftSQLServerModel") {
					skip("SQL Server does not split IN lists.");
				}
				var state = {split = -1, single = -1};
				transaction {
					// A row whose authorid is NULL: NOT IN excludes it, split or not.
					g.model("post").create(title = "in-list null author", body = "x", authorid = "");
					var filler = paddedKeys(1500, []);
					state.split = g.model("post").whereNotIn("authorid", filler).count();
					state.single = g.model("post").whereNotIn("authorid", [-1]).count();
					transaction action = "rollback";
				}
				expect(state.split).toBe(state.single);
			});

			it("still short-circuits an empty list", () => {
				expect(g.model("author").whereIn("id", []).count()).toBe(0);
				expect(g.model("author").whereNotIn("id", []).count()).toBe(g.model("author").count());
			});

			it("splits a quoted-string list at a group boundary without breaking its values", () => {
				// Values with commas and apostrophes, and real names either side of the
				// 1000-value boundary, so a split inside a value would lose a match.
				var names = [];
				var authors = g.model("author").findAll(select = "firstName", returnAs = "query");
				for (var i = 1; i <= 998; i++) {
					ArrayAppend(names, "pad, it's #i#");
				}
				for (var r = 1; r <= authors.recordCount; r++) {
					ArrayAppend(names, authors.firstName[r]);
				}
				for (var i = 999; ArrayLen(names) < 1500; i++) {
					ArrayAppend(names, "pad, it's #i#");
				}
				expect(g.model("author").whereIn("firstName", names).count()).toBe(authors.recordCount);
				expect(g.model("author").whereNotIn("firstName", names).count()).toBe(0);
			});

			it("returns the right rows for a split list with parameterize=false", () => {
				var keys = paddedKeys(1500);
				var rows = g.model("author").findAll(where = "id IN (#ArrayToList(keys)#)", parameterize = false, returnAs = "query");
				expect(rows.recordCount).toBe(ArrayLen(realIds));
				var names = [];
				var authors = g.model("author").findAll(select = "firstName", returnAs = "query");
				for (var r = 1; r <= authors.recordCount; r++) {
					ArrayAppend(names, "'" & Replace(authors.firstName[r], "'", "''", "all") & "'");
				}
				for (var i = 1; ArrayLen(names) < 1500; i++) {
					ArrayAppend(names, "'pad, it''s #i#'");
				}
				var named = g.model("author").findAll(where = "firstName IN (#ArrayToList(names)#)", parameterize = false, returnAs = "query");
				expect(named.recordCount).toBe(authors.recordCount);
			});

			it("runs the adapter's limit and refuses one more on SQL Server before the query runs", () => {
				if (g.get("adapterName") != "MicrosoftSQLServerModel") {
					skip("SQL Server's bound-parameter limit.");
				}
				var adapter = g.model("author").$classData().adapter;
				var limit = adapter.$maxBoundParameters();
				expect(g.model("author").whereIn("id", paddedKeys(limit)).count()).toBe(ArrayLen(realIds));
				var state = {type = "", message = ""};
				try {
					g.model("author").whereIn("id", paddedKeys(limit + 1)).count();
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("Wheels.TooManyParameters");
				expect(state.message).toInclude("#limit + 1#");
				expect(state.message).toInclude("#limit#");
			});

			it("counts a scalar parameter alongside a list against SQL Server's limit", () => {
				if (g.get("adapterName") != "MicrosoftSQLServerModel") {
					skip("SQL Server's bound-parameter limit.");
				}
				var adapter = g.model("author").$classData().adapter;
				var limit = adapter.$maxBoundParameters();
				var first = g.model("author").findByKey(realIds[1]);
				var expected = g.model("author").findAll(where = "firstName = '#Replace(first.firstName, "'", "''", "all")#'", returnAs = "query");
				expect(g.model("author").whereIn("id", paddedKeys(limit - 1)).where("firstName", first.firstName).count()).toBe(expected.recordCount);
				var state = {type = "", message = ""};
				try {
					g.model("author").whereIn("id", paddedKeys(limit)).where("firstName", first.firstName).count();
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("Wheels.TooManyParameters");
				expect(state.message).toInclude("#limit + 1#");
			});

		});

	}

	// `size` keys: the given ids (every real author id by default), padded with
	// negative numbers that can never match an id.
	private array function paddedKeys(required numeric size, array ids = realIds) {
		var keys = [];
		for (var id in arguments.ids) {
			ArrayAppend(keys, id);
		}
		for (var i = 1; ArrayLen(keys) < arguments.size; i++) {
			ArrayAppend(keys, -i);
		}
		return keys;
	}

}
