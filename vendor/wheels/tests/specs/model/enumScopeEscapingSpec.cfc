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
				var scopes = m.scopeInfo()

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
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("low")
				expect(scopes.low.where).toBe("priority = '0'")

				expect(scopes).toHaveKey("high")
				expect(scopes.high.where).toBe("priority = '2'")
			})

			it("escapes single quotes in enum stored values", () => {
				var m = g.model("post")
				m.enum(property="status", values={it_s_fine: "it's fine", normal: "normal"})
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("it_s_fine")
				expect(scopes.it_s_fine.where).toBe("status = 'it''s fine'")

				expect(scopes).toHaveKey("normal")
				expect(scopes.normal.where).toBe("status = 'normal'")
			})

			it("escapes multiple single quotes in enum stored values", () => {
				var m = g.model("post")
				m.enum(property="status", values={tricky: "it''s a ''test''"})
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("tricky")
				expect(scopes.tricky.where).toBe("status = 'it''''s a ''''test'''''")
			})

			it("handles enum values containing SQL keywords safely", () => {
				var m = g.model("post")
				m.enum(property="status", values={dangerous: "'; DROP TABLE users; --"})
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("dangerous")
				expect(scopes.dangerous.where).toBe("status = '''; DROP TABLE users; --'")
			})

			it("rejects property names with invalid characters", () => {
				var m = g.model("post")

				expect(function() {
					m.enum(property="status; DROP TABLE", values="draft")
				}).toThrow("Wheels.InvalidPropertyName")
			})

			it("rejects property names starting with a number", () => {
				var m = g.model("post")

				expect(function() {
					m.enum(property="1status", values="draft")
				}).toThrow("Wheels.InvalidPropertyName")
			})

			it("allows property names with underscores", () => {
				var m = g.model("post")
				m.enum(property="_my_status", values="draft,published")
				var scopes = m.scopeInfo()

				expect(scopes).toHaveKey("draft")
				expect(scopes.draft.where).toBe("_my_status = 'draft'")
			})
		})
	}
}
