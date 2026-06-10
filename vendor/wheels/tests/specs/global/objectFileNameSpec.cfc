component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $objectFileName", () => {

			it("returns the file name in its proper case for an existing model", () => {
				result = g.$objectFileName(name = "author", objectPath = application.wheels.modelPath, type = "model")

				expect(Compare(result, "Author")).toBe(0)
			})

			it("returns the capitalized type when no file exists", () => {
				result = g.$objectFileName(
					name = "thisModelDefinitelyDoesNotExist999",
					objectPath = application.wheels.modelPath,
					type = "model"
				)

				expect(result).toBe("Model")
			})

			it("memoizes file-existence checks in struct-backed caches", () => {
				g.$objectFileName(name = "author", objectPath = application.wheels.modelPath, type = "model")
				g.$objectFileName(
					name = "thisModelDefinitelyDoesNotExist999",
					objectPath = application.wheels.modelPath,
					type = "model"
				)

				expect(IsStruct(application.wheels.existingObjectFiles)).toBeTrue()
				expect(IsStruct(application.wheels.nonExistingObjectFiles)).toBeTrue()
				if (application.wheels.cacheFileChecking) {
					expect(
						StructKeyExists(application.wheels.existingObjectFiles, application.wheels.modelPath & "/author")
					).toBeTrue()
					expect(
						StructKeyExists(
							application.wheels.nonExistingObjectFiles,
							application.wheels.modelPath & "/thisModelDefinitelyDoesNotExist999"
						)
					).toBeTrue()
				}
			})
		})
	}
}
