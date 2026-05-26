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

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		// Issue #2811: when migrateIndividual()'s up() throws, the catch block must
		// not fall through to `transaction action="commit"` after the rollback.
		// On Lucee the spurious commit is a silent no-op; on Adobe CF 2023/2025
		// (and potentially BoxLang) it can throw a JDBC "transaction not active"
		// error that masks the real migration failure. This spec asserts the
		// post-fix contract on every engine.
		describe("migrateIndividual() error path (issue ##2811)", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				try {
					queryExecute(
						"DELETE FROM #application.wheels.migratorTableName# WHERE version = '004'",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				} catch (any e) {}
				$cleanSqlDirectory();
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				try {
					queryExecute(
						"DELETE FROM #application.wheels.migratorTableName# WHERE version = '004'",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				} catch (any e) {}
				$cleanSqlDirectory();
			});

			it("returns normally when the migration's up() throws", () => {
				if (_isCockroachDB) return;
				var rv = "";
				var threw = false;
				var thrownMessage = "";
				try {
					rv = migrator.migrateIndividual("004");
				} catch (any e) {
					threw = true;
					thrownMessage = e.message;
				}
				expect(threw).toBeFalse(
					"migrateIndividual() should catch the migration error and return its message, "
					& "not propagate an exception. Got: " & thrownMessage
				);
				expect(rv).toInclude("Error migrating 004");
				expect(rv).toInclude("synthetic failure");
			});

			it("does not record a tracking row when the migration throws", () => {
				if (_isCockroachDB) return;
				migrator.migrateIndividual("004");
				var versions = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '004'",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				expect(versions.recordCount).toBe(
					0,
					"The migration's up() threw, so the catch should have rolled back "
					& "and returned early. No tracking row should exist for version 004."
				);
			});

		});

	}

}
