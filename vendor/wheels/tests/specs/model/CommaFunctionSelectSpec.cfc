/**
 * Regression for #4634: a select= expression containing a SQL function with commas
 * (CONCAT/IF/COALESCE/...) must survive intact when include= enables the duplicate
 * prefix pass, and the distinct group-by pass must not split it into fragments.
 *
 * The expression's alias deliberately repeats the last column's name: the old
 * ListToArray-based split treated every fragment as a select item and dropped the
 * tail fragment as a "duplicate", corrupting the SQL.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("comma-bearing SQL functions in select (##4634)", () => {

			beforeEach(() => {
				// Alias == last column name, as in the issue's report.
				variables.expr = "CONCAT(IF(ISNULL(authors.firstname)=1, '', CONCAT(authors.firstname, ' ')), authors.firstname) AS firstname"
				variables.model = application.wo.model("post")
			})

			it("keeps the function expression intact through the include duplicate-prefix pass", () => {
				var sql = variables.model.$selectClause(select = "#variables.expr#", include = "author", returnAs = "query")
				expect(sql).toInclude(variables.expr)
			})

			it("does not drop the expression tail when a plain item precedes it", () => {
				var sql = variables.model.$selectClause(select = "id, #variables.expr#", include = "author", returnAs = "query")
				expect(sql).toInclude(variables.expr)
				// The old code truncated after the first fragment that collided by property name,
				// so the expression (the last select item) has to still be the end of the clause.
				expect(Right(sql, Len(variables.expr))).toBe(variables.expr)
			})

			it("keeps several comma-bearing functions intact side by side", () => {
				var functions = "COALESCE(authors.firstname, 'x', 'y') AS fn, COALESCE(authors.lastname, 'x', 'y') AS ln"
				var sql = variables.model.$selectClause(select = "id, #functions#", include = "author", returnAs = "query")
				expect(sql).toInclude("COALESCE(authors.firstname, 'x', 'y') AS fn")
				expect(sql).toInclude("COALESCE(authors.lastname, 'x', 'y') AS ln")
			})

			it("does not leak split subquery fragments into a distinct group by", () => {
				// Subquery select items are deliberately skipped in the GROUP BY clause; the old
				// ListToArray split kept the fragments that did not themselves contain SELECT.
				var expr = "(SELECT CONCAT(authors.firstname, ' ') FROM c_o_r_e_authors) AS subname"
				var groupSql = variables.model.$groupByClause(select = "id, #expr#", include = "author", group = "", distinct = true, returnAs = "query")
				expect(groupSql).toInclude("id")
				expect(groupSql).notToInclude("c_o_r_e_authors")
				expect(groupSql).notToInclude("subname")
			})

		})

	}

}
