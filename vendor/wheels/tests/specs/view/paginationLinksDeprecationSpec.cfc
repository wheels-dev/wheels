component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("paginationLinks deprecation warning (##2714)", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
				g.set(functionName = "paginationLinks", encode = false)
				structDelete(request.wheels, "$paginationLinksDeprecationLogged")
			})

			afterEach(() => {
				g.set(functionName = "paginationLinks", encode = true)
				structDelete(request.wheels, "$paginationLinksDeprecationLogged")
			})

			it("sets a request-scoped guard flag on first call", () => {
				g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				expect(structKeyExists(request.wheels, "$paginationLinksDeprecationLogged")).toBeFalse()
				_controller.paginationLinks()
				expect(structKeyExists(request.wheels, "$paginationLinksDeprecationLogged")).toBeTrue()
				expect(request.wheels.$paginationLinksDeprecationLogged).toBeTrue()
			})

			it("does not re-log when called multiple times in the same request", () => {
				g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
				_controller.paginationLinks()
				request.wheels.$paginationLinksDeprecationLogged = "first"
				_controller.paginationLinks()
				expect(request.wheels.$paginationLinksDeprecationLogged).toBe("first")
			})

		})

	}

}
