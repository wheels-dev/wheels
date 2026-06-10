/**
 * Helper extracted from app-runner.cfm so the test-DB-swap rule is
 * unit-testable without spinning up an HTTP request. app-runner.cfm
 * instantiates this resolver and uses its return value to decide
 * whether to swap application.wheels.dataSourceName for the duration
 * of a test run.
 *
 * Convention: when url.useTestDB=true, swap to "<currentName>_test"
 * if such a datasource is registered. The CLI passes useTestDB=true
 * for app tests by default; users opt out with --no-test-db.
 *
 * See finding #10 in
 * docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
 */
component {

	public string function resolveDataSource(
		required string currentName,
		required struct url
	) {
		var useTestDB = StructKeyExists(arguments.url, "useTestDB")
			&& arguments.url.useTestDB;
		if (!useTestDB) return arguments.currentName;
		return arguments.currentName & "_test";
	}

	// Sets the datasource and clears application.wheels.models so cached model classes re-initialize.
	public void function applyDataSource(
		required struct wheelsScope,
		required string name
	) {
		arguments.wheelsScope.dataSourceName = arguments.name;
		if (StructKeyExists(arguments.wheelsScope, "models")) {
			StructClear(arguments.wheelsScope.models);
		}
	}

}
