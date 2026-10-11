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

		describe("escapeForLike adapter resolution", () => {

			it("does not throw when no model class has set the application adapterName yet", () => {
				var wo = application.wo;
				var appScope = application[wo.$appKey()];
				var hadKey = StructKeyExists(appScope, "adapterName");
				var saved = hadKey ? appScope.adapterName : "";
				// Simulate a fresh app / just-reloaded state: no adapterName set yet. escapeForLike must
				// resolve the adapter without letting $get() throw — it falls back to "" (treated as not
				// SQL Server). Restore in a catch-free finally (no loop) so the shared application scope
				// is left intact.
				try {
					StructDelete(appScope, "adapterName");
					expect(wo.escapeForLike("a%b")).toBe("a\%b");
				} finally {
					if (hadKey) {
						appScope.adapterName = saved;
					}
				}
			});

			it("prefers a model instance's own adapter over the global default", () => {
				var wo = application.wo;
				var appScope = application[wo.$appKey()];
				var hadKey = StructKeyExists(appScope, "adapterName");
				var saved = hadKey ? appScope.adapterName : "";
				var modelAdapter = model("post").$adapterNameForLike();
				// Point the global at a DIFFERENT adapter; a model still resolves its own (so a
				// multi-datasource app escapes `[` per the model's database, not the last-initialised one).
				var bogus = (modelAdapter == "MicrosoftSQLServerModel") ? "SQLiteModel" : "MicrosoftSQLServerModel";
				try {
					appScope.adapterName = bogus;
					expect(model("post").$adapterNameForLike()).toBe(modelAdapter);
				} finally {
					if (hadKey) {
						appScope.adapterName = saved;
					} else {
						StructDelete(appScope, "adapterName");
					}
				}
			});

		});

	}

}
