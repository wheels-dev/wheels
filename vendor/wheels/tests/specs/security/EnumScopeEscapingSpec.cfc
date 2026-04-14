component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that enum scope WHERE clauses use parameterized queries", () => {

			beforeEach(() => {
				g.$clearModelInitializationCache()
			})

			afterEach(() => {
				g.$clearModelInitializationCache()
			})

			it("generates parameterized WHERE with placeholder for simple string values", () => {
				var m = g.model("author")
				m.enum(property="status", values="draft,published,archived")
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("draft")
				expect(scopes.draft).toHaveKey("where")
				expect(scopes.draft.where).toBe("status = ?")
				expect(scopes.draft).toHaveKey("whereParams")
				expect(scopes.draft.whereParams).toBeArray()
				expect(scopes.draft.whereParams).toHaveLength(1)
				expect(scopes.draft.whereParams[1].value).toBe("draft")
				expect(scopes.draft.whereParams[1].type).toBe("CF_SQL_VARCHAR")

				expect(scopes).toHaveKey("published")
				expect(scopes.published.where).toBe("status = ?")
				expect(scopes.published.whereParams[1].value).toBe("published")

				expect(scopes).toHaveKey("archived")
				expect(scopes.archived.where).toBe("status = ?")
				expect(scopes.archived.whereParams[1].value).toBe("archived")
			})

			it("generates parameterized WHERE for struct-mapped values", () => {
				var m = g.model("author")
				m.enum(property="priority", values={low: 0, medium: 1, high: 2})
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = ?")
				expect(scopes.low.whereParams[1].value).toBe("0")

				expect(scopes).toHaveKey("high")
				expect(scopes.high.where).toBe("priority = ?")
				expect(scopes.high.whereParams[1].value).toBe("2")
			})

			it("allows enum values with hyphens spaces and dots", () => {
				var m = g.model("author")
				m.enum(property="status", values={my_val: "some-value", other: "v1.0", spaced: "hello world"})
				var scopes = m.$classData().scopes

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
				var m = g.model("author")
				m.enum(property="priority", values={low: 0, medium: 1, high: 2})
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = ?")
				expect(scopes.low.whereParams[1].value).toBe("0")
				expect(scopes.low.whereParams[1].type).toBe("CF_SQL_VARCHAR")
			})

			it("resolves whereParams into quoted values during scope merge", () => {
				var m = g.model("author")
				m.enum(property="status", values="draft,published")
				var chain = new wheels.model.query.ScopeChain(
					modelReference = m,
					specs = [m.$classData().scopes["draft"]]
				)
				var merged = chain.$mergeSpecs()

				expect(merged).toHaveKey("where")
				expect(merged.where).toBe("status = 'draft'")
			})

		})
	}
}
