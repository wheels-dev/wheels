/**
 * Regression for #4640: $queryRowToStruct appends query columns that are not model
 * properties (custom select aliases, join columns, driver metadata) and must apply the
 * same key-casing rule the property keys follow — normalized when
 * resetPropertiesStructKeyCase is on, raw when it is off.
 *
 * QueryNew() is used so the reported column casing is explicit and engine-neutral.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$queryRowToStruct extra-column key casing (##4640)", () => {

			beforeEach(() => {
				variables.model = application.wo.model("author")
				variables.saved = application.wo.get("resetPropertiesStructKeyCase")
			})

			afterEach(() => {
				application.wo.$set(resetPropertiesStructKeyCase = variables.saved)
			})

			it("lowercases extra query columns when resetPropertiesStructKeyCase is on", () => {
				var query = QueryNew("id,FIRSTNAME,SGP_ID", "integer,varchar,varchar", [[1, "Per", "abc"]])
				var row = variables.model.$queryRowToStruct(properties = query, row = 1)
				var keys = StructKeyList(row)

				expect(ListFind(keys, "sgp_id")).toBeGT(0, "extra column should be lowercased, got [#keys#]")
				expect(ListFind(keys, "SGP_ID")).toBe(0, "raw extra-column casing should be gone, got [#keys#]")
				// Find() is case-sensitive; toInclude() is not, so it cannot prove key casing.
				var json = SerializeJSON(row)
				expect(Find('"sgp_id"', json)).toBeGT(0, "serialized JSON should carry the lowercased key, got [#json#]")
				expect(Find('"SGP_ID"', json)).toBe(0, "serialized JSON should not carry the raw key, got [#json#]")
				// property-backed keys are untouched by the extra-column rule
				expect(row["FIRSTNAME"]).toBe("Per")
			})

			it("preserves raw extra-column casing when resetPropertiesStructKeyCase is off", () => {
				application.wo.$set(resetPropertiesStructKeyCase = false)
				var query = QueryNew("id,FIRSTNAME,SGP_ID", "integer,varchar,varchar", [[1, "Per", "abc"]])
				var row = variables.model.$queryRowToStruct(properties = query, row = 1)
				var keys = StructKeyList(row)

				expect(ListFind(keys, "SGP_ID")).toBeGT(0, "raw extra-column casing should be preserved, got [#keys#]")
				expect(ListFind(keys, "sgp_id")).toBe(0)
				var json = SerializeJSON(row)
				expect(Find('"SGP_ID"', json)).toBeGT(0, "serialized JSON should keep the raw key, got [#json#]")
				expect(Find('"sgp_id"', json)).toBe(0)
			})

			it("does not add an extra key when a property shares the column's name ignoring case", () => {
				var query = QueryNew("id,FIRSTNAME", "integer,varchar", [[1, "Per"]])
				var row = variables.model.$queryRowToStruct(properties = query, row = 1)

				// COUNT case-insensitively: firstName/firstname/FIRSTNAME must be a single key.
				expect(ListValueCountNoCase(StructKeyList(row), "firstname")).toBe(1)
				expect(row["firstname"]).toBe("Per")
			})

			it("applies the same casing rule on the joined-model (joinAlias) path", () => {
				var query = QueryNew(
					"authorid,authorFIRSTNAME,authorLASTNAME,AUTHOR_SGP_ID",
					"integer,varchar,varchar,varchar",
					[[1, "Per", "Djurner", "abc"]]
				)
				var row = variables.model.$queryRowToStruct(properties = query, row = 1, base = false, joinAlias = "author")
				var keys = StructKeyList(row)

				// property matched through the join prefix keeps its canonical name
				expect(row["lastname"]).toBe("Djurner")
				// extra columns are normalized the same way as on the base path
				expect(ListFind(keys, "author_sgp_id")).toBeGT(0, "extra joined column should be lowercased, got [#keys#]")
				expect(ListFind(keys, "AUTHOR_SGP_ID")).toBe(0, "raw joined-column casing should be gone, got [#keys#]")
			})

		})

	}

}
