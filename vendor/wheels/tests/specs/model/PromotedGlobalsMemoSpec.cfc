/**
 * Global's pseudo-constructor promotes include-injected functions from `variables`
 * to `this`, memoising the keys to promote. The memo uses one constant key,
 * "wheels.Global" (#4174): inside the pseudo-constructor GetMetadata(this) named
 * `wheels.Global` for every subclass anyway, so it was always a single entry.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Promoted globals memo (##4174)", () => {

			it("keeps one memo entry, under wheels.Global, for models and controllers", () => {
				var appScope = application[StructKeyExists(application, "$wheels") ? "$wheels" : "wheels"]
				var built = {
					model = g.model("author").new(firstName = "Memo4174"),
					otherModel = g.model("post").new(title = "Memo4174"),
					controller = g.controller(name = "test", params = {controller = "test", action = "index"})
				}
				expect(StructKeyExists(appScope, "promotedGlobalKeys")).toBeTrue()
				expect(StructKeyList(appScope.promotedGlobalKeys)).toBe("wheels.Global")
			})

			it("gives every instance each memoised function on `this`", () => {
				var appScope = application[StructKeyExists(application, "$wheels") ? "$wheels" : "wheels"]
				var model = g.model("author").new(firstName = "Memo4174")
				var controller = g.controller(name = "test", params = {controller = "test", action = "index"})
				var keys = appScope.promotedGlobalKeys["wheels.Global"]
				for (var key in keys) {
					expect(StructKeyExists(model, key)).toBeTrue("model is missing " & key)
					expect(StructKeyExists(controller, key)).toBeTrue("controller is missing " & key)
				}
			})

		})

	}

}
