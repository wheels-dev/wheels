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
