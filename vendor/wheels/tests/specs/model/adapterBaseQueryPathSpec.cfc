component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// Coverage for the Base adapter query path (vendor/wheels/databaseAdapters/Base.cfc).

		describe("Base adapter non-parameterized IN lists", () => {

			// Regression: the parameterize=false branch used to add its own parentheses
			// inside the outer pair, emitting "IN ((1,2))" — a row-constructor syntax
			// error on every supported database.
			it("executes a multi-value IN clause without doubled parentheses when parameterize=false", () => {
				var sample = g.model("author").findAll(maxRows = 2, order = "id");
				expect(sample.recordCount).toBe(2);
				var idList = ValueList(sample.id);
				var expected = g.model("author").findAll(where = "id IN (#idList#)", order = "id");
				var actual = g.model("author").findAll(
					where = "id IN (#idList#)",
					order = "id",
					parameterize = false,
					reload = true
				);
				expect(actual.recordCount).toBe(2);
				expect(actual.recordCount).toBe(expected.recordCount);
			})
		})

		describe("Adapter $limitOffsetClause", () => {

			// The limit/offset dialect now comes from the adapter type instead of a
			// per-query $dbinfo version probe (a JDBC metadata round-trip per query).
			it("emits LIMIT/OFFSET from the Base adapter", () => {
				var adapter = new wheels.databaseAdapters.Base();
				expect(adapter.$limitOffsetClause(limit = 10, offset = 0)).toBe("LIMIT 10");
				var clause = adapter.$limitOffsetClause(limit = 10, offset = 20);
				expect(clause).toInclude("LIMIT 10");
				expect(clause).toInclude("OFFSET 20");
			})

			it("emits OFFSET/FETCH from the Oracle adapter", () => {
				var adapter = new wheels.databaseAdapters.Oracle.OracleModel();
				expect(adapter.$limitOffsetClause(limit = 10, offset = 0)).toBe("FETCH FIRST 10 ROWS ONLY");
				var clause = adapter.$limitOffsetClause(limit = 10, offset = 20);
				expect(clause).toInclude("OFFSET 20 ROWS");
				expect(clause).toInclude("FETCH NEXT 10 ROWS ONLY");
			})

			it("applies limit and offset end-to-end via paginated findAll", () => {
				var paged = g.model("author").findAll(order = "id", page = 2, perPage = 1);
				expect(paged.recordCount).toBe(1);
			})
		})
	}

}
