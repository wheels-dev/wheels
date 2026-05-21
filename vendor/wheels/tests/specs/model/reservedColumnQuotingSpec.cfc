component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$createSQLFieldList column identifier quoting", () => {

			it("quotes the underlying column when a property aliases a different column name", () => {
				// City has `property(name="id", column="countyid")`, so SELECT id must
				// render the column part quoted to survive databases where the column
				// name is a reserved word (e.g. `key` on MSSQL, `order` everywhere).
				var m = g.model("city");
				var actual = m.$selectClause(select = "id", include = "", returnAs = "objects");
				var qTable = m.$quoteColumn("c_o_r_e_cities");
				var qCol = m.$quoteColumn("countyid");

				expect(actual).toInclude(qTable & "." & qCol);
			});

			it("quotes the column when the property name matches the column name", () => {
				// Author.firstName has no column mapping (property == column). SELECT
				// firstName must still wrap the column identifier so reserved words
				// like `order` or `key` survive the SELECT clause.
				var m = g.model("author");
				var actual = m.$selectClause(select = "firstName", include = "", returnAs = "objects");
				var qTable = m.$quoteColumn("c_o_r_e_authors");
				var qCol = m.$quoteColumn("firstName");

				expect(actual).toInclude(qTable & "." & qCol);
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
				var qTable = m.$quoteColumn("c_o_r_e_cities");
				var qCol = m.$quoteColumn("countyid");

				expect(actual).toInclude(qTable & "." & qCol);
			});

		});
	}
}
