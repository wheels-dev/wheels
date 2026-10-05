/**
 * escapeForLike() escapes the LIKE wildcards in a string so it can be used as a literal search term
 * in a `LIKE ... ESCAPE '\'` comparison: the escape character `\` is escaped first, then `%` and `_`
 * on every database, and `[` only when the default adapter is SQL Server (where `[` opens a character
 * class; on Oracle `\[` is an illegal escape sequence, ORA-01424). The per-DB behaviour of `ESCAPE '\'`
 * with a bound parameter is pinned by escapeForLikeQuerySpec across the compat matrix; this spec pins
 * the pure string transform.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("escapeForLike", () => {

			it("escapes %, _ and the backslash on every database", () => {
				var wo = application.wo;
				expect(wo.escapeForLike("a%b")).toBe("a\%b");
				expect(wo.escapeForLike("a_b")).toBe("a\_b");
				expect(wo.escapeForLike("a\b")).toBe("a\\b");
			});

			it("escapes the backslash first so wildcard escapes are not doubled", () => {
				var wo = application.wo;
				// "\" -> "\\"; then % and _ each gain one leading "\". "]" is never a wildcard, left as-is.
				expect(wo.escapeForLike("50%_\y")).toBe("50\%\_\\y");
			});

			it("escapes [ only when the default adapter is SQL Server", () => {
				var wo = application.wo;
				if (wo.$get("adapterName") == "MicrosoftSQLServerModel") {
					expect(wo.escapeForLike("a[b")).toBe("a\[b");
					expect(wo.escapeForLike("50%[x]")).toBe("50\%\[x]");
				} else {
					// '[' is a literal character on MySQL / PostgreSQL / SQLite / H2 / CockroachDB / Oracle,
					// and '\[' would be an illegal escape sequence on Oracle (ORA-01424), so it is left as-is.
					expect(wo.escapeForLike("a[b")).toBe("a[b");
					expect(wo.escapeForLike("50%[x]")).toBe("50\%[x]");
				}
			});

			it("leaves a string with no wildcards unchanged, and handles empty", () => {
				var wo = application.wo;
				expect(wo.escapeForLike("plain text")).toBe("plain text");
				expect(wo.escapeForLike("")).toBe("");
			});

		});

	}

}
