component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that ScopeChain resolves whereParams placeholders positionally", () => {

			it("does not let a substituted value containing a question mark absorb later placeholders", () => {
				var m = g.model("author")
				var spec = {
					where = "firstName = ? AND lastName = ?",
					whereParams = [
						{value = "what?now", type = "CF_SQL_VARCHAR"},
						{value = "second", type = "CF_SQL_VARCHAR"}
					]
				}
				var chain = new wheels.model.query.ScopeChain(modelReference = m, specs = [spec])
				var merged = chain.$mergeSpecs()

				expect(merged.where).toBe("firstName = 'what?now' AND lastName = 'second'")
			})

			it("resolves multiple plain values in order", () => {
				var m = g.model("author")
				var spec = {
					where = "firstName = ? AND lastName = ?",
					whereParams = [
						{value = "first", type = "CF_SQL_VARCHAR"},
						{value = "second", type = "CF_SQL_VARCHAR"}
					]
				}
				var chain = new wheels.model.query.ScopeChain(modelReference = m, specs = [spec])
				var merged = chain.$mergeSpecs()

				expect(merged.where).toBe("firstName = 'first' AND lastName = 'second'")
			})

			it("leaves extra placeholders untouched when there are fewer params than placeholders", () => {
				var m = g.model("author")
				var spec = {
					where = "firstName = ? AND lastName = ?",
					whereParams = [
						{value = "only", type = "CF_SQL_VARCHAR"}
					]
				}
				var chain = new wheels.model.query.ScopeChain(modelReference = m, specs = [spec])
				var merged = chain.$mergeSpecs()

				expect(merged.where).toBe("firstName = 'only' AND lastName = ?")
			})

			it("still escapes single quotes in substituted values", () => {
				var m = g.model("author")
				var spec = {
					where = "firstName = ?",
					whereParams = [
						{value = "O'Hara", type = "CF_SQL_VARCHAR"}
					]
				}
				var chain = new wheels.model.query.ScopeChain(modelReference = m, specs = [spec])
				var merged = chain.$mergeSpecs()

				expect(merged.where).toBe("firstName = 'O''Hara'")
			})

		})
	}
}
