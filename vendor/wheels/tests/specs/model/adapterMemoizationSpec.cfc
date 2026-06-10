/**
 * Regression coverage for db-adapters review finding DA15 — `$assignAdapter()`
 * re-probed the database ($dbinfo version plus a SELECT version() roundtrip on
 * PostgreSQL-driver datasources) on every model class init. The resolved
 * adapter is now memoized per datasource in `application.wheels.adapterCache`
 * (rebuilt on framework reload) so subsequent model class inits skip the
 * probe.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$assignAdapter per-datasource memoization (DA15)", () => {

			it("caches the resolved adapter per datasource in the application scope", () => {
				StructDelete(application.wheels, "adapterCache");
				g.model("author").$assignAdapter();
				expect(StructKeyExists(application.wheels, "adapterCache")).toBeTrue();
				expect(StructKeyExists(application.wheels.adapterCache, application.wheels.dataSourceName)).toBeTrue();
				var cached = application.wheels.adapterCache[application.wheels.dataSourceName];
				expect(cached).toHaveKey("namespace");
				expect(cached).toHaveKey("name");
				expect(cached.name).toBe(get("adapterName"));
			});

			it("returns the same adapter type from the cached path as from a fresh probe", () => {
				StructDelete(application.wheels, "adapterCache");
				var probed = g.model("author").$assignAdapter();
				var cachedResult = g.model("author").$assignAdapter();
				expect(GetMetaData(cachedResult).name).toBe(GetMetaData(probed).name);
				expect(ListLast(GetMetaData(cachedResult).name, ".")).toBe(get("adapterName"));
			});

		});

	}

}
