component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Stress Testing for Race Conditions", () => {

			it("should handle concurrent model access with cacheModelConfig=false", () => {
				application.wheels.cacheModelConfig = false;
				modelName = "TestModels";
				g.model(modelName);

				values = [];
				for (i = 1; i <= 30; i++) {
					arrayAppend(values, "*");
				}

				if (structKeyExists(server, "lucee")) {
					// Parallel map (only Lucee supports this)
					results = values.map((v, i) => {
						try {
							if (randRange(1, 5) == 1) {
								structClear(application.wheels.models);
							}
							obj = g.model(modelName);
							return { success: isObject(obj), error: "" };
						} catch (any e) {
							return { success: false, error: e.message & " " & e.detail };
						}
					}, true, 20);
				} else {
					// Sequential map for Adobe ColdFusion
					results = values.map(function(v, i) {
						try {
							if (randRange(1, 5) == 1) {
								structClear(application.wheels.models);
							}
							obj = g.model(modelName);
							return { success: isObject(obj), error: "" };
						} catch (any e) {
							return { success: false, error: e.message & " " & e.detail };
						}
					});
				}

				errors = results.filter(function(r) {
					return !r.success;
				}).map(function(r, i) {
					return "Thread " & i & ": " & r.error;
				});

				expect(arrayLen(errors)).toBe(0, "No threads should error, but got: #serializeJSON(errors)#");

				application.wheels.cacheModelConfig = true;
			});
		});
	}
}
