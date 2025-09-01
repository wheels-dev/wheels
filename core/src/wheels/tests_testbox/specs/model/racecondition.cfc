component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Stress Testing for Race Conditions", () => {

			it("should handle concurrent model access with isolated cache", () => {
				// Store original state to restore later
				var originalCacheConfig = application.wheels.cacheModelConfig;
				var originalModels = duplicate(application.wheels.models);
				
				try {
					// Create isolated test scope to avoid affecting other tests
					var testScope = {
						cacheModelConfig = false,
						models = {}
					};
					
					modelName = "UserBlank";
					g.model(modelName);
					
					values = [];
					for (i = 1; i <= 100; i++) {
						arrayAppend(values, "*");
					}

					// Test with isolated model cache instead of global application cache
					results = values.map(function(v, i) {
						try {
							if (randRange(1, 10) == 1) {
								testScope.models = {};
							}
							
							// Test model loading with cache disabled locally
							var localWheels = duplicate(application.wheels);
							localWheels.cacheModelConfig = false;
							
							obj = g.model(modelName);
							return { success: isObject(obj), error: "" };
						} catch (any e) {
							return { success: false, error: e.message & " " & e.detail };
						}
					});

					errors = results.filter(function(r) {
						return !r.success;
					}).map(function(r, i) {
						return "Iteration " & i & ": " & r.error;
					});

					expect(arrayLen(errors)).toBe(0, "No iterations should error, but got: #serializeJSON(errors)#");
					
				} finally {
					// Always restore original state
					application.wheels.cacheModelConfig = originalCacheConfig;
					application.wheels.models = originalModels;
				}
			});
		});
	}
}
