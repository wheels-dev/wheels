/**
 * Regression coverage for #3844.
 *
 * The per-request finder cache keyed a result on the model, the finder arguments and the host,
 * but not on the datasource the query actually ran against. The tenant datasource is chosen inside
 * the adapter after the cache lookup, so switching tenant within a request returned the previous
 * tenant's cached result for an identical finder call.
 *
 * Requires the two SQLite test datasources (wheelstestdb_sqlite and wheelstestdb_sqlite_tenant_b);
 * the suite skips itself when they are not available.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("request query cache per datasource (##3844)", () => {

			var dsA = "wheelstestdb_sqlite";
			var dsB = "wheelstestdb_sqlite_tenant_b";

			var available = true;
			try {
				QueryExecute("SELECT 1 AS t", [], {datasource = dsA});
				QueryExecute("SELECT 1 AS t", [], {datasource = dsB});
			} catch (any e) {
				available = false;
			}
			if (!available || application.wheels.dataSourceName != dsA) return;

			beforeEach(() => {
				state = {cacheSetting = application.wheels.cacheQueriesDuringRequest};
				application.wheels.cacheQueriesDuringRequest = true;
				StructDelete(request.wheels, "tenant");
				StructDelete(request.wheels, "$queryCache");
				for (var ds in [dsA, dsB]) {
					QueryExecute("DROP TABLE IF EXISTS qc_products", [], {datasource = ds});
					QueryExecute("CREATE TABLE qc_products (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100) NOT NULL)", [], {datasource = ds});
				}
				QueryExecute("INSERT INTO qc_products (name) VALUES ('alpha-1')", [], {datasource = dsA});
				QueryExecute("INSERT INTO qc_products (name) VALUES ('alpha-2')", [], {datasource = dsA});
				QueryExecute("INSERT INTO qc_products (name) VALUES ('beta-1')", [], {datasource = dsB});
			})

			afterEach(() => {
				application.wheels.cacheQueriesDuringRequest = state.cacheSetting;
				StructDelete(request.wheels, "tenant");
				StructDelete(request.wheels, "$queryCache");
				for (var ds in [dsA, dsB]) {
					QueryExecute("DROP TABLE IF EXISTS qc_products", [], {datasource = ds});
				}
			})

			it("returns each tenant datasource's own findAll result within one request", () => {
				var first = model("QueryCacheProduct").findAll(order = "name");
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				var second = model("QueryCacheProduct").findAll(order = "name");

				expect(first.recordCount).toBe(2);
				expect(second.recordCount).toBe(1);
				expect(second.name[1]).toBe("beta-1");
			})

			it("returns each tenant datasource's own count within one request", () => {
				var first = model("QueryCacheProduct").count();
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				var second = model("QueryCacheProduct").count();

				expect(first).toBe(2);
				expect(second).toBe(1);
			})

			it("returns each explicit dataSource argument's own result within one request", () => {
				var first = model("QueryCacheProduct").findAll(dataSource = dsA);
				var second = model("QueryCacheProduct").findAll(dataSource = dsB);

				expect(first.recordCount).toBe(2);
				expect(second.recordCount).toBe(1);
			})

			it("still serves a repeat finder call on the same datasource from the cache", () => {
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				model("QueryCacheProduct").findAll(order = "name");
				model("QueryCacheProduct").findAll(order = "name");

				expect(StructCount(request.wheels["$queryCache"]["QueryCacheProduct"])).toBe(1);
			})
		});
	}
}
