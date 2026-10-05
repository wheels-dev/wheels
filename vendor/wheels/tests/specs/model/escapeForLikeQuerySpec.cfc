/**
 * escapeForLike() makes a search term's LIKE wildcards literal. These specs run a real
 * `LIKE '...' ESCAPE '\'` query through findAll (the quoted literal is bound by `parameterize`)
 * and assert the escaped term matches only the row that contains the characters literally — never
 * the row a raw wildcard would also catch. They run across the compat matrix, so they pin the
 * `ESCAPE '\'` behaviour on every supported database (MySQL, PostgreSQL, SQL Server, SQLite, Oracle,
 * H2, CockroachDB). The pure string transform is pinned separately by escapeForLikeSpec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("escapeForLike() in a LIKE ... ESCAPE '\' query", () => {

			it("treats % as a literal, not a wildcard", () => {
				var counts = $countsFor(
					literalRow = "50% off everything",
					wildcardRow = "500 off everything",
					term = "50%"
				);
				// Escaped: matches only the row that literally contains "50%".
				expect(counts.escaped).toBe(1);
				// Unescaped the % is a wildcard, so both rows match — that is the bug escapeForLike fixes.
				expect(counts.raw).toBe(2);
			});

			it("treats _ as a literal, not a single-character wildcard", () => {
				var counts = $countsFor(
					literalRow = "code a_b active",
					wildcardRow = "code axb active",
					term = "a_b"
				);
				expect(counts.escaped).toBe(1);
				expect(counts.raw).toBe(2);
			});

			it("treats [ as a literal (a character-class wildcard on SQL Server)", () => {
				// The escaped '\[' matches a literal '[' on every engine; on SQL Server it also stops
				// '[x]' being read as a one-character class. Asserted as a universal positive match.
				var counts = $countsFor(
					literalRow = "size [x] large",
					wildcardRow = "size y large",
					term = "[x]"
				);
				expect(counts.escaped).toBe(1);
			});

			it("treats a backslash as a literal character", () => {
				var counts = $countsFor(
					literalRow = "path c:\temp\logs",
					wildcardRow = "path c:/temp/logs",
					term = "c:\temp"
				);
				expect(counts.escaped).toBe(1);
			});

			it("leaves a plain term matching exactly what a plain LIKE would", () => {
				var counts = $countsFor(
					literalRow = "ordinary words here",
					wildcardRow = "nothing to see",
					term = "ordinary"
				);
				expect(counts.escaped).toBe(1);
				expect(counts.raw).toBe(1);
			});

		});

	}

	/**
	 * Creates two posts — one whose title contains the search characters literally, one a raw wildcard
	 * would also catch — then counts what the escaped and (for comparison) unescaped patterns find,
	 * and rolls the posts back. `escaped` uses escapeForLike + an explicit ESCAPE '\'; `raw` drops both
	 * so the wildcard meaning of the metacharacter shows through.
	 */
	public struct function $countsFor(required string literalRow, required string wildcardRow, required string term) {
		var counts = {};
		transaction {
			g.model("post").create(title = arguments.literalRow, body = "escapeForLike fixture");
			g.model("post").create(title = arguments.wildcardRow, body = "escapeForLike fixture");

			var escapedPattern = "%" & g.escapeForLike(arguments.term) & "%";
			var rawPattern = "%" & arguments.term & "%";

			counts.escaped = g.model("post")
				.findAll(where = "title LIKE '#escapedPattern#' ESCAPE '\'", returnAs = "query", reload = true)
				.recordCount;
			counts.raw = g.model("post")
				.findAll(where = "title LIKE '#rawPattern#'", returnAs = "query", reload = true)
				.recordCount;

			transaction action = "rollback";
		}
		return counts;
	}

}
