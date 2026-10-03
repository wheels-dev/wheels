/**
 * An empty string in a `where` value binds as a real empty string (#4055), so it
 * matches rows that store '' and `<>` / `!=` match every other non-NULL row. The
 * unquoted NULL keyword still binds as NULL, and so does an empty value for a column
 * that can't hold '' (numbers, dates). Oracle stores '' as NULL, so an empty-string
 * comparison matches no row there.
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
