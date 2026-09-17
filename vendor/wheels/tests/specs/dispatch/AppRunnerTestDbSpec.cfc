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

		describe("app-runner test-db swap serialization (issue ##3427)", () => {

			it("app-runner.cfm wraps the datasource swap in an exclusive named lock", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var fileLines = ListToArray(source, Chr(10), true);
				var foundLock = false;
				var foundGuard = false;
				for (var rawLine in fileLines) {
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (
						REFindNoCase("(^|[\s;{}])lock\s+[^{]*name\s*=", trimmed)
						&& FindNoCase("wheelsTestRunner_", trimmed)
						&& REFindNoCase("type\s*=\s*[""']exclusive[""']", trimmed)
						&& REFindNoCase("throwontimeout", trimmed)
					) {
						foundLock = true;
					}
					if (FindNoCase("StructKeyExists(application, ""$$$appTestOriginalDataSource"")", trimmed)) {
						foundGuard = true;
					}
				}
				expect(foundLock).toBeTrue(
					"app-runner.cfm must wrap the test-db swap window in an exclusive named lock ('wheelsTestRunner_...', throwOnTimeout) — issue ##3427"
				);
				expect(foundGuard).toBeTrue(
					"app-runner.cfm must detect an in-progress swap via StructKeyExists(application, '$$$appTestOriginalDataSource') so re-entrant requests skip the swap and the shared lock"
				);
			});

			it("app-runner.cfm restores the datasource and clears the marker in a finally block", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				expect(Find("finally", source) > 0).toBeTrue(
					"app-runner.cfm must restore the datasource in a finally block so an erroring run can no longer leave the test datasource live"
				);
				expect(Find("structDelete(application, ""$$$appTestOriginalDataSource"")", source) > 0).toBeTrue(
					"app-runner.cfm must clear the swap marker after restoring"
				);
			});

		});

	}

}
