component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo

		// Regression for issue #3325 (from discussion #3323).
		//
		// The `super<name>` convention was implemented asymmetrically. `Model.cfc`'s
		// $integrateFunctions() registered the framework original as `super<name>` whenever the
		// mixin's name already existed on the target — i.e. whenever the app had overridden it.
		// `Controller.cfc`'s did not: it only registered `super<name>` for names a registered
		// plugin/package mixin overrode. So an app that overrode a controller or view helper,
		// exactly as the "Overriding Core Methods" guide documents, got nothing — and calling
		// `superLinkTo()` was a 500.
		describe("Tests that the super<name> override convention", () => {

			it("registers super<name> for an app-level controller/view helper override", () => {
				c = g.controller(name = "superOverride")

				expect(StructKeyExists(c, "superLinkTo")).toBeTrue()
			})

			it("lets the override delegate to the framework original", () => {
				c = g.controller(name = "superOverride")

				// the fixture returns "wrapped:" & superLinkTo(...), so a real anchor
				// coming back proves the original ran rather than recursing into the override
				result = c.linkTo(text = "Home", route = "root")

				expect(result).toStartWith("wrapped:")
				expect(result).toInclude("<a")
				expect(result).toInclude("Home")
				expect(result).notToInclude("wrapped:wrapped:")
			})

			it("registers super<name> for a model override, unchanged", () => {
				// the model side already behaved this way; pinned so the parity cannot
				// regress from either direction
				m = g.model("superOverride")

				expect(StructKeyExists(m, "superColumnNames")).toBeTrue()
				expect(m.columnNames()).toStartWith("wrapped:")
			})

			it("registers super<name> on model instances built via the fast path", () => {
				// #3515: new()/create()/finder rows are built by
				// $createObjectFromRoot's CreateObject + $initModelObject fast path,
				// which never calls init() — the aliases must register here too.
				m = g.model("superOverride").new()

				expect(StructKeyExists(m, "superColumnNames")).toBeTrue()
				expect(m.columnNames()).toStartWith("wrapped:")
			})

			it("lets a delete() override delegate to the framework original via super.delete()", () => {
				// #3519: the model-side variables.super<name> alias is gone in
				// 4.1.0; the sanctioned delegation path is the parent-method call
				// super.delete(). The fixture records the invocation so the spec
				// proves the override actually ran (not just that a delete happened).
				transaction {
					post = g.model("superOverrideDelete").create(
						title = "super-delete-test",
						body = "body"
					)

					rv = post.delete()

					expect(post.wasSuperDeleteInvoked()).toBeTrue()
					expect(rv).toBeTrue()

					transaction action = "rollback";
				}
			})

			it("adds no super<name> keys to a controller that overrides nothing", () => {
				// the else branch fires only on a genuine override, so the common case pays
				// nothing — this runs on every request
				c = g.controller(name = "test")
				supers = []
				for (key in StructKeyArray(c)) {
					if (Left(key, 5) == "super") {
						ArrayAppend(supers, key)
					}
				}

				expect(ArrayLen(supers)).toBe(0)
			})
		})
	}

}
