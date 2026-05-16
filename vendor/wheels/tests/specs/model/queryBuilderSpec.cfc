component extends="wheels.WheelsTest" {

	function run() {

		describe("Query Builder", () => {

			describe("where()", () => {

				it("filters with equality (2-arg form)", () => {
					var result = model("author").where("lastName", "Djurner").get();
					expect(result.recordcount).toBe(1);
					expect(result.lastname).toBe("Djurner");
				})

				it("filters with an operator (3-arg form)", () => {
					var result = model("post").where("views", ">", 0).get();
					expect(result.recordcount).toBeGT(0);
				})

				it("passes through raw SQL strings (1-arg form)", () => {
					var result = model("author").where("lastName = 'Djurner'").get();
					expect(result.recordcount).toBe(1);
				})

				it("chains multiple where conditions with AND", () => {
					var result = model("author").where("firstName", "Per").where("lastName", "Djurner").get();
					expect(result.recordcount).toBe(1);
				})

			})

			describe("orWhere()", () => {

				it("combines conditions with OR", () => {
					var result = model("author").where("lastName", "Djurner").orWhere("lastName", "Petruzzi").get();
					expect(result.recordcount).toBe(2);
				})

			})

			describe("NULL checks", () => {

				it("filters with whereNull()", () => {
					var result = model("post").whereNull("deletedat").get();
					expect(result.recordcount).toBeGT(0);
				})

				it("filters with whereNotNull()", () => {
					var result = model("post").whereNotNull("averagerating").get();
					expect(result.recordcount).toBeGT(0);
				})

			})

			describe("whereBetween()", () => {

				it("filters values in a range", () => {
					var result = model("post").whereBetween("views", 1, 5).get();
					expect(result.recordcount).toBeGT(0);
				})

			})

			describe("whereIn() / whereNotIn()", () => {

				it("matches values in a list", () => {
					var result = model("author").whereIn("lastName", "Djurner,Petruzzi").get();
					expect(result.recordcount).toBe(2);
				})

				it("matches values in an array", () => {
					var result = model("author").whereIn("lastName", ["Djurner", "Petruzzi"]).get();
					expect(result.recordcount).toBe(2);
				})

				it("excludes values with whereNotIn()", () => {
					var totalCount = model("author").count();
					var result = model("author").whereNotIn("lastName", "Djurner,Petruzzi").get();
					expect(result.recordcount).toBe(totalCount - 2);
				})

				it("whereIn() with an empty array matches no rows", () => {
					var result = model("author").whereIn("id", []).count();
					expect(result).toBe(0);
				})

				it("whereIn() with an empty list matches no rows", () => {
					var result = model("author").whereIn("id", "").count();
					expect(result).toBe(0);
				})

				it("whereNotIn() with an empty array matches every row", () => {
					var totalCount = model("author").count();
					var result = model("author").whereNotIn("id", []).count();
					expect(result).toBe(totalCount);
				})

				it("whereNotIn() with an empty list matches every row", () => {
					var totalCount = model("author").count();
					var result = model("author").whereNotIn("id", "").count();
					expect(result).toBe(totalCount);
				})

				it("whereIn() with an empty array composes cleanly with other clauses", () => {
					var result = model("author").where("lastName", "Djurner").whereIn("id", []).count();
					expect(result).toBe(0);
				})

				it("whereNotIn() with an empty array composes cleanly with other clauses", () => {
					var result = model("author").where("lastName", "Djurner").whereNotIn("id", []).count();
					expect(result).toBe(1);
				})

				it("whereIn() with an empty array returns a properly-shaped empty query from findAll()", () => {
					var result = model("author").whereIn("id", []).findAll();
					expect(result.recordcount).toBe(0);
					// columnList must match a normal zero-row findAll() shape — callers introspect it.
					expect(Len(result.columnList)).toBeGT(0);
				})

				it("whereIn() with an empty array returns false from first()/findOne()", () => {
					var result = model("author").whereIn("id", []).first();
					expect(result).toBeFalse();
				})

				it("whereIn() with an empty array returns false from exists()", () => {
					var result = model("author").whereIn("id", []).exists();
					expect(result).toBeFalse();
				})

				it("whereIn() with an empty array returns 0 from updateAll() without touching rows", () => {
					var before = model("author").count();
					var affected = model("author").whereIn("id", []).updateAll(firstName="ShouldNotChange");
					var after = model("author").where("firstName", "ShouldNotChange").count();
					expect(affected).toBe(0);
					expect(after).toBe(0);
					expect(model("author").count()).toBe(before);
				})

				it("whereIn() with an empty array returns 0 from deleteAll() without removing rows", () => {
					var before = model("author").count();
					var affected = model("author").whereIn("id", []).deleteAll();
					expect(affected).toBe(0);
					expect(model("author").count()).toBe(before);
				})

				it("whereIn() with an empty array never invokes the findEach() callback", () => {
					var state = {invoked: 0};
					model("author").whereIn("id", []).findEach(callback=function(row) {
						state.invoked += 1;
					});
					expect(state.invoked).toBe(0);
				})

				it("whereIn() with an empty array never invokes the findInBatches() callback", () => {
					var state = {invoked: 0};
					model("author").whereIn("id", []).findInBatches(callback=function(batch) {
						state.invoked += 1;
					});
					expect(state.invoked).toBe(0);
				})

				it("whereIn() with an empty array ignores chained select() on findAll()", () => {
					// Locks in QueryBuilder.cfc findAll() short-circuit: $alwaysEmpty returns the full columnList, ignoring chained select().
					var result = model("author")
						.whereIn("id", [])
						.select("id")
						.findAll();
					expect(result.recordcount).toBe(0);
					expect(ListLen(result.columnList)).toBeGT(1);
				})

			})

			describe("orderBy()", () => {

				it("orders ascending", () => {
					var result = model("author").orderBy("firstName", "ASC").get();
					expect(result.firstname[1]).toBe("Adam");
				})

				it("orders descending", () => {
					var result = model("author").orderBy("firstName", "DESC").get();
					expect(result.firstname[1]).toBe("Tony");
				})

			})

			describe("limit()", () => {

				it("limits the number of results", () => {
					var result = model("author").limit(3).orderBy("id", "ASC").get();
					expect(result.recordcount).toBe(3);
				})

			})

			describe("terminal methods", () => {

				it("get() is an alias for findAll()", () => {
					var r1 = model("author").where("lastName", "Djurner").get();
					var r2 = model("author").where("lastName", "Djurner").findAll();
					expect(r1.recordcount).toBe(r2.recordcount);
				})

				it("first() returns a model object", () => {
					var result = model("author").where("lastName", "Djurner").first();
					expect(IsObject(result)).toBeTrue();
					expect(result.lastName).toBe("Djurner");
				})

				it("findOne() returns a model object", () => {
					var result = model("author").where("lastName", "Djurner").findOne();
					expect(IsObject(result)).toBeTrue();
				})

				it("count() returns the matching count", () => {
					var result = model("author").where("lastName", "Djurner").count();
					expect(result).toBe(1);
				})

				it("exists() returns true for matching records", () => {
					var result = model("author").where("lastName", "Djurner").exists();
					expect(result).toBeTrue();
				})

				it("exists() returns false for no matches", () => {
					var result = model("author").where("lastName", "NonExistent").exists();
					expect(result).toBeFalse();
				})

			})

			it("handles complex chains", () => {
				var result = model("author")
					.where("firstName", "Per")
					.whereNotNull("lastName")
					.orderBy("id", "ASC")
					.limit(10)
					.get();
				expect(result.recordcount).toBe(1);
				expect(result.firstname).toBe("Per");
			})

		})

	}
}
