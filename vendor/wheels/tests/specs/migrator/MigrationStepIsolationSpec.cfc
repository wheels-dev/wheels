/**
 * A migration step runs in a transaction. On CockroachDB a schema change after any other
 * statement in that transaction needs serializable isolation, and Lucee leaves a pooled
 * connection at read committed once a transaction on it has ended, so the migrator asks for
 * serializable there. This runs a step that reads before its DDL, after other transactions on
 * the same connection pool, on every database.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.version = "20991231001000";
		variables.migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator-step-isolation/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator-step-isolation/sql/"
		);
	}

	function afterAll() {
		try {
			variables.migrator.migrateTo("0");
		} catch (any e) {
		}
		try {
			queryExecute(
				"DELETE FROM #application.wheels.migratorTableName# WHERE version = :version",
				{version = {value = variables.version, cfsqltype = "cf_sql_varchar"}},
				{datasource = application.wheels.dataSourceName}
			);
		} catch (any e) {
		}
	}

	function run() {

		describe("a migration step's transaction", function() {

			it("runs a step that reads before it changes the schema, after other transactions on the connection", function() {
				for (var i = 1; i <= 2; i++) {
					transaction action="begin" {
						queryExecute("SELECT COUNT(*) AS cnt FROM #application.wheels.migratorTableName#", {}, {datasource = application.wheels.dataSourceName});
					}
				}
				var schema = new wheels.JobSchema();
				var output = variables.migrator.migrateTo(variables.version);
				expect(schema.hasTable("migrator_isolation_items")).toBeTrue(output);
				output = variables.migrator.migrateTo("0");
				expect(schema.hasTable("migrator_isolation_items")).toBeFalse(output);
			});

		});
	}

}
