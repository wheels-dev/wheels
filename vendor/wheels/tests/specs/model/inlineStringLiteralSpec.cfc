component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// String values that end up in the SQL text instead of a bound parameter:
		// parameterize=false, and literals the WHERE parser leaves in place
		// (function arguments, ESCAPE clauses). Each adapter writes them with
		// $inlineStringLiteral().

		describe("Adapter $inlineStringLiteral", () => {

			it("doubles single quotes in the Base adapter", () => {
				var adapter = new wheels.databaseAdapters.Base();
				expect(adapter.$inlineStringLiteral("O'Brien")).toBe("'O''Brien'");
				expect(adapter.$inlineStringLiteral("")).toBe("''");
			})

			it("leaves a backslash as an ordinary character in the Base adapter", () => {
				var adapter = new wheels.databaseAdapters.Base();
				expect(adapter.$inlineStringLiteral("a\b")).toBe("'a\b'");
			})

			it("writes a plain value as a quoted literal on MySQL", () => {
				var adapter = new wheels.databaseAdapters.MySQL.MySQLModel();
				expect(adapter.$inlineStringLiteral("O'Brien")).toBe("'O''Brien'");
			})

			it("writes a value containing a backslash as a hex literal on MySQL", () => {
				var adapter = new wheels.databaseAdapters.MySQL.MySQLModel();
				expect(adapter.$inlineStringLiteral("a\b")).toBe("_utf8mb4 X'615C62'");
				var literal = adapter.$inlineStringLiteral("x'y\");
				expect(Left(literal, 11)).toBe("_utf8mb4 X'");
				expect(Find("\", literal)).toBe(0, literal);
				expect(ReFind("^_utf8mb4 X'[0-9A-F]+'$", literal)).toBe(1, literal);
			})

			it("writes a LIKE ... ESCAPE character as a single character", () => {
				var base = new wheels.databaseAdapters.Base();
				expect(base.$inlineEscapeCharacter("!")).toBe("'!'");
				var mysql = new wheels.databaseAdapters.MySQL.MySQLModel();
				expect(mysql.$inlineEscapeCharacter("!")).toBe("'!'");
				expect(mysql.$inlineEscapeCharacter("\")).toBe("_utf8mb4 X'5C'");
				expect(mysql.$inlineEscapeCharacter("\\")).toBe("_utf8mb4 X'5C'");
			})

			it("finds the ESCAPE keyword before a literal whatever whitespace separates them", () => {
				var m = g.model("author");
				var longGap = "lastName LIKE UPPER('x') ESCAPE" & RepeatString(" ", 40);
				expect(m.$followsEscapeKeyword(longGap & "'", Len(longGap) + 1)).toBeTrue();
				var newline = "lastName LIKE UPPER('x') escape" & Chr(10) & Chr(9);
				expect(m.$followsEscapeKeyword(newline & "'", Len(newline) + 1)).toBeTrue();
				var identifier = "lastName = NOESCAPE ";
				expect(m.$followsEscapeKeyword(identifier & "'", Len(identifier) + 1)).toBeFalse();
				var plain = "lastName = ";
				expect(m.$followsEscapeKeyword(plain & "'", Len(plain) + 1)).toBeFalse();
				expect(m.$followsEscapeKeyword("'", 1)).toBeFalse();
			})

			it("keeps an N-prefixed literal valid when it is restored", () => {
				var m = g.model("author");
				var restored = m.$restoreMaskedLiterals(m.$maskWhereLiterals("lastName = UPPER(N'q\z') OR lastName = UPPER(N'plain')"));
				if (FindNoCase("MySQL", g.get("adapterName"))) {
					expect(restored).toBe("lastName = UPPER(_utf8mb4 X'715C7A') OR lastName = UPPER(N'plain')");
				} else {
					expect(restored).toBe("lastName = UPPER(N'q\z') OR lastName = UPPER(N'plain')");
				}
			})

			it("passes a numeric value through $inlineValue unquoted", () => {
				var adapter = new wheels.databaseAdapters.Base();
				expect(adapter.$inlineValue(str = "42", sqlType = "cf_sql_integer")).toBe("42");
				expect(adapter.$inlineValue(str = "O'Brien", sqlType = "cf_sql_varchar")).toBe("'O''Brien'");
			})

		})

		describe("Inline string values round-trip", () => {

			it("matches values containing a backslash on every inline path", () => {
				var counts = {};
				transaction {
					g.model("author").create(firstName = "Inline", lastName = "Q\Z");
					g.model("author").create(firstName = "Inline", lastName = "TAIL\");
					counts.paramFalseEquals = g.model("author").findAll(where = "lastName = 'Q\Z'", parameterize = false, returnAs = "query", reload = true).recordCount;
					counts.paramFalseTrailing = g.model("author").findAll(where = "lastName = 'TAIL\'", parameterize = false, returnAs = "query", reload = true).recordCount;
					counts.paramFalseIn = g.model("author").findAll(where = "lastName IN ('Q\Z','zznope')", parameterize = false, returnAs = "query", reload = true).recordCount;
					counts.functionArgument = g.model("author").findAll(where = "lastName = UPPER('q\z')", returnAs = "query", reload = true).recordCount;
					counts.functionArgumentTrailing = g.model("author").findAll(where = "lastName = UPPER('tail\')", returnAs = "query", reload = true).recordCount;
					transaction action = "rollback";
				}
				expect(counts.paramFalseEquals).toBe(1, "parameterize=false =");
				expect(counts.paramFalseTrailing).toBe(1, "parameterize=false = (trailing backslash)");
				expect(counts.paramFalseIn).toBe(1, "parameterize=false IN");
				expect(counts.functionArgument).toBe(1, "function argument");
				expect(counts.functionArgumentTrailing).toBe(1, "function argument (trailing backslash)");
			})

			// One restore pass that writes an ODBC date escape verbatim and a backslash
			// literal through the adapter, with parameterize=false, in both MySQL sql_modes.
			// MySQL only: backslash handling depends on MySQL's sql_mode, which no other
			// database has. Inline dates on Oracle are covered by inlineDateLiteralSpec.
			it("restores an ODBC date escape and a backslash literal in one where string on MySQL", () => {
				var adapterName = g.get("adapterName");
				if (!FindNoCase("MySQL", adapterName)) {
					skip("MySQL/MariaDB sql_mode behaviour, not `#adapterName#`.");
				}
				var ds = g.get("dataSourceName");
				var state = {counts = {}, modes = {}, savedMode = ""};
				var since = "createdAt > {ts '2000-01-01 00:00:00'} AND title = UPPER('q\odbc')";
				var future = "createdAt > {ts '2999-01-01 00:00:00'} AND title = UPPER('q\odbc')";
				transaction {
					state.savedMode = queryExecute("SELECT @@SESSION.sql_mode AS m", [], {datasource = ds}).m;
					try {
						g.model("post").create(title = "Q\ODBC", body = "inline literal restore");
						queryExecute("SET SESSION sql_mode = REPLACE(@@SESSION.sql_mode, 'NO_BACKSLASH_ESCAPES', '')", [], {datasource = ds});
						state.modes.off = queryExecute("SELECT @@SESSION.sql_mode AS m", [], {datasource = ds}).m;
						state.counts.off = g.model("post").count(where = since, parameterize = false);
						state.counts.futureOff = g.model("post").count(where = future, parameterize = false);
						queryExecute("SET SESSION sql_mode = CONCAT(@@SESSION.sql_mode, ',NO_BACKSLASH_ESCAPES')", [], {datasource = ds});
						state.modes.on = queryExecute("SELECT @@SESSION.sql_mode AS m", [], {datasource = ds}).m;
						state.counts.on = g.model("post").count(where = since, parameterize = false);
					} finally {
						queryExecute("SET SESSION sql_mode = ?", [state.savedMode], {datasource = ds});
					}
					transaction action = "rollback";
				}
				expect(FindNoCase("NO_BACKSLASH_ESCAPES", state.modes.off)).toBe(0, "first run without NO_BACKSLASH_ESCAPES: [#state.modes.off#]");
				expect(FindNoCase("NO_BACKSLASH_ESCAPES", state.modes.on)).toBeGT(0, "second run with NO_BACKSLASH_ESCAPES: [#state.modes.on#]");
				expect(state.counts.off).toBe(1, "past {ts} date + backslash literal, default sql_mode");
				expect(state.counts.futureOff).toBe(0, "future {ts} date excludes the row");
				expect(state.counts.on).toBe(1, "past {ts} date + backslash literal, NO_BACKSLASH_ESCAPES");
			})

			it("matches a literal underscore with LIKE UPPER(...) ESCAPE '\'", () => {
				var counts = {};
				transaction {
					g.model("author").create(firstName = "Escape", lastName = "ZQ_ESC");
					g.model("author").create(firstName = "Escape", lastName = "ZQXESC");
					counts.escaped = g.model("author").findAll(where = "lastName LIKE UPPER('zq\_%') ESCAPE '\'", returnAs = "query", reload = true).recordCount;
					counts.wildcard = g.model("author").findAll(where = "lastName LIKE 'ZQ_%'", returnAs = "query", reload = true).recordCount;
					transaction action = "rollback";
				}
				expect(counts.escaped).toBe(1, "escaped underscore");
				expect(counts.wildcard).toBe(2, "plain wildcard");
			})

			it("keeps the MySQL ESCAPE '\\' spelling working in both sql_modes", () => {
				if (!FindNoCase("MySQL", g.get("adapterName"))) {
					skip("MySQL/MariaDB escape-character spelling");
				}
				var ds = g.get("dataSourceName");
				var state = {counts = {}, savedMode = ""};
				transaction {
					state.savedMode = queryExecute("SELECT @@SESSION.sql_mode AS m", [], {datasource = ds}).m;
					try {
						g.model("author").create(firstName = "Escape", lastName = "ZQ_ESC");
						g.model("author").create(firstName = "Escape", lastName = "ZQXESC");
						queryExecute("SET SESSION sql_mode = REPLACE(@@SESSION.sql_mode, 'NO_BACKSLASH_ESCAPES', '')", [], {datasource = ds});
						state.counts.defaultMode = g.model("author").findAll(where = "lastName LIKE UPPER('zq\_%') ESCAPE '\\'", returnAs = "query", reload = true).recordCount;
						queryExecute("SET SESSION sql_mode = CONCAT(@@SESSION.sql_mode, ',NO_BACKSLASH_ESCAPES')", [], {datasource = ds});
						state.counts.noBackslashEscapes = g.model("author").findAll(where = "lastName LIKE UPPER('zq\_%') ESCAPE '\\'", returnAs = "query", reload = true).recordCount;
						state.counts.portableNoBackslashEscapes = g.model("author").findAll(where = "lastName LIKE UPPER('zq\_%') ESCAPE '\'", returnAs = "query", reload = true).recordCount;
						state.counts.longGap = g.model("author").findAll(where = "lastName LIKE UPPER('zq\_%') ESCAPE" & RepeatString(" ", 40) & "'\\'", returnAs = "query", reload = true).recordCount;
						state.counts.national = g.model("author").findAll(where = "lastName LIKE UPPER(N'zq\_%') ESCAPE '\'", returnAs = "query", reload = true).recordCount;
					} finally {
						queryExecute("SET SESSION sql_mode = ?", [state.savedMode], {datasource = ds});
					}
					transaction action = "rollback";
				}
				expect(state.counts.defaultMode).toBe(1, "default sql_mode");
				expect(state.counts.noBackslashEscapes).toBe(1, "NO_BACKSLASH_ESCAPES");
				expect(state.counts.portableNoBackslashEscapes).toBe(1, "NO_BACKSLASH_ESCAPES, single backslash");
				expect(state.counts.longGap).toBe(1, "40 spaces after ESCAPE");
				expect(state.counts.national).toBe(1, "N-prefixed pattern");
			})

			it("matches backslash values in latin1, utf8mb3 and binary-collation columns on MySQL", () => {
				if (!FindNoCase("MySQL", g.get("adapterName"))) {
					skip("MySQL/MariaDB column character sets");
				}
				var ds = g.get("dataSourceName");
				var adapter = new wheels.databaseAdapters.MySQL.MySQLModel();
				var value = "Q\Z " & Chr(233);
				var literal = adapter.$inlineStringLiteral(value);
				var state = {counts = {}};
				queryExecute("DROP TABLE IF EXISTS c_o_r_e_inlinecharsets", [], {datasource = ds});
				queryExecute(
					"CREATE TABLE c_o_r_e_inlinecharsets ("
					& "l1 VARCHAR(40) CHARACTER SET latin1, "
					& "l1bin VARCHAR(40) CHARACTER SET latin1 COLLATE latin1_bin, "
					& "u3 VARCHAR(40) CHARACTER SET utf8mb3, "
					& "u4bin VARCHAR(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin)",
					[],
					{datasource = ds}
				);
				try {
					// Seed with the same literal rather than bound parameters: under
					// NO_BACKSLASH_ESCAPES the JDBC driver sends a bound string that
					// contains a backslash in a way latin1/utf8mb3 columns store
					// mangled, which would test the driver instead of the literal.
					queryExecute(
						"INSERT INTO c_o_r_e_inlinecharsets (l1, l1bin, u3, u4bin) VALUES (#literal#, #literal#, #literal#, #literal#)",
						[],
						{datasource = ds}
					);
					for (var column in ["l1", "l1bin", "u3", "u4bin"]) {
						state.counts[column] = queryExecute(
							"SELECT COUNT(*) AS n FROM c_o_r_e_inlinecharsets WHERE #column# = #literal#",
							[],
							{datasource = ds}
						).n;
					}
				} finally {
					queryExecute("DROP TABLE IF EXISTS c_o_r_e_inlinecharsets", [], {datasource = ds});
				}
				expect(Left(literal, 11)).toBe("_utf8mb4 X'");
				expect(state.counts.l1).toBe(1, "latin1");
				expect(state.counts.l1bin).toBe(1, "latin1_bin");
				expect(state.counts.u3).toBe(1, "utf8mb3");
				expect(state.counts.u4bin).toBe(1, "utf8mb4_bin");
			})

			it("still matches backslash values on the bound paths (no double escaping)", () => {
				var counts = {};
				transaction {
					g.model("author").create(firstName = "Bound", lastName = "Q\Z");
					counts.whereString = g.model("author").findAll(where = "lastName = 'Q\Z'", returnAs = "query", reload = true).recordCount;
					counts.whereIn = g.model("author").findAll(where = "lastName IN ('Q\Z','zznope')", returnAs = "query", reload = true).recordCount;
					counts.builder = g.model("author").where("lastName", "Q\Z").get().recordCount;
					counts.dynamicFinder = IsObject(g.model("author").findOneByLastName("Q\Z")) ? 1 : 0;
					transaction action = "rollback";
				}
				expect(counts.whereString).toBe(1, "where string");
				expect(counts.whereIn).toBe(1, "where IN");
				expect(counts.builder).toBe(1, "query builder");
				expect(counts.dynamicFinder).toBe(1, "dynamic finder");
			})

		})

	}

}
