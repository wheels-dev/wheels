component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Enum scope SQL parameterization security", () => {

			beforeEach(() => {
				g.$clearModelInitializationCache()
			})

			afterEach(() => {
				g.$clearModelInitializationCache()
			})

			it("stores whereParams with type metadata instead of interpolated values", () => {
				var m = g.model("author")
				m.enum(property="status", values="draft,published")
				var scopes = m.$classData().scopes

				expect(scopes.draft.where).toBe("status = ?")
				expect(scopes.draft.whereParams).toBeArray()
				expect(scopes.draft.whereParams[1]).toHaveKey("value")
				expect(scopes.draft.whereParams[1]).toHaveKey("type")
				expect(scopes.draft.whereParams[1].type).toBe("CF_SQL_VARCHAR")
			})

			it("rejects enum values containing SQL injection characters", () => {
				var m = g.model("author")

				expect(function() {
					m.enum(property="status", values={bad: "'; DROP TABLE users; --"})
				}).toThrow("Wheels.InvalidEnumValue")
			})

			it("rejects enum property names with SQL injection patterns", () => {
				var m = g.model("author")

				expect(function() {
					m.enum(property="status; DROP TABLE", values="draft")
				}).toThrow("Wheels.InvalidPropertyName")
			})

			it("scope merge resolves whereParams into quoted values for downstream parameterization", () => {
				var m = g.model("author")
				m.enum(property="status", values="active,inactive")
				var chain = new wheels.model.query.ScopeChain(
					modelReference = m,
					specs = [m.$classData().scopes["active"]]
				)
				var merged = chain.$mergeSpecs()

				// The merged where should have the value quoted for the RESQLWhere regex to extract
				expect(merged.where).toBe("status = 'active'")
			})

			it("scope merge resolves multiple chained enum scopes correctly", () => {
				var m = g.model("author")
				m.enum(property="status", values="draft,published")
				// Manually define a second parameterized scope for testing
				m.scope(name="recent", where="createdAt > '2024-01-01'")
				var specs = [
					m.$classData().scopes["draft"],
					m.$classData().scopes["recent"]
				]
				var chain = new wheels.model.query.ScopeChain(
					modelReference = m,
					specs = specs
				)
				var merged = chain.$mergeSpecs()

				expect(merged.where).toInclude("status = 'draft'")
				expect(merged.where).toInclude("AND")
				expect(merged.where).toInclude("createdAt > '2024-01-01'")
			})

			it("escapes quotes in scope handler arguments without rewriting keywords", () => {
				var m = g.model("author")
				var result = m.$sanitizeScopeHandlerArgs({"1": "admin' UNION SELECT password FROM users --"})

				expect(result["1"]).toBe("admin'' UNION SELECT password FROM users --")
			})

			it("leaves keyword-only scope handler args unchanged (no quotes to escape)", () => {
				var m = g.model("author")
				var result = m.$sanitizeScopeHandlerArgs({"1": "1 OR SLEEP(5)"})

				expect(result["1"]).toBe("1 OR SLEEP(5)")
			})

		})
	}

}
