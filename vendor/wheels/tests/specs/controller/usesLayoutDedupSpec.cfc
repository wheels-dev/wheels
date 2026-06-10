component extends="wheels.WheelsTest" {

	function run() {

		describe("usesLayout() duplicate detection", () => {

			beforeEach(() => {
				params = {controller = "usesLayoutDedupTest", action = "index"}
				_controller = application.wo.controller("usesLayoutDedupTest", params)
				// Layouts are stored on the class level so clear them to keep each test independent.
				ArrayClear(_controller.$getControllerClassData().layouts)
			})

			afterEach(() => {
				ArrayClear(_controller.$getControllerClassData().layouts)
			})

			it("does not crash when two declarations have the same key count but different key sets", () => {
				// Pre-fix this threw a "key doesn't exist" error because equal struct counts were treated as the same shape.
				_controller.usesLayout(template = "myLayout", only = "index")
				_controller.usesLayout(template = "otherLayout", except = "index")

				expect(ArrayLen(_controller.$getControllerClassData().layouts)).toBe(2)
			})

			it("replaces an identical declaration instead of duplicating it", () => {
				_controller.usesLayout(template = "myLayout", only = "index")
				_controller.usesLayout(template = "myLayout", only = "index")

				expect(ArrayLen(_controller.$getControllerClassData().layouts)).toBe(1)
			})

			it("keeps declarations that differ only by a value", () => {
				_controller.usesLayout(template = "myLayout", only = "index")
				_controller.usesLayout(template = "otherLayout", only = "index")

				expect(ArrayLen(_controller.$getControllerClassData().layouts)).toBe(2)
			})
		})
	}
}
