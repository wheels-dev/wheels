component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that enum scope WHERE clauses", () => {

			it("generates parameterized WHERE for simple string values", () => {
				var m = application.wo.model("author")
				m.enum(property="status", values="draft,published,archived")
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("draft")
				expect(scopes.draft).toHaveKey("where")
				expect(scopes.draft.where).toBe("status = ?")
				expect(scopes.draft).toHaveKey("whereParams")
				expect(scopes.draft.whereParams[1].value).toBe("draft")

				expect(scopes).toHaveKey("published")
				expect(scopes.published.where).toBe("status = ?")
				expect(scopes.published.whereParams[1].value).toBe("published")

				expect(scopes).toHaveKey("archived")
				expect(scopes.archived.where).toBe("status = ?")
				expect(scopes.archived.whereParams[1].value).toBe("archived")
			})

			it("generates parameterized WHERE for struct-mapped values", () => {
				var m = application.wo.model("author")
				m.enum(property="priority", values={low: 0, medium: 1, high: 2})
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = ?")
				expect(scopes.low.whereParams[1].value).toBe("0")

				expect(scopes).toHaveKey("high")
				expect(scopes.high.where).toBe("priority = ?")
				expect(scopes.high.whereParams[1].value).toBe("2")
			})

			it("rejects enum values containing single quotes", () => {
				var m = application.wo.model("author")

				expect(function() {
					m.enum(property="status", values={it_s_fine: "it's fine", normal: "normal"})
				}).toThrow("Wheels.InvalidEnumValue")
			})

			it("rejects enum values containing SQL injection patterns", () => {
				var m = application.wo.model("author")

				expect(function() {
					m.enum(property="status", values={dangerous: "'; DROP TABLE users; --"})
				}).toThrow("Wheels.InvalidEnumValue")
			})

			it("allows enum values with hyphens spaces and dots", () => {
				var m = application.wo.model("author")
				m.enum(property="status", values={my_val: "some-value", other: "v1.0", spaced: "hello world"})
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("my_val")
				expect(scopes.my_val.where).toBe("status = ?")
				expect(scopes.my_val.whereParams[1].value).toBe("some-value")

				expect(scopes).toHaveKey("other")
				expect(scopes.other.where).toBe("status = ?")
				expect(scopes.other.whereParams[1].value).toBe("v1.0")

				expect(scopes).toHaveKey("spaced")
				expect(scopes.spaced.where).toBe("status = ?")
				expect(scopes.spaced.whereParams[1].value).toBe("hello world")
			})

			it("allows numeric enum stored values", () => {
				var m = application.wo.model("author")
				m.enum(property="priority", values={low: 0, medium: 1, high: 2})
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = ?")
				expect(scopes.low.whereParams[1].value).toBe("0")
				expect(scopes.low.whereParams[1].type).toBe("CF_SQL_VARCHAR")
			})

			it("rejects property names with invalid characters", () => {
				var m = application.wo.model("author")

				expect(function() {
					m.enum(property="status; DROP TABLE", values="draft")
				}).toThrow("Wheels.InvalidPropertyName")
			})

			it("rejects property names starting with a number", () => {
				var m = application.wo.model("author")

				expect(function() {
					m.enum(property="1status", values="draft")
				}).toThrow("Wheels.InvalidPropertyName")
			})

			it("allows property names with underscores", () => {
				var m = application.wo.model("author")
				m.enum(property="_my_status", values="draft,published")
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("draft")
				expect(scopes.draft.where).toBe("_my_status = ?")
				expect(scopes.draft.whereParams[1].value).toBe("draft")
			})
		})
	}
}
