/**
 * Coverage for the column-metadata cache (perf). `$getColumns()` issues a
 * cfdbinfo type="columns" JDBC catalog round-trip — once per model class and
 * re-paid on every reload and for every model sharing a table. On
 * remote / wide-schema databases that round-trip dominates first-request
 * latency. When `cacheDatabaseSchema` is on, the resolved column query is now
 * memoized per datasource+table in `application.wheels.cache.schema` (rebuilt
 * on framework reload, so schema changes are still picked up on reload — the
 * same contract as the model/controller config caches).
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Snapshot the shared caches/settings so a mid-spec failure can't leave
		// the rest of the suite running against a polluted cache.
		if (StructKeyExists(application.wheels.cache, "schema")) {
			variables.$priorSchemaCache = Duplicate(application.wheels.cache.schema);
		}
		variables.$priorCacheDatabaseSchema = application.wheels.cacheDatabaseSchema;
	}

	function afterAll() {
		application.wheels.cache.schema = StructKeyExists(variables, "$priorSchemaCache")
			? variables.$priorSchemaCache
			: {};
		application.wheels.cacheDatabaseSchema = variables.$priorCacheDatabaseSchema;
	}

	function run() {

		g = application.wo;

		describe("$getColumns column-metadata cache", () => {

			it("memoizes columns per datasource+table when cacheDatabaseSchema is on", () => {
				application.wheels.cacheDatabaseSchema = true;
				application.wheels.cache.schema = {};
				var m = g.model("author");
				var adapter = m.$assignAdapter();
				var first = adapter.$getColumns(m.tableName());
				expect(StructCount(application.wheels.cache.schema)).toBeGT(0);
			});

			it("returns identical column metadata on the cached path", () => {
				application.wheels.cacheDatabaseSchema = true;
				application.wheels.cache.schema = {};
				var m = g.model("author");
				var adapter = m.$assignAdapter();
				var fresh = adapter.$getColumns(m.tableName());
				var cached = adapter.$getColumns(m.tableName());
				expect(cached.recordCount).toBe(fresh.recordCount);
				expect(cached.columnList).toBe(fresh.columnList);
			});

			it("does not populate the cache when cacheDatabaseSchema is off", () => {
				application.wheels.cacheDatabaseSchema = false;
				application.wheels.cache.schema = {};
				var m = g.model("author");
				var adapter = m.$assignAdapter();
				var cols = adapter.$getColumns(m.tableName());
				expect(StructCount(application.wheels.cache.schema)).toBe(0);
				// columns still resolve correctly with caching disabled
				expect(cols.recordCount).toBeGT(0);
			});

		});

	}

}
