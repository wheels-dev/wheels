component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Stress Testing for Race Conditions", () => {

			it("should handle concurrent model access with cacheModelConfig=false", () => {
				application.wheels.cacheModelConfig = false
				modelName = "TestModels"
				application.wo.model(modelName)

				values = []
				for (i = 1; i <= 30; i++) {
					arrayAppend(values, "*")
				}

				results = values.map((v, i) => {
					try {
						if (randRange(1, 5) == 1) {
							structClear(application.wheels.models)
						}
						obj = application.wo.model(modelName)
						return { success: isObject(obj), error: "" }
					} catch (any e) {
						return { success: false, error: e.message & " " & e.detail }
					}
				}, true, 20)

				errors = results.filter(function(r) {
					return !r.success
				}).map(function(r, i) {
					return "Thread " & i & ": " & r.error
				})

				expect(arrayLen(errors)).toBe(0, "No threads should error, but got: #serializeJSON(errors)#")
				application.wheels.cacheModelConfig = true
			})
		})
	}
}
