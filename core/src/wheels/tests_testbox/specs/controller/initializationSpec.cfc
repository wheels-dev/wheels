component extends="wheels.Testbox" {

	 function run() {

	 	describe("Tests that general", () => {

	 		afterEach(() => {
	 			StructDelete(variables, "c", false)
	 		})

	 		it("is creating controller when file exists", () => {
	 			c = application.wo.controller(name = "test", params = {controller = "Test", action = "test"})
	 			expect(c).toBeInstanceOf("Test")

				name = c.$getControllerClassData().name
				expect(name).toBe("Test")
	 		})

	 		it("is initializing with nested controller", () => {
	 			c = application.wo.controller(name = "admin.Admin", params = {controller = "admin.Admin", action = "test"})
	 			expect(c).toBeInstanceOf("admin")

				name = c.$getControllerClassData().name
				expect(name).toBe("admin.Admin")
	 		})

	 		it("is creating controller when no file exists", () => {
	 			c = application.wo.controller(name = "Admin", params = {controller = "Admin", action = "test"})
	 			expect(c).toBeInstanceOf("Controller")

				name = c.$getControllerClassData().name
				expect(name).toBe("Admin")
	 		})

	 		it("is creating controller when no nested file exists", () => {
	 			c = application.wo.controller(name = "admin.nothing.Admin", params = {controller = "admin.nothing.Admin", action = "test"})
	 			expect(c).toBeInstanceOf("Controller")

				name = c.$getControllerClassData().name
				expect(name).toBe("admin.nothing.Admin")
	 		})
	 	})
	 }
}