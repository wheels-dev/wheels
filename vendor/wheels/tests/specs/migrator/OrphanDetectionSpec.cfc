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

		// Helper for inserting fake orphan versions directly into the
		// tracking table. Pulled into a function so each `it` doesn't
		// repeat the SQL.
		var insertOrphan = function(required string version) {
			queryExecute(
				"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('#arguments.version#', #application.wheels.migrationLevel#)",
				{},
				{ datasource = application.wheels.dataSourceName }
			);
		};

		describe("$getOrphanVersions", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			it("returns empty array when DB and files match", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				var orphans = migrator.$getOrphanVersions();
				expect(orphans).toBeArray();
				expect(ArrayLen(orphans)).toBe(0);
			});

			it("returns the orphan when DB has a version with no matching file", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var orphans = migrator.$getOrphanVersions();
				expect(ArrayLen(orphans)).toBe(1);
				expect(orphans[1]).toBe("999");
			});

			it("returns multiple orphans sorted ascending", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				insertOrphan("998");
				var orphans = migrator.$getOrphanVersions();
				expect(ArrayLen(orphans)).toBe(2);
				expect(orphans[1]).toBe("998");
				expect(orphans[2]).toBe("999");
			});

			it("ignores the sentinel '0' returned by empty tracking table", () => {
				if (_isCockroachDB) return;
				var orphans = migrator.$getOrphanVersions();
				expect(ArrayLen(orphans)).toBe(0);
			});

		});

		describe("migrateTo with orphan-at-top", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			afterEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			it("does not take the down branch when only orphans separate current from target", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var output = migrator.migrateTo("003");
				expect(output).notToInclude("down to 003");
			});

			it("applies pending local migrations when only orphans separate current from target", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				migrator.migrateTo("003");
				var info = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears");
				expect(ListFindNoCase(ValueList(info.table_name), "c_o_r_e_dropbears")).toBeTrue();
				var info2 = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_hoopsnakes");
				expect(ListFindNoCase(ValueList(info2.table_name), "c_o_r_e_hoopsnakes")).toBeTrue();
			});

			it("emits a warning naming the orphan version(s)", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var output = migrator.migrateTo("003");
				expect(output).toInclude("999");
				expect(output).toInclude("no matching file");
			});

			it("prints a clear nothing-to-do message when no pending local migrations exist", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("003");
				insertOrphan("999");
				var output = migrator.migrateToLatest();
				expect(output).notToInclude("down to");
				expect(output).toInclude("999");
				expect(output).toInclude("Nothing to do");
			});

			it("still allows legitimate down-migration when down target has a local file", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("002");
				var output = migrator.migrateTo("001");
				expect(output).toInclude("down to 001");
				var info = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears");
				expect(ListFindNoCase(ValueList(info.table_name), "c_o_r_e_dropbears")).toBeFalse();
			});

			it("warns about orphans and still runs the down branch when both are present above target", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("002");
				insertOrphan("999");
				var output = migrator.migrateTo("001");
				expect(output).toInclude("999");
				expect(output).toInclude("skipped during rollback");
				expect(output).toInclude("down to 001");
				var info = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears");
				expect(ListFindNoCase(ValueList(info.table_name), "c_o_r_e_dropbears")).toBeFalse();
			});

		});

	}

}
