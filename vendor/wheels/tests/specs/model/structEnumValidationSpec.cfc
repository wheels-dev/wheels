component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Struct-form enum() validation aligns with scopes and is*() checkers (issue ##3014)", () => {

			beforeEach(() => {
				g.$clearModelInitializationCache()
			})

			afterEach(() => {
				g.$clearModelInitializationCache()
			})

			it("accepts the stored VALUE (not the name) on valid() — the same value scopes filter on", () => {
				var m = g.model("author")
				m.enum(property="lastName", values={low: 0, medium: 1, high: 2})

				var instance = m.new(firstName="Test")
				instance.lastName = 0
				expect(instance.valid()).toBeTrue()

				var errors = instance.errorsOn("lastName")
				expect(ArrayLen(errors)).toBe(0)
			})

			it("rejects the enum NAME string (struct form) — stored value is what matters", () => {
				var m = g.model("author")
				m.enum(property="lastName", values={low: 0, medium: 1, high: 2})

				var instance = m.new(firstName="Test")
				instance.lastName = "low"
				expect(instance.valid()).toBeFalse()
			})

			it("rejects values that are neither names nor stored values", () => {
				var m = g.model("author")
				m.enum(property="lastName", values={low: 0, medium: 1, high: 2})

				var instance = m.new(firstName="Test")
				instance.lastName = "bogus"
				expect(instance.valid()).toBeFalse()
			})

			it("the value that passes validation is the same value is<Name>() returns true for", () => {
				var m = g.model("author")
				m.enum(property="lastName", values={low: 0, medium: 1, high: 2})

				var instance = m.new(firstName="Test")
				instance.lastName = 0

				expect(instance.valid()).toBeTrue()
				expect(instance.isLow()).toBeTrue()
			})

			it("the value that passes validation is the same value the auto-generated scope filters on", () => {
				var m = g.model("author")
				m.enum(property="lastName", values={low: 0, medium: 1, high: 2})
				var scopes = m.$classData().scopes

				expect(scopes.low.whereParams[1].value).toBe("0")

				var instance = m.new(firstName="Test")
				instance.lastName = scopes.low.whereParams[1].value
				expect(instance.valid()).toBeTrue()
			})

			it("list-form enum (names == values) still validates correctly", () => {
				var m = g.model("author")
				m.enum(property="lastName", values="alpha,beta,gamma")

				var instance = m.new(firstName="Test", lastName="alpha")
				expect(instance.valid()).toBeTrue()

				instance.lastName = "delta"
				expect(instance.valid()).toBeFalse()
			})

		})
	}
}
