/**
 * An empty string in a `where` value binds as a real empty string (#4055), so it
 * matches rows that store '' and `<>` / `!=` match every other non-NULL row. The
 * unquoted NULL keyword still binds as NULL, and so does an empty value whose parameter
 * doesn't bind as a string (number, date, time and boolean cf_sql types). The bind type
 * decides: SQLite binds its text datetimes as strings. Oracle stores '' as NULL, so an
 * empty-string comparison matches no row there.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Empty-string where values", () => {

			beforeEach(() => {
				isOracle = g.get("adapterName") == "OracleModel"
			})

			it("matches a row that stores an empty string with = ''", () => {
				if (isOracle) {
					expect(g.model("author").count(where = "lastName = ''")).toBe(0)
					return
				}
				var state = {blank = -1, raw = -1}
				transaction {
					g.model("author").create(firstName = "Blank", lastName = "", validate = false)
					state.blank = g.model("author").count(where = "lastName = ''")
					state.raw = rawCount("lastname = ''")
					transaction action="rollback";
				}
				expect(state.raw).toBe(1)
				expect(state.blank).toBe(state.raw)
			})

			it("matches the downstream shape: a key AND an empty string", () => {
				if (isOracle) {
					skip("Oracle stores '' as NULL.")
				}
				var state = {n = -1}
				transaction {
					var a = g.model("author").create(firstName = "Blank", lastName = "", validate = false)
					state.n = g.model("author").count(where = "id = '#a.id#' AND lastName = ''")
					transaction action="rollback";
				}
				expect(state.n).toBe(1)
			})

			it("matches every other non-NULL row with <> '' and != ''", () => {
				var state = {ne = -1, bang = -1, raw = -1}
				transaction {
					if (!isOracle) {
						g.model("author").create(firstName = "Blank", lastName = "", validate = false)
					}
					state.ne = g.model("author").count(where = "lastName <> ''")
					state.bang = g.model("author").count(where = "lastName != ''")
					state.raw = rawCount("lastname <> ''")
					transaction action="rollback";
				}
				if (isOracle) {
					// '' is NULL on Oracle, so <> '' is never true.
					expect(state.ne).toBe(0)
					expect(state.bang).toBe(0)
				} else {
					expect(state.raw).toBeGT(0)
					expect(state.ne).toBe(state.raw)
					expect(state.bang).toBe(state.raw)
				}
			})

			it("matches an empty string in dynamic finders, the query builder and parameterize=false", () => {
				if (isOracle) {
					skip("Oracle stores '' as NULL.")
				}
				var state = {finder = "", builder = -1, inline = -1}
				transaction {
					var a = g.model("author").create(firstName = "BlankFinder", lastName = "", validate = false)
					var found = g.model("author").findOneByLastName("")
					state.finder = IsObject(found) ? found.firstName : ""
					state.builder = g.model("author").where("lastName", "").count()
					state.inline = g.model("author").count(where = "lastName = ''", parameterize = false)
					transaction action="rollback";
				}
				expect(state.finder).toBe("BlankFinder")
				expect(state.builder).toBe(1)
				expect(state.inline).toBe(1)
			})

			it("deletes and updates rows that store an empty string", () => {
				if (isOracle) {
					skip("Oracle stores '' as NULL.")
				}
				var state = {updated = -1, deleted = -1, left = -1}
				transaction {
					g.model("author").create(firstName = "BlankUpd", lastName = "", validate = false)
					state.updated = g.model("author").updateAll(firstName = "BlankUpd2", where = "lastName = ''")
					state.deleted = g.model("author").deleteAll(where = "lastName = ''")
					state.left = rawCount("lastname = ''")
					transaction action="rollback";
				}
				expect(state.updated).toBe(1)
				expect(state.deleted).toBe(1)
				expect(state.left).toBe(0)
			})

			it("still binds the NULL keyword as NULL", () => {
				expect(g.model("author").count(where = "lastName IS NULL")).toBe(rawCount("lastname IS NULL"))
				expect(g.model("author").count(where = "lastName IS NOT NULL")).toBe(rawCount("lastname IS NOT NULL"))
			})

			it("binds an empty value as NULL only for parameters that don't bind as a string", () => {
				var m = g.model("author")
				var nullTypes = "cf_sql_integer,CF_SQL_BIGINT,cf_sql_smallint,cf_sql_tinyint,cf_sql_decimal,cf_sql_float,cf_sql_date,cf_sql_time,cf_sql_timestamp,CF_SQL_TIMESTAMP,cf_sql_bit,CF_SQL_BIT"
				for (var t in ListToArray(nullTypes)) {
					expect(m.$whereValueBindsNull(value = "", nullKeyword = false, type = t)).toBeTrue(t)
				}
				var stringTypes = "cf_sql_varchar,CF_SQL_VARCHAR,cf_sql_char,cf_sql_nvarchar,cf_sql_longvarchar,CF_SQL_LONGNVARCHAR"
				for (var t in ListToArray(stringTypes)) {
					expect(m.$whereValueBindsNull(value = "", nullKeyword = false, type = t)).toBeFalse(t)
				}
				// No type recorded: a string.
				expect(m.$whereValueBindsNull(value = "", nullKeyword = false, type = "")).toBeFalse()
				// The NULL keyword is NULL whatever the type; a non-empty value never is.
				expect(m.$whereValueBindsNull(value = "", nullKeyword = true, type = "cf_sql_varchar")).toBeTrue()
				expect(m.$whereValueBindsNull(value = "0", nullKeyword = false, type = "cf_sql_integer")).toBeFalse()
			})

			it("matches nothing, without an error, for an empty value on boolean and datetime columns", () => {
				// booleanType binds as a bit/integer everywhere, so '' is NULL: no match, and no
				// bind error on Adobe.
				var state = {err = "", boolEq = -1, dtEq = -1, dtNe = -1, total = -1}
				try {
					state.total = g.model("sqlType").count()
					state.boolEq = g.model("sqlType").count(where = "booleanType = ''")
					state.dtEq = g.model("sqlType").count(where = "dateTimeType = ''")
					state.dtNe = g.model("sqlType").count(where = "dateTimeType <> ''")
				} catch (any e) {
					state.err = e.message
				}
				expect(state.err).toBe("")
				expect(state.boolEq).toBe(0)
				expect(state.dtEq).toBe(0)
				if (g.get("adapterName") == "SQLiteModel") {
					// SQLite stores datetimes as text and binds them as strings, so <> '' compares
					// text and matches every row.
					expect(state.dtNe).toBe(state.total)
				} else {
					// Everywhere else a datetime binds as a date, so '' is NULL and <> matches nothing.
					expect(state.dtNe).toBe(0)
				}
			})

			it("matches nothing, without an error, for an empty value on a numeric column", () => {
				var state = {n = -1, err = ""}
				try {
					state.n = g.model("author").count(where = "id = ''")
				} catch (any e) {
					state.err = e.message
				}
				expect(state.err).toBe("")
				expect(state.n).toBe(0)
			})

		})

	}

	// A raw count, so each expectation is checked against the database itself (inside the
	// spec's transaction, on the same datasource).
	private numeric function rawCount(required string condition) {
		return QueryExecute(
			"SELECT COUNT(*) AS n FROM c_o_r_e_authors WHERE #arguments.condition#",
			[],
			{datasource = g.get("dataSourceName")}
		).n;
	}

}
