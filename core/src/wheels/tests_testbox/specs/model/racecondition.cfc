component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Stress Testing for Race Conditions", () => {

			it("should handle concurrent model access with cache manipulation", () => {
				// Store original state to restore later
				var originalCacheConfig = application.wheels.cacheModelConfig;
				var originalModelKeys = structKeyList(application.wheels.models);
				
				try {
					modelName = "UserBlank";
					g.model(modelName);
					
					values = [];
					for (i = 1; i <= 100; i++) {
						arrayAppend(values, "*");
					}

					// Test concurrent model access with cache manipulation
					results = values.map(function(v, i) {
						try {
							if (randRange(1, 10) == 1) {
								application.wheels.cacheModelConfig = false;
								if (structKeyExists(application.wheels.models, modelName)) {
									structDelete(application.wheels.models, modelName);
								}
							}
							
							obj = g.model(modelName);
							
							// Reset cache config for next iteration
							application.wheels.cacheModelConfig = originalCacheConfig;
							
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
					g.model(modelName);
				}
			});
		});
	}
}
