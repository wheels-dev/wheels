component extends="wheels.WheelsTest" {

	function run() {

		describe("Query Scopes", () => {

			describe("static scopes", () => {

				it("filters with a where scope", () => {
					var result = model("authorScoped").withLastNameDjurner().findAll();
					expect(result.recordcount).toBe(1);
					expect(result.lastname).toBe("Djurner");
				})

				it("orders with an order scope", () => {
					var result = model("authorScoped").orderedByFirstName().findAll();
					expect(result.firstname[1]).toBe("Adam");
				})

				it("limits with a maxRows scope", () => {
					var result = model("authorScoped").firstThree().findAll(order = "id");
					expect(result.recordcount).toBe(3);
				})

			})

			describe("chaining", () => {

				it("chains multiple scopes together", () => {
					var result = model("authorScoped").orderedByFirstName().firstThree().findAll();
					expect(result.recordcount).toBe(3);
					expect(result.firstname[1]).toBe("Adam");
				})

				it("returns a chainable object, not a query", () => {
					var chain = model("authorScoped").withLastNameDjurner();
					expect(IsQuery(chain)).toBeFalse();
					expect(IsSimpleValue(chain)).toBeFalse();
				})

				it("merges scope WHERE with finder WHERE using AND", () => {
					var result = model("authorScoped").withLastNameDjurner().findAll(where = "firstname = 'Per'");
					expect(result.recordcount).toBe(1);
					expect(result.firstname).toBe("Per");
				})

			})

			describe("dynamic scopes", () => {

				it("accepts arguments via a handler function", () => {
					var result = model("authorScoped").byLastName("Petruzzi").findAll();
					expect(result.recordcount).toBe(1);
					expect(result.lastname).toBe("Petruzzi");
				})

			})

			describe("terminal methods", () => {

				it("works with count()", () => {
					var result = model("authorScoped").withLastNameDjurner().count();
					expect(result).toBe(1);
				})

				it("works with findOne()", () => {
					var result = model("authorScoped").withLastNameDjurner().findOne();
					expect(IsObject(result)).toBeTrue();
					expect(result.lastName).toBe("Djurner");
				})

				it("works with exists()", () => {
					var result = model("authorScoped").withLastNameDjurner().exists();
					expect(result).toBeTrue();
				})

				it("accepts additional finder args", () => {
					var result = model("authorScoped").orderedByFirstName().findAll(select = "firstname");
					expect(result.recordcount).toBeGT(0);
				})

			})

			it("returns empty results for non-matching scope", () => {
				var result = model("authorScoped").byLastName("NonExistent").findAll();
				expect(result.recordcount).toBe(0);
			})

		})

	}
}
