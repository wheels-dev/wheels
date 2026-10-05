/**
 * escapeForLike() escapes the LIKE wildcards in a string so it can be used as a literal search term
 * in a `LIKE :q ESCAPE '\'` comparison: the escape character `\` is escaped first, then `%`, `_` and
 * `[` (a wildcard on SQL Server). The per-DB behaviour of `ESCAPE '\'` with a bound parameter is
 * pinned by escapeForLikeQuerySpec, which runs across the compat matrix; this spec pins the pure
 * string transform.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("escapeForLike", () => {

			it("escapes each LIKE wildcard with a backslash", () => {
				var wo = application.wo;
				expect(wo.escapeForLike("a%b")).toBe("a\%b");
				expect(wo.escapeForLike("a_b")).toBe("a\_b");
				expect(wo.escapeForLike("a[b")).toBe("a\[b");
				expect(wo.escapeForLike("a\b")).toBe("a\\b");
			});

			it("escapes the backslash first so wildcard escapes are not doubled", () => {
				var wo = application.wo;
				// "\" -> "\\"; then %,_,[ each gain one leading "\"; "]" is not a wildcard, left as-is.
				expect(wo.escapeForLike("50%_[x]\y")).toBe("50\%\_\[x]\\y");
			});

			it("leaves a string with no wildcards unchanged, and handles empty", () => {
				var wo = application.wo;
				expect(wo.escapeForLike("plain text")).toBe("plain text");
				expect(wo.escapeForLike("")).toBe("");
			});

		});

	}

}
