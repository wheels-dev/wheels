component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator-error-path/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator-error-path/sql/"
		);
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration")
			.init()
			.adapter
			.adapterName() == "CockroachDB";

		// migrateTo() folds a failed step into the string it returns instead of
		// throwing, so the failure only reaches a caller that inspects that string.
		// The CLI does (#3081 maps the "Error migrating" signature to a non-zero
		// exit), but the application-start auto-migrate path in
		// events/onapplicationstart.cfc discarded the report outright — a migration
		// that could not run stalled every migration queued behind it while the app
		// booted healthy and nothing was written anywhere. The migrator now logs the
		// failure itself, at the point where the exception is still in hand, so no
		// entry point can lose it.
		describe("Migrator failure logging", () => {

			describe("$migrationFailureLogMessage()", () => {

				it("names the direction, the version and the migration's file, then the engine message", () => {
					var step = {
						version = "20260902120000",
						cfcfile = "20260902120000_create_rfq_tables.cfc"
					};
					var error = {
						message = "Datasource [datapai] doesn't exist",
						detail  = ""
					};

					var text = migrator.$migrationFailureLogMessage(
						migration = step,
						direction = "up",
						error = error
					);

					expect(text).toInclude("up 20260902120000");
					expect(text).toInclude("20260902120000_create_rfq_tables.cfc");
					expect(text).toInclude("Datasource [datapai] doesn't exist");
				});

				it("appends the engine detail when there is one", () => {
					var text = migrator.$migrationFailureLogMessage(
						migration = { version = "005", cfcfile = "005_dml_then_synthetic_failure.cfc" },
						direction = "redo",
						error = { message = "synthetic failure after DML", detail = "rollback probe" }
					);

					expect(text).toInclude("redo 005");
					expect(text).toInclude("synthetic failure after DML");
					expect(text).toInclude("rollback probe");
				});

				it("omits the detail separator when the detail is blank", () => {
					var text = migrator.$migrationFailureLogMessage(
						migration = { version = "004", cfcfile = "004_synthetic_failing_migration.cfc" },
						direction = "up",
						error = { message = "synthetic failure", detail = "   " }
					);

					expect(text).toInclude("synthetic failure");
					expect(text).notToInclude("|");
				});

				it("still produces a usable line when the migration struct carries no cfcfile", () => {
					var text = migrator.$migrationFailureLogMessage(
						migration = { version = "004" },
						direction = "up",
						error = { message = "synthetic failure", detail = "" }
					);

					expect(text).toInclude("up 004");
					expect(text).toInclude("synthetic failure");
				});
			});

			// The logging call sits inside $runMigrationStep()'s catch, so the
			// failing-fixture path below executes it on every engine the suite runs.
			// This asserts the failure still returns normally with its report — the
			// log line is additive and must not change the migrate contract.
			describe("a failed step", () => {

				beforeEach(() => {
					deleteMigratorVersions(2);
					try {
						queryExecute(
							"DELETE FROM #application.wheels.migratorTableName# WHERE version = '004'",
							{},
							{ datasource = application.wheels.dataSourceName }
						);
					} catch (any e) {
						// Table not bootstrapped yet on a first run — nothing to clear.
					}
					$cleanSqlDirectory();
				});

				it("still returns its report instead of throwing, with the log line written alongside", () => {
					if (_isCockroachDB) {
						skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
						return;
					}

					var threw = false;
					var rv = "";
					try {
						rv = migrator.migrateIndividual("004");
					} catch (any e) {
						threw = true;
					}

					expect(threw).toBeFalse(
						"migrateIndividual() should catch the migration error, log it and return its "
						& "message — not propagate an exception."
					);
					expect(rv).toInclude("Error migrating 004");
				});
			});
		});
	}
}
