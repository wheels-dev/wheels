/**
 * The sort direction in an `order` string is read whatever its case or the whitespace before it:
 * `desc`, `Desc` and `DESC` all sort descending, through findAll(), paginated finders, dot-notation
 * items and the query builder's orderBy(). A lowercase direction used to sort ascending.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		var ids = variables.g.model("author").findAll(select = "id", order = "id ASC", returnAs = "query");
		variables.minId = ids.id[1];
		variables.maxId = ids.id[ids.recordCount];
	}

	function firstId(required query result) {
		return arguments.result.id[1];
	}

	function run() {

		describe("The direction in an order string", () => {

			it("sorts descending for desc in any case", () => {
				for (var dir in ["DESC", "desc", "Desc", "dEsC"]) {
					expect(firstId(variables.g.model("author").findAll(order = "id #dir#", maxRows = 1))).toBe(variables.maxId, "order=""id #dir#""");
				}
			});

			it("sorts ascending for asc in any case, and when no direction is given", () => {
				for (var dir in ["ASC", "asc", "Asc", ""]) {
					expect(firstId(variables.g.model("author").findAll(order = Trim("id #dir#"), maxRows = 1))).toBe(variables.minId, "order=""id #dir#""");
				}
			});

			it("reads the direction after repeated spaces or a tab", () => {
				expect(firstId(variables.g.model("author").findAll(order = "id   desc", maxRows = 1))).toBe(variables.maxId);
				expect(firstId(variables.g.model("author").findAll(order = "id#Chr(9)#desc", maxRows = 1))).toBe(variables.maxId);
				expect(firstId(variables.g.model("author").findAll(order = "  id desc  ", maxRows = 1))).toBe(variables.maxId);
			});

			it("reads each item's direction in a multi-column order", () => {
				var rows = variables.g.model("author").findAll(order = "lastName asc, id desc", returnAs = "query");
				var expected = variables.g.model("author").findAll(order = "lastName ASC, id DESC", returnAs = "query");
				expect(ValueList(rows.id)).toBe(ValueList(expected.id));
			});

			it("reads a lowercase direction on a table.column item", () => {
				var tableName = variables.g.model("author").tableName();
				expect(firstId(variables.g.model("author").findAll(order = "#tableName#.id desc", maxRows = 1))).toBe(variables.maxId);
			});

			it("reads a lowercase direction in a paginated finder", () => {
				expect(firstId(variables.g.model("author").findAll(order = "id desc", page = 1, perPage = 2))).toBe(variables.maxId);
			});

			it("reads a lowercase direction passed to the query builder's orderBy()", () => {
				expect(firstId(variables.g.model("author").orderBy("id", "desc").limit(1).get())).toBe(variables.maxId);
			});

		});

	}

}
