component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// Where strings that hold more than one quoted literal, or a literal
		// followed by something other than AND/OR or the end of the clause.

		describe("Where strings with a LIKE ... ESCAPE clause after a quoted literal", () => {

			it("matches a literal underscore with ESCAPE '!'", () => {
				var counts = $countsFor({
					bang: "lastName LIKE '%Qzw!_%' ESCAPE '!'"
				});
				expect(counts.bang).toBe(2);
			})

			it("matches a literal underscore with ESCAPE '\'", () => {
				var counts = $countsFor({
					backslash: "lastName LIKE '%Qzw\_%' ESCAPE '\'"
				});
				expect(counts.backslash).toBe(2);
			})

			it("keeps a condition that follows the ESCAPE clause", () => {
				var counts = $countsFor({
					followed: "lastName LIKE '%Qzw!_%' ESCAPE '!' AND firstName = 'Literal'",
					followedNoMatch: "lastName LIKE '%Qzw!_%' ESCAPE '!' AND firstName = 'zznope'"
				});
				expect(counts.followed).toBe(2);
				expect(counts.followedNoMatch).toBe(0);
			})

			it("matches a pattern holding a doubled quote", () => {
				var counts = $countsFor({
					doubledQuote: "lastName LIKE '%O''Qzw!_%' ESCAPE '!'"
				});
				expect(counts.doubledQuote).toBe(1);
			})

		})

		describe("Where strings that join quoted literals with lowercase or mixed-case AND/OR", () => {

			it("handles a lowercase or between two quoted literals", () => {
				var counts = $countsFor({
					equals: "lastName = 'Qzw_Ox' or lastName = 'zznope'",
					like: "lastName LIKE '%Qzw_O%' or lastName LIKE '%zznope%'"
				});
				expect(counts.equals).toBe(1);
				expect(counts.like).toBe(2);
			})

			it("handles a lowercase and between two quoted literals", () => {
				var counts = $countsFor({
					match: "firstName = 'Literal' and lastName = 'Qzw_Ox'",
					noMatch: "firstName = 'Literal' and lastName = 'zznope'"
				});
				expect(counts.match).toBe(1);
				expect(counts.noMatch).toBe(0);
			})

			it("handles mixed-case operators and keywords", () => {
				var counts = $countsFor({
					mixed: "lastName Like '%Qzw%' And firstName = 'Literal'",
					mixedOr: "lastName = 'zznope' Or lastName = 'QzwXOx'"
				});
				expect(counts.mixed).toBe(3);
				expect(counts.mixedOr).toBe(1);
			})

			it("still handles upper-case AND/OR", () => {
				var counts = $countsFor({
					upper: "lastName = 'Qzw_Ox' OR lastName = 'QzwXOx'",
					upperAnd: "firstName = 'Literal' AND lastName = 'QzwXOx'"
				});
				expect(counts.upper).toBe(2);
				expect(counts.upperAnd).toBe(1);
			})

		})

		describe("Where strings with BETWEEN ... AND in any case", () => {

			it("returns the rows between two bounds whatever the keyword case", () => {
				var ids = $postIds();
				var lower = g.model("post").findAll(where = "id between #ids[1]# and #ids[3]#", returnAs = "query", reload = true);
				var mixed = g.model("post").findAll(where = "id Between #ids[1]# And #ids[3]#", returnAs = "query", reload = true);
				var upper = g.model("post").findAll(where = "id BETWEEN #ids[1]# AND #ids[3]#", returnAs = "query", reload = true);
				expect(lower.recordCount).toBe(3);
				expect(mixed.recordCount).toBe(3);
				expect(upper.recordCount).toBe(3);
			})

			it("keeps a BETWEEN next to a lowercase and/or condition", () => {
				var ids = $postIds();
				var titles = $postTitles();
				var withOr = g.model("post").findAll(where = "id between #ids[2]# and #ids[3]# or title = '#titles[5]#'", returnAs = "query", reload = true);
				var withAnd = g.model("post").findAll(where = "id between #ids[1]# and #ids[3]# and title <> '#titles[2]#'", returnAs = "query", reload = true);
				expect(withOr.recordCount).toBe(3);
				expect(withAnd.recordCount).toBe(2);
			})

			it("keeps a BETWEEN next to a quoted literal", () => {
				var ids = $postIds();
				var titles = $postTitles();
				var before = g.model("post").findAll(where = "title = '#titles[1]#' and id between #ids[1]# and #ids[3]#", returnAs = "query", reload = true);
				var after = g.model("post").findAll(where = "id Between #ids[1]# And #ids[3]# And title = '#titles[4]#'", returnAs = "query", reload = true);
				expect(before.recordCount).toBe(1);
				expect(after.recordCount).toBe(0);
			})

		})

	}

	/**
	 * Creates the authors these specs search, counts the rows each where string
	 * finds, and rolls the authors back.
	 */
	public struct function $countsFor(required struct wheres) {
		var counts = {};
		transaction {
			g.model("author").create(firstName = "Literal", lastName = "Qzw_Ox");
			g.model("author").create(firstName = "Literal", lastName = "QzwXOx");
			g.model("author").create(firstName = "Literal", lastName = "O'Qzw_y");
			for (var key in arguments.wheres) {
				counts[key] = g.model("author").findAll(where = arguments.wheres[key], returnAs = "query", reload = true).recordCount;
			}
			transaction action = "rollback";
		}
		return counts;
	}

	public array function $postIds() {
		// hoisted: ValueList() over a call expression doesn't compile on Adobe
		var posts = g.model("post").findAll(select = "id", order = "id", returnAs = "query", reload = true);
		return ListToArray(ValueList(posts.id));
	}

	public array function $postTitles() {
		var posts = g.model("post").findAll(select = "id,title", order = "id", returnAs = "query", reload = true);
		var titles = [];
		for (var row in posts) {
			ArrayAppend(titles, row.title);
		}
		return titles;
	}

}
