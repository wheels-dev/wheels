/**
 * Regression coverage for #3336.
 *
 * The per-request finder cache used to key itself on the bare model name directly in
 * `request.wheels`. CFML struct keys are case-insensitive, so an app with a model named `Tenant`
 * — the documented name for the control-plane model in a database-per-tenant app — had its query
 * cache and its resolved-tenant context aliased onto the single key `request.wheels.tenant`.
 *
 * Two failure modes followed:
 *   1. Write path: `$clearRequestCache()` (called after every create/update/delete/bulk op) set
 *      `request.wheels.tenant = {}`, wiping the resolved tenant for the rest of the request. Every
 *      later tenant-scoped query silently fell back to the control-plane datasource.
 *   2. Read path: a `Tenant` finder running before resolution created `request.wheels.tenant` as a
 *      query-cache struct, so `IsDefined("request.wheels.tenant")` reported an unresolved request
 *      as resolved.
 *
 * The cache now lives under the reserved `request.wheels.$queryCache` sub-struct.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("request query cache / tenant key collision (##3336)", () => {

			beforeEach(() => {
				originalCacheSetting = application.wheels.cacheQueriesDuringRequest;
				StructDelete(request.wheels, "tenant");
				StructDelete(request.wheels, "$queryCache");
			})

			afterEach(() => {
				application.wheels.cacheQueriesDuringRequest = originalCacheSetting;
				StructDelete(request.wheels, "tenant");
				StructDelete(request.wheels, "$queryCache");
			})

			it("keeps the query cache out of the bare model-name key", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				model("Tenant").findAll(where = "lastName = 'Djurner'");

				expect(StructKeyExists(request.wheels, "$queryCache")).toBeTrue();
				expect(StructKeyExists(request.wheels["$queryCache"], "Tenant")).toBeTrue();
				// The bare key is what aliased onto request.wheels.tenant.
				expect(StructKeyExists(request.wheels, "Tenant")).toBeFalse();
			})

			it("still caches repeat finder calls once namespaced", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				model("Tenant").findAll(where = "lastName = 'Djurner'");
				model("Tenant").findAll(where = "lastName = 'Djurner'");

				expect(StructCount(request.wheels["$queryCache"]["Tenant"])).toBe(1);
			})

			// Failure mode 2 — read path.
			it("does not fabricate a resolved tenant when a Tenant finder runs before resolution", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				model("Tenant").findAll(where = "lastName = 'Djurner'");

				expect(IsDefined("request.wheels.tenant")).toBeFalse();
				expect(StructIsEmpty(g.tenant())).toBeTrue();
			})

			// Failure mode 1 — write path, via the helper every write path calls.
			it("does not erase resolved tenant context when a Tenant model clears its request cache", () => {
				request.wheels.tenant = {id = "acme", dataSource = "tenant_acme", config = {}, "$locked" = true};

				model("Tenant").$clearRequestCache();

				expect(IsDefined("request.wheels.tenant")).toBeTrue();
				expect(request.wheels.tenant.id).toBe("acme");
				expect(request.wheels.tenant.dataSource).toBe("tenant_acme");
				expect(g.$tenantDataSource()).toBe("tenant_acme");
			})

			// Failure mode 1 — write path, through a real bulk write rather than the helper directly.
			// The where clause matches nothing, so this mutates no fixture data but still reaches
			// $updateAll() -> $clearRequestCache(). The tenant datasource must be the real one: the
			// write executes for real, and pointing it at a non-existent datasource throws inside
			// updateAll's transaction and leaves transaction state dirty for later specs.
			it("keeps the resolved tenant intact after a Tenant write in the same request", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				request.wheels.tenant = {
					id = "acme",
					dataSource = application.wheels.dataSourceName,
					config = {},
					"$locked" = true
				};

				model("Tenant").updateAll(
					where = "lastName = 'NoSuchTenantXYZ'",
					instantiate = false,
					firstName = "ignored"
				);

				expect(IsDefined("request.wheels.tenant")).toBeTrue();
				expect(request.wheels.tenant.id).toBe("acme");
				expect(g.$tenantDataSource()).toBe(application.wheels.dataSourceName);
			})

			it("clears only its own model's cache, leaving sibling models untouched", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				model("author").findAll(where = "lastName = 'Djurner'");
				model("Tenant").findAll(where = "lastName = 'Djurner'");
				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(1);

				model("Tenant").$clearRequestCache();

				expect(StructCount(request.wheels["$queryCache"]["Tenant"])).toBe(0);
				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(1);
			})

		})

	}
}
