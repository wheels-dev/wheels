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

		describe("doctor()", () => {

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

			it("returns a clean health struct when DB and files match", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("003");
				var report = migrator.doctor();
				expect(report).toBeStruct();
				expect(report.healthy).toBeTrue();
				expect(ArrayLen(report.orphans)).toBe(0);
				expect(ArrayLen(report.pending)).toBe(0);
				expect(report.summary.applied).toBe(3);
				expect(report.summary.total).toBe(3);
			});

			it("flags orphans as unhealthy", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var report = migrator.doctor();
				expect(report.healthy).toBeFalse();
				expect(ArrayLen(report.orphans)).toBe(1);
				expect(report.orphans[1]).toBe("999");
			});

			it("flags pending local migrations", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				var report = migrator.doctor();
				expect(report.healthy).toBeFalse();
				expect(ArrayLen(report.pending)).toBe(2);
			});

			it("includes a human-readable summary message", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var report = migrator.doctor();
				expect(report.message).toBeString();
				expect(report.message).toInclude("orphan");
			});

		});

		describe("forgetVersion()", () => {

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

			it("removes an orphan version from the tracking table", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				insertOrphan("999");
				var result = migrator.forgetVersion("999");
				expect(result.success).toBeTrue();
				expect(result.removed).toBe("999");
				expect(ArrayLen(migrator.$getOrphanVersions())).toBe(0);
			});

			it("refuses to forget a version that has a local file", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("002");
				var result = migrator.forgetVersion("002");
				expect(result.success).toBeFalse();
				expect(result.message).toInclude("local file");
			});

			it("refuses to forget a version that is not in the tracking table", () => {
				if (_isCockroachDB) return;
				var result = migrator.forgetVersion("999");
				expect(result.success).toBeFalse();
				expect(result.message).toInclude("not found");
			});

			it("returns a failure for invalid version input", () => {
				if (_isCockroachDB) return;
				var result = migrator.forgetVersion("abc");
				expect(result.success).toBeFalse();
				expect(result.message).toInclude("Invalid version");
			});

		});

		describe("pretendVersion()", () => {

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

			it("records a version as applied without running its up()", () => {
				if (_isCockroachDB) return;
				var result = migrator.pretendVersion("001");
				expect(result.success).toBeTrue();
				expect(result.recorded).toBe("001");
				var versions = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '001'",
					{},
					{datasource = application.wheels.dataSourceName}
				);
				expect(versions.recordCount).toBe(1);
				var info = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_bunyips");
				expect(ListFindNoCase(ValueList(info.table_name), "c_o_r_e_bunyips")).toBeFalse();
			});

			it("refuses to pretend a version that is already applied", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				var result = migrator.pretendVersion("001");
				expect(result.success).toBeFalse();
				expect(result.message).toInclude("already applied");
			});

			it("refuses to pretend a version that has no local file", () => {
				if (_isCockroachDB) return;
				var result = migrator.pretendVersion("999");
				expect(result.success).toBeFalse();
				expect(result.message).toInclude("no matching file");
			});

			it("returns a failure for invalid version input", () => {
				if (_isCockroachDB) return;
				var result = migrator.pretendVersion("abc");
				expect(result.success).toBeFalse();
				expect(result.message).toInclude("Invalid version");
			});

		});

	}

}
