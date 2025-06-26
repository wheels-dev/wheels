component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Tests that caching", () => {

			it("is hashing arguments to identical result", () => {
				result1 = _method(1, 2, 3, 4, 5, 6, 7, 8, 9)
				result2 = _method(1, 2, 3, 4, 5, 6, 7, 8, 9)

				expect(result1).toBe(result2)

				result1 = _method("per", "was", "here")
				result2 = _method("per", "was", "here")
				
				expect(result1).toBe(result2)
				
				result1 = _method(a = 1, b = 2)
				result2 = _method(a = 1, b = 2)
				
				expect(result1).toBe(result2)

				aStruct = StructNew()
				aStruct.test1 = "a"
				aStruct.test2 = "b"
				anArray = ArrayNew(1)
				anArray[1] = 1
				result1 = _method(a = aStruct, b = anArray)
				result2 = _method(a = aStruct, b = anArray)

				expect(result1).toBe(result2)
			})
		})
	}

	function _method() {
		return application.wo.$hashedKey(arguments)
	}
}