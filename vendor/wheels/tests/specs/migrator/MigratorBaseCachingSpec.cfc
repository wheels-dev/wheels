/**
 * Coverage for the migrator Base.cfc caching layers:
 *
 *   1. $getDBType() memoizes the resolved adapter name per datasource on the
 *      application scope — discovery paths (Migrator.getAvailableMigrations())
 *      instantiate every migration CFC, and each init() used to trigger a
 *      fresh $dbinfo(version) round-trip.
 *   2. $getColumns() caches the column list per request — addRecord() /
 *      updateRecord() consult it for every row, so a multi-row seed migration
 *      used to issue a full table-metadata round-trip per row (two per row in
 *      addRecord's case). Any statement routed through $execute() drops the
 *      cache so DDL in the same request is reflected on the next read.
 *
 * Both tests use the "poison the cache with a sentinel" technique: if the
 * implementation consults the cache, the sentinel comes back; if it re-probes
 * the database, the real value comes back and the test fails.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function run() {

		describe("Migrator Base.cfc caching", () => {

			it("memoizes the $getDBType() adapter name per datasource", () => {
				var dsName = application.wheels.dataSourceName;
				var realType = variables.migration.$getDBType();
				expect(Len(realType)).toBeGT(0);
				expect(StructKeyExists(application.wheels, "$migratorAdapterNames")).toBeTrue();
				expect(StructKeyExists(application.wheels.$migratorAdapterNames, dsName)).toBeTrue();
				expect(application.wheels.$migratorAdapterNames[dsName]).toBe(realType);

				// Poison the cache to prove subsequent calls consume it instead
				// of re-probing the database.
				application.wheels.$migratorAdapterNames[dsName] = "SentinelAdapter";
				try {
					expect(variables.migration.$getDBType()).toBe("SentinelAdapter");
				} finally {
					application.wheels.$migratorAdapterNames[dsName] = realType;
				}
			});

			it("caches $getColumns() per request and invalidates on $execute()", () => {
				var tableName = "c_o_r_e_authors";
				var cacheKey = LCase(application.wheels.dataSourceName & "|" & tableName);
				StructDelete(request, "$wheelsMigratorColumns");

				var realColumns = variables.migration.$getColumns(tableName);
				expect(Len(realColumns)).toBeGT(0);
				expect(StructKeyExists(request, "$wheelsMigratorColumns")).toBeTrue();
				expect(StructKeyExists(request.$wheelsMigratorColumns, cacheKey)).toBeTrue();

				// Poison the cache to prove the next read consumes it.
				request.$wheelsMigratorColumns[cacheKey] = "sentinelcolumn";
				expect(variables.migration.$getColumns(tableName)).toBe("sentinelcolumn");

				// Any statement routed through $execute() may change the schema,
				// so it must drop the cache (dry-run capture keeps the DB
				// untouched here).
				request.$wheelsDebugSQL = true;
				request.$wheelsDebugSQLResult = [];
				try {
					variables.migration.execute("SELECT 1 FROM #tableName# WHERE 1=0");
				} finally {
					StructDelete(request, "$wheelsDebugSQL");
					StructDelete(request, "$wheelsDebugSQLResult");
				}
				expect(
					StructKeyExists(request, "$wheelsMigratorColumns")
					&& StructKeyExists(request.$wheelsMigratorColumns, cacheKey)
				).toBeFalse();
				expect(variables.migration.$getColumns(tableName)).toBe(realColumns);
			});

		});
	}
}
