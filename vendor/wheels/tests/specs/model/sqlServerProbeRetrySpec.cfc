/**
 * SQL Server's per-datasource probes (compatibility level for STRING_SPLIT, #4103; the driver's date
 * bind types, #4318) keep a successful read for the application's lifetime. A failed read isn't
 * kept: it is tried again once $probeRetrySeconds() have passed, and not before, so a broken probe
 * doesn't run before every long statement. The reads are stubbed, so this runs on every database.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.dataSource = "wheels_probe_retry_" & Replace(CreateUUID(), "-", "", "all");
	}

	function afterAll() {
		forgetProbes();
	}

	function forgetProbes() {
		for (var store in ["sqlServerCompatibilityLevels", "sqlServerDateBindTypes"]) {
			if (StructKeyExists(application.wheels, store)) {
				StructDelete(application.wheels[store], variables.dataSource);
			}
		}
		if (StructKeyExists(application.wheels, "sqlServerProbeFailures")) {
			StructDelete(application.wheels.sqlServerProbeFailures, "compatibilityLevel|" & variables.dataSource);
			StructDelete(application.wheels.sqlServerProbeFailures, "dateBindTypes|" & variables.dataSource);
		}
	}

	// A SQL Server adapter for a datasource no other spec uses, with its probe reads stubbed.
	function stubbedAdapter() {
		var adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel").$init(
			dataSource = variables.dataSource,
			username = "",
			password = ""
		);
		prepareMock(adapter);
		return adapter;
	}

	// Moves a recorded failure `seconds` into the past.
	function ageFailure(required string probe, required numeric seconds) {
		var key = arguments.probe & "|" & variables.dataSource;
		application.wheels.sqlServerProbeFailures[key] = application.wheels.sqlServerProbeFailures[key] - arguments.seconds * 1000;
	}

	function run() {

		describe("SQL Server probes after a failed read", () => {

			beforeEach(() => {
				forgetProbes();
			});

			it("retries the compatibility level only after the back-off, then keeps a good read", () => {
				var adapter = stubbedAdapter();
				adapter.$("$readCompatibilityLevel").$results(0, 150);
				expect(adapter.$supportsStringSplit(variables.dataSource)).toBeFalse();
				expect(adapter.$supportsStringSplit(variables.dataSource)).toBeFalse();
				expect(adapter.$count("$readCompatibilityLevel")).toBe(1, "read again within the back-off");
				expect(StructKeyExists(application.wheels.sqlServerCompatibilityLevels, variables.dataSource)).toBeFalse("a failed read was kept");
				ageFailure("compatibilityLevel", adapter.$probeRetrySeconds() + 1);
				expect(adapter.$supportsStringSplit(variables.dataSource)).toBeTrue();
				expect(adapter.$supportsStringSplit(variables.dataSource)).toBeTrue();
				expect(adapter.$count("$readCompatibilityLevel")).toBe(2, "a good read is kept");
				expect(application.wheels.sqlServerCompatibilityLevels[variables.dataSource]).toBe(150);
				expect(StructKeyExists(application.wheels.sqlServerProbeFailures, "compatibilityLevel|" & variables.dataSource)).toBeFalse();
			});

			it("retries the date bind types only after the back-off, then keeps a good read", () => {
				var adapter = stubbedAdapter();
				adapter.$("$readDateBindTypes").$results({}, {cf_sql_timestamp = "datetime2/7", cf_sql_date = "date/0"});
				expect(StructIsEmpty(adapter.$stringSplitDateCasts(variables.dataSource))).toBeTrue();
				expect(StructIsEmpty(adapter.$stringSplitDateCasts(variables.dataSource))).toBeTrue();
				expect(adapter.$count("$readDateBindTypes")).toBe(1, "read again within the back-off");
				expect(StructKeyExists(application.wheels.sqlServerDateBindTypes, variables.dataSource)).toBeFalse("a failed read was kept");
				ageFailure("dateBindTypes", adapter.$probeRetrySeconds() + 1);
				expect(adapter.$stringSplitDateCasts(variables.dataSource).cf_sql_timestamp).toBe("DATETIME2(7)");
				expect(adapter.$stringSplitDateCasts(variables.dataSource).cf_sql_date).toBe("DATE");
				expect(adapter.$count("$readDateBindTypes")).toBe(2, "a good read is kept");
			});

			it("keeps a level below 130 as a good read, not a failure", () => {
				var adapter = stubbedAdapter();
				adapter.$("$readCompatibilityLevel").$results(120);
				expect(adapter.$supportsStringSplit(variables.dataSource)).toBeFalse();
				expect(adapter.$supportsStringSplit(variables.dataSource)).toBeFalse();
				expect(adapter.$count("$readCompatibilityLevel")).toBe(1);
				expect(application.wheels.sqlServerCompatibilityLevels[variables.dataSource]).toBe(120);
			});

		});

	}

}
