component extends="wheels.WheelsTest" {

	function run() {

		describe("$appliesToAction() shared only/except gating", () => {

			beforeEach(() => {
				params = {controller = "dummy", action = "index"}
				_controller = application.wo.controller("dummy", params)
			})

			it("applies when neither only nor except is provided", () => {
				expect(_controller.$appliesToAction(action = "index")).toBeTrue()
			})

			it("applies only to actions in the only list", () => {
				expect(_controller.$appliesToAction(action = "index", only = "index,show")).toBeTrue()
				expect(_controller.$appliesToAction(action = "edit", only = "index,show")).toBeFalse()
			})

			it("applies to all actions not in the except list", () => {
				expect(_controller.$appliesToAction(action = "edit", except = "index")).toBeTrue()
				expect(_controller.$appliesToAction(action = "index", except = "index")).toBeFalse()
			})

			it("ORs the conditions when both lists are provided", () => {
				// Matching `only` applies even when the action is also in `except`.
				expect(_controller.$appliesToAction(action = "index", only = "index", except = "index")).toBeTrue()
				// Being absent from `except` applies even when the action is missing from `only`.
				expect(_controller.$appliesToAction(action = "edit", only = "index", except = "show")).toBeTrue()
				// In `except` and not in `only` does not apply.
				expect(_controller.$appliesToAction(action = "show", only = "index", except = "show")).toBeFalse()
			})
		})
	}
}
