component extends="wheels.WheelsTest" {

	function run() {

		describe("app-runner test database resolution", () => {

			it("swaps to <currentName>_test when url.useTestDB=true", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
				var fakeUrl = { useTestDB: true };
				expect(resolver.resolveDataSource(currentName = "myapp", url = fakeUrl))
					.toBe("myapp_test");
			});

			it("returns currentName untouched when useTestDB is false", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
				var fakeUrl = { useTestDB: false };
				expect(resolver.resolveDataSource(currentName = "myapp", url = fakeUrl))
					.toBe("myapp");
			});

			it("returns currentName untouched when useTestDB key is missing", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
				expect(resolver.resolveDataSource(currentName = "myapp", url = {}))
					.toBe("myapp");
			});

		});

		describe("app-runner datasource application", () => {

			// Regression: the swap must invalidate cached model classes or dev-DB models keep writing to the dev DB during a test run.
			it("applyDataSource sets the datasource name and clears cached model classes", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
				var fakeWheels = {
					dataSourceName: "myapp",
					models: { post: { dataSource: "myapp" } }
				};
				resolver.applyDataSource(wheelsScope = fakeWheels, name = "myapp_test");
				expect(fakeWheels.dataSourceName).toBe("myapp_test");
				expect(StructCount(fakeWheels.models)).toBe(0);
			});

			it("applyDataSource clears the cache again when restoring the original name", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
				var fakeWheels = {
					dataSourceName: "myapp_test",
					models: { post: { dataSource: "myapp_test" } }
				};
				resolver.applyDataSource(wheelsScope = fakeWheels, name = "myapp");
				expect(fakeWheels.dataSourceName).toBe("myapp");
				expect(StructCount(fakeWheels.models)).toBe(0);
			});

			it("applyDataSource tolerates a wheels scope without a models cache", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDbResolver();
				var fakeWheels = { dataSourceName: "myapp" };
				resolver.applyDataSource(wheelsScope = fakeWheels, name = "myapp_test");
				expect(fakeWheels.dataSourceName).toBe("myapp_test");
				expect(StructKeyExists(fakeWheels, "models")).toBeFalse();
			});

		});

	}

}
