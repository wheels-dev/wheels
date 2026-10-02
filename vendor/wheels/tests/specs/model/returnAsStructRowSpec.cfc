/**
 * returnAs="struct(s)" across the finders (#4003). Since 4.2, findAll(returnAs=
 * "structs") returns the documented array of structs; through 4.1 it was a
 * struct keyed by row number. findOne, findByKey and findEach return rows.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("returnAs struct (##4003)", () => {

			it("findAll returns an array of structs for structs and struct", () => {
				var total = g.model("author").count()
				for (var shape in ["structs", "struct"]) {
					var rows = g.model("author").findAll(returnAs = shape, order = "id")
					expect(IsArray(rows)).toBeTrue("returnAs=#shape# is not an array")
					expect(ArrayLen(rows)).toBe(total)
					expect(rows[1]).toHaveKey("firstName")
				}
			})

			it("findAll(returnAs=structs) serializes to a JSON array", () => {
				var json = SerializeJSON(g.model("author").findAll(returnAs = "structs", maxRows = 2, order = "id"))
				expect(Left(Trim(json), 1)).toBe("[")
			})

			it("findAll(returnAs=array) returns an array of structs", () => {
				var rows = g.model("author").findAll(returnAs = "array", order = "id")
				expect(IsArray(rows)).toBeTrue()
				expect(ArrayLen(rows)).toBe(g.model("author").count())
			})

			it("findOne returns the row struct itself", () => {
				var first = g.model("author").findOne(order = "id", returnAs = "query")
				var row = g.model("author").findOne(order = "id", returnAs = "struct")
				expect(row).toBeStruct()
				expect(row).toHaveKey("id")
				expect(row.id).toBe(first.id)
			})

			it("findByKey returns the row struct itself", () => {
				var first = g.model("author").findOne(order = "id", returnAs = "query")
				var row = g.model("author").findByKey(key = first.id, returnAs = "struct")
				expect(row).toBeStruct()
				expect(row.id).toBe(first.id)
			})

			it("findOne still returns an empty struct when nothing matches", () => {
				var row = g.model("author").findOne(where = "lastName = 'zz-no-such-author'", returnAs = "struct")
				expect(row).toBeStruct()
				expect(StructIsEmpty(row)).toBeTrue()
			})

			it("findEach passes each row to the callback in order", () => {
				var seen = {ids = [], allStructs = true}
				var visit = function(row) {
					ArrayAppend(seen.ids, arguments.row.id)
					if (!IsStruct(arguments.row) || IsObject(arguments.row)) {
						seen.allStructs = false
					}
				}
				g.model("author").findEach(returnAs = "struct", batchSize = 3, callback = visit)
				// ValueList() needs a plain query variable: Adobe will not compile a call expression there.
				var authors = g.model("author").findAll(order = "id", returnAs = "query")
				var expected = ValueList(authors.id)
				expect(ArrayToList(seen.ids)).toBe(expected)
				expect(seen.allStructs).toBeTrue()
			})

		})

	}

}
