component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that includePartial", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"}
				_controller = g.controller("test", params)
			})

			it("is including partial", () => {
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(partial = "partialTemplate"))
				}

				expect(result).toInclude("partial template content")
			})

			it("is including partial loading data", () => {
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(partial = "partialDataImplicitPrivate"))
				}

				expect(result).toBe("Apple,Banana,Kiwi")
			})

			it("is including partial loading data allowed from explicit public method", () => {
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(partial = "partialDataExplicitPublic", dataFunction = "partialDataExplicitPublic"))
				}

				expect(result).toBe("Apple,Banana,Kiwi")
			})

			it("is including partial loading data allowed from explicit public method with arg", () => {
				savecontent variable="result" {
					WriteOutput(
						_controller.includePartial(
							partial = "partialDataExplicitPublic",
							dataFunction = "partialDataExplicitPublic",
							passThrough = 1
						)
					)
				}

				expect(result).toBe("Apple,Banana,Kiwi,passThroughWorked")
			})

			it("is not allowing partial loading data to be included from implicit public method", () => {
				result = ""
				try {
					savecontent variable="result" {
						WriteOutput(_controller.includePartial(partial = "partialDataImplicitPublic"))
					}
				} catch (any e) {
					result = e
				}

				expect(issimplevalue(result)).toBeFalse()
				expect(result.type).toBe("expression")
			})

			it("is including partial with query", () => {
				usersQuery = g.model("user").findAll(order = "firstName")
				request.partialTests.currentTotal = 0
				request.partialTests.thirdUserName = ""
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(query = usersQuery, partial = "user"))
				}

				expect(request.partialTests.currentTotal).toBe(15)
				expect(request.partialTests.thirdUserName).toBe("Per")
			})

			it("is including partial with special query argument", () => {
				usersQuery = g.model("user").findAll(order = "firstName")
				request.partialTests.currentTotal = 0
				request.partialTests.thirdUserName = ""
				request.partialTests.noQueryArg = true
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(partial = "custom", query = usersQuery))
				}

				expect(request.partialTests.noQueryArg).toBeTrue()
				expect(request.partialTests.currentTotal).toBe(15)
				expect(request.partialTests.thirdUserName).toBe("Per")
			})

			it("is including partial with normal query argument", () => {
				usersQuery = g.model("user").findAll(order = "firstName");
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(partial = "custom", customQuery = usersQuery));
				}

				expect(Trim(result)).toBe("Per")
			})

			it("is including partial with special objects argument", () => {
				usersArray = g.model("user").findAll(order = "firstName", returnAs = "objects")
				request.partialTests.currentTotal = 0
				request.partialTests.thirdUserName = ""
				request.partialTests.thirdObjectExists = false
				request.partialTests.noObjectsArg = true
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(partial = "custom", objects = usersArray))
				}

				expect(request.partialTests.thirdObjectExists).toBeTrue()
				expect(request.partialTests.noObjectsArg).toBeTrue()
				expect(request.partialTests.currentTotal).toBe(15)
				expect(request.partialTests.thirdUserName).toBe("Per")
			})

			it("is including partial with object", () => {
				userObject = g.model("user").findOne(order = "firstName")
				request.wheelsTests.objectTestsPassed = false
				savecontent variable="result" {
					WriteOutput(_controller.includePartial(userObject))
				}

				expect(request.wheelsTests.objectTestsPassed).toBeTrue()
				expect(trim(result)).toBe("Chris")
			})
		})
	}
}