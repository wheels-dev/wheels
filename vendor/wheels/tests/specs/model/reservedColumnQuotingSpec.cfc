component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$createSQLFieldList column identifier quoting", () => {

			it("quotes the underlying column when a property aliases a different column name", () => {
				// City aliases id -> countyid, so the SELECT column must be quoted in case it is a reserved word.
				var m = g.model("city");
				var actual = m.$selectClause(select = "id", include = "", returnAs = "objects");

				expect(actual).toInclude(m.$quotedTableName() & "." & m.$quoteColumn("countyid"));
			});

			it("quotes the column when the property name matches the column name", () => {
				// Author.firstName has no column mapping (property == column); SELECT must still quote the identifier.
				var m = g.model("author");
				var actual = m.$selectClause(select = "firstName", include = "", returnAs = "objects");

				expect(actual).toInclude(m.$quotedTableName() & "." & m.$quoteColumn("firstName"));
			});

			it("quotes column identifiers in the GROUP BY clause too", () => {
				// $groupByClause routes through the same $createSQLFieldList builder.
				var m = g.model("city");
				var actual = m.$groupByClause(
					select = "id",
					include = "",
					group = "id",
					distinct = false,
					returnAs = "objects"
				);

				expect(actual).toInclude(m.$quotedTableName() & "." & m.$quoteColumn("countyid"));
			});

			it("returns a well-formed empty query when paginated findAll matches zero rows on an aliased column", () => {
				// Without $stripIdentifierQuotes, dialect quote chars from $createSQLFieldList leak into QueryNew column names.
				var m = g.model("city");
				var rv = m.findAll(select = "id", where = "id = -1", page = 1, perPage = 25);

				expect(IsQuery(rv)).toBeTrue();
				expect(rv.recordCount).toBe(0);
				expect(ListFindNoCase(rv.columnList, "id")).toBeGT(0);
			});

		});
	}
}
