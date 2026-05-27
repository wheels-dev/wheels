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

		var insertOrphan = function(required string version) {
			queryExecute(
				"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('#arguments.version#', #application.wheels.migrationLevel#)",
				{},
				{ datasource = application.wheels.dataSourceName }
			);
		};

		describe("Migrator info output", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
			});

			afterEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
			});

			it("$buildInfoOutput returns expected lines for a clean state", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("002");
				var lines = migrator.$buildInfoOutput();
				expect(lines).toBeArray();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).toInclude("Current version:");
				expect(joined).toInclude("[x] 001");
				expect(joined).toInclude("[x] 002");
				expect(joined).toInclude("[ ] 003");
			});

			it("$buildInfoOutput marks orphan versions with [?] and NO FILE", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var lines = migrator.$buildInfoOutput();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).toInclude("[?] 999");
				expect(joined).toInclude("NO FILE");
			});

			it("$buildInfoOutput summary counts orphans separately", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var lines = migrator.$buildInfoOutput();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).toInclude("orphan: 1");
			});

			it("$buildInfoOutput omits orphan summary line when no orphans exist", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				var lines = migrator.$buildInfoOutput();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).notToInclude("orphan:");
			});

		});

	}

}
