component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that enum scope WHERE clauses", () => {

			beforeEach(() => {
				g.$clearModelInitializationCache()
			})

			afterEach(() => {
				g.$clearModelInitializationCache()
			})

			it("generates correct WHERE for simple string values", () => {
				var m = g.model("post")
				m.enum(property="status", values="draft,published,archived")
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("draft")
				expect(scopes.draft).toHaveKey("where")
				expect(scopes.draft.where).toBe("status = 'draft'")

				expect(scopes).toHaveKey("published")
				expect(scopes.published.where).toBe("status = 'published'")

				expect(scopes).toHaveKey("archived")
				expect(scopes.archived.where).toBe("status = 'archived'")
			})

			it("generates correct WHERE for struct-mapped values", () => {
				var m = g.model("post")
				m.enum(property="priority", values={low: 0, medium: 1, high: 2})
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = '0'")

				expect(scopes).toHaveKey("high")
				expect(scopes.high.where).toBe("priority = '2'")
			})

			it("allows enum values with hyphens spaces and dots", () => {
				var m = g.model("post")
				m.enum(property="status", values={my_val: "some-value", other: "v1.0", spaced: "hello world"})
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("my_val")
				expect(scopes.my_val.where).toBe("status = 'some-value'")

				expect(scopes).toHaveKey("other")
				expect(scopes.other.where).toBe("status = 'v1.0'")

				expect(scopes).toHaveKey("spaced")
				expect(scopes.spaced.where).toBe("status = 'hello world'")
			})

			it("allows numeric enum stored values", () => {
				var m = g.model("post")
				m.enum(property="priority", values={low: 0, medium: 1, high: 2})
				var scopes = m.$classData().scopes

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = '0'")
			})

		})
	}
}
