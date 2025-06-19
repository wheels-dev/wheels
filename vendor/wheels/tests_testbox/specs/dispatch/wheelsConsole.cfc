component extends="testbox.system.BaseSpec" {
	
	function run() {

		describe("Tests that wheels console request", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
				_originalEnablePublicComponent = application.wheels.enablePublicComponent
				application.wheels.enablePublicComponent = true
			})

			afterEach(() => {
				application.wheels.enablePublicComponent = _originalEnablePublicComponent
			})

			it("handles wheels console route", () => {
				args = {}
				args.pathinfo = "/wheels/console"
				args.urlScope = {}
				args.formScope = {}
				
				// Test that the request doesn't throw an error
				try {
					result = dispatch.$request(argumentCollection = args)
					// If we get here without error, the test passes
					expect(true).toBeTrue()
				} catch (any e) {
					// If an error occurs, fail the test with the error message
					expect(e.message).toBe("No error should occur")
				}
			})

			it("handles wheels console with command parameter", () => {
				args = {}
				args.pathinfo = "/wheels/console"
				args.urlScope = {command = "test"}
				args.formScope = {}
				
				try {
					result = dispatch.$request(argumentCollection = args)
					// The console should return JSON for test command
					expect(isJSON(result)).toBeTrue()
					if (isJSON(result)) {
						data = deserializeJSON(result)
						expect(data.success).toBeTrue()
						expect(data.command).toBe("test")
					}
				} catch (any e) {
					expect(e.message).toBe("No error should occur")
				}
			})

			it("handles disabled public component", () => {
				application.wheels.enablePublicComponent = false
				
				args = {}
				args.pathinfo = "/wheels/console"
				args.urlScope = {}
				args.formScope = {}
				
				// This should abort, which throws an error in the test
				expect(() => {
					dispatch.$request(argumentCollection = args)
				}).toThrow()
			})

		})
	}
}