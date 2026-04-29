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

	}

}
