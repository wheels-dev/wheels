/**
 * db status / db version --detailed show when each migration was applied (4407): the
 * migrator reads applied_at for the applied versions, the status formatter carries it,
 * and the CLI bridge passes the migrator's values to the formatter.
 */
component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("applied-at in migration status (4407)", () => {

			it("the status formatter carries each applied version's applied-at", () => {
				var publicCfc = CreateObject("component", "wheels.Public").$init();
				var rv = publicCfc.$cliFormatMigrationStatus(
					migrations = [
						{version = "001", name = "first", status = "migrated"},
						{version = "002", name = "second", status = "pending"}
					],
					appliedAt = {"001" = "2026-10-05 12:46:37"}
				);
				expect(rv.migrations[1].appliedAt).toBe("2026-10-05 12:46:37");
				expect(rv.migrations[2].appliedAt).toBe("");
			});

			it("the CLI bridge passes the migrator's applied-at values to the formatter", () => {
				var seen = {appliedAt = "not passed"};
				var fakeHost = {
					$cliFormatMigrationStatus = function(migrations, appliedAt = "not passed") {
						seen.appliedAt = arguments.appliedAt;
						return {migrations = arguments.migrations, summary = {total = 0, applied = 0, pending = 0}};
					}
				};
				var fakeMigrator = {$appliedAtByVersion = () => {return {"001" = "2026-10-05 12:46:37"};}};
				var bridge = new wheels.public.CliBridge();
				bridge.dispatch(
					command = "dbStatus",
					context = {host = fakeHost, migrator = fakeMigrator, migrations = []},
					params = {}
				);
				expect(IsStruct(seen.appliedAt)).toBeTrue();
				expect(seen.appliedAt["001"]).toBe("2026-10-05 12:46:37");
			});

			describe("the migrator's applied-at values", () => {

				beforeEach(() => {
					for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
						try { migration.dropTable(local.table); } catch (any e) {}
					}
					StructDelete(application.wheels, "$trackingColumnsEnsured");
					StructDelete(application.wheels, "$migratorDbType");
					deleteMigratorVersions(2);
					$cleanSqlDirectory();
				});

				afterEach(() => {
					deleteMigratorVersions(2);
					StructDelete(application.wheels, "$trackingColumnsEnsured");
					StructDelete(application.wheels, "$migratorDbType");
					$cleanSqlDirectory();
				});

				it("include a date for an applied migration", () => {
					if (_isCockroachDB) {
						skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
						return;
					}
					migrator.migrateTo("001");
					var appliedAt = migrator.$appliedAtByVersion();
					expect(StructKeyExists(appliedAt, "001")).toBeTrue();
					expect(ReFind("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$", appliedAt["001"])).toBe(1);
				});

			});

		});

	}

}
