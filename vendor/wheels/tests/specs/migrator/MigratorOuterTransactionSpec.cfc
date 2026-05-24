component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		// Separate migrations directory so this spec's synthetic 001_ file
		// doesn't collide with the reconciliation spec's 001/002/003 fixtures.
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations_2789/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_2789/"
		);
	}

	function run() {

		var ctx = {isCockroachDB: CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB"};

		describe("Migrator sets $wheelsTransactionWrapper while up()/down() runs (issue ##2789)", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				} catch (any e) {}
				StructDelete(request, "$issue2789FlagDuringUp");
				StructDelete(request, "$wheelsTransactionWrapper");
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				} catch (any e) {}
				StructDelete(request, "$issue2789FlagDuringUp");
				StructDelete(request, "$wheelsTransactionWrapper");
			});

			it("model.create() inside up() persists after the outer transaction commits", () => {
				if (ctx.isCockroachDB) return;
				migrator.migrateTo("001");
				var found = queryExecute(
					"SELECT id FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				expect(found.recordCount).toBe(1);
			});

			it("sets request.$wheelsTransactionWrapper for the duration of up()", () => {
				if (ctx.isCockroachDB) return;
				migrator.migrateTo("001");
				expect(request.$issue2789FlagDuringUp).toBeTrue();
			});

			it("clears request.$wheelsTransactionWrapper after up() returns", () => {
				if (ctx.isCockroachDB) return;
				migrator.migrateTo("001");
				expect(StructKeyExists(request, "$wheelsTransactionWrapper")).toBeFalse();
			});

			it("clears request.$wheelsTransactionWrapper after down() returns", () => {
				if (ctx.isCockroachDB) return;
				migrator.migrateTo("001");
				migrator.migrateTo("0");
				expect(StructKeyExists(request, "$wheelsTransactionWrapper")).toBeFalse();
			});

		});

	}

}
