component extends="wheels.WheelsTest" {

	function run() {

		describe("application.wheels.protectedControllerMethods", () => {

			it("is populated at application start", () => {
				expect(Len(application.wheels.protectedControllerMethods)).toBeGT(0)
			})

			it("includes the env() global helper", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "env")).toBeGT(0)
			})

			it("includes the model() global helper", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "model")).toBeGT(0)
			})

			it("includes the redirectTo controller mixin method", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "redirectTo")).toBeGT(0)
			})

			it("includes the linkTo view helper", () => {
				expect(ListFindNoCase(application.wheels.protectedControllerMethods, "linkTo")).toBeGT(0)
			})

			it("does not include $-prefixed internal methods", () => {
				var dollarCount = 0
				for (var item in ListToArray(application.wheels.protectedControllerMethods)) {
					if (Left(item, 1) == "$") {
						dollarCount++
					}
				}
				expect(dollarCount).toBe(0)
			})
		})

		describe("$callAction action-dispatch gate", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = application.wo.controller("test", params)
			})

			it("rejects dispatch to env() with Wheels.ActionNotAllowed", () => {
				expect(function(){
					_controller.$callAction(action = "env")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("rejects dispatch to model() with Wheels.ActionNotAllowed", () => {
				expect(function(){
					_controller.$callAction(action = "model")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("rejects dispatch to redirectTo() with Wheels.ActionNotAllowed", () => {
				expect(function(){
					_controller.$callAction(action = "redirectTo")
				}).toThrow("Wheels.ActionNotAllowed")
			})

			it("rejects dispatch to $-prefixed internal methods", () => {
				expect(function(){
					_controller.$callAction(action = "$callAction")
				}).toThrow("Wheels.ActionNotAllowed")
			})
		})
	}
}
