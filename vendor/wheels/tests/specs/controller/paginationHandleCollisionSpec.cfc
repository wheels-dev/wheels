/**
 * Regression coverage for #3339.
 *
 * `setPagination()` / `pagination()` key themselves on a caller-supplied handle name (default
 * `"query"`), which used to be written straight into `request.wheels`. CFML struct keys are
 * case-insensitive, so a handle matching a framework-owned key collided with it in both
 * directions:
 *
 *   1. Write: `setPagination(handle="tenant")` overwrote the resolved tenant context with a
 *      pagination struct. `handle="$queryCache"` did the same to the per-request finder cache.
 *   2. Read: `pagination()` only validates the handle when `showErrorInformation` is on, so in
 *      production an unknown handle that happened to name a framework key returned that key's
 *      struct as though it were pagination state.
 *
 * Handles now live under the reserved `request.wheels.$pagination` sub-struct. Same fix shape as
 * #3336, which moved the finder cache to `request.wheels.$queryCache`.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("pagination handle / framework key collision (##3339)", () => {

			// The whole core suite runs inside a single request, so request.wheels is shared across
			// spec files. Only ever remove this spec's own handles — deleting the $pagination
			// namespace wholesale would destroy handles other specs set up.
			ownHandles = "articles,comments,tenant,$queryCache,noSuchHandleXYZ";

			// Ensure the namespace inline rather than calling g.$ensurePaginationStore(): a
			// zero-argument dotted call in statement position breaks Adobe CF 2025's parser.
			beforeEach(() => {
				originalShowErr = application.wheels.showErrorInformation;
				originalCacheSetting = application.wheels.cacheQueriesDuringRequest;
				StructDelete(request.wheels, "tenant");
				if (!StructKeyExists(request.wheels, "$pagination")) {
					request.wheels["$pagination"] = {};
				}
				paginationStore = request.wheels["$pagination"];
				for (var h in ListToArray(ownHandles)) {
					StructDelete(paginationStore, h, false);
				}
			})

			afterEach(() => {
				application.wheels.showErrorInformation = originalShowErr;
				application.wheels.cacheQueriesDuringRequest = originalCacheSetting;
				StructDelete(request.wheels, "tenant");
				if (!StructKeyExists(request.wheels, "$pagination")) {
					request.wheels["$pagination"] = {};
				}
				paginationStore = request.wheels["$pagination"];
				for (var h in ListToArray(ownHandles)) {
					StructDelete(paginationStore, h, false);
				}
			})

			it("stores handles under the reserved namespace, not the bare key", () => {
				g.setPagination(totalRecords = 100, currentPage = 2, perPage = 10, handle = "articles");

				expect(StructKeyExists(request.wheels, "$pagination")).toBeTrue();
				expect(StructKeyExists(request.wheels["$pagination"], "articles")).toBeTrue();
				expect(StructKeyExists(request.wheels, "articles")).toBeFalse();
			})

			it("round-trips pagination data through the namespace", () => {
				g.setPagination(totalRecords = 100, currentPage = 2, perPage = 10, handle = "articles");
				var pg = g.pagination("articles");

				expect(pg.totalRecords).toBe(100);
				expect(pg.currentPage).toBe(2);
				expect(pg.perPage).toBe(10);
				expect(pg.totalPages).toBe(10);
			})

			// Write direction — a handle named after a framework key must not clobber it.
			it("does not overwrite resolved tenant context when a handle is named tenant", () => {
				request.wheels.tenant = {id = "acme", dataSource = "tenant_acme", config = {}, "$locked" = true};

				g.setPagination(totalRecords = 50, currentPage = 1, perPage = 25, handle = "tenant");

				expect(IsDefined("request.wheels.tenant")).toBeTrue();
				expect(request.wheels.tenant.id).toBe("acme");
				expect(request.wheels.tenant.dataSource).toBe("tenant_acme");
				expect(g.$tenantDataSource()).toBe("tenant_acme");
			})

			it("does not overwrite the finder cache namespace when a handle is named $queryCache", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				model("author").findAll(where = "lastName = 'Djurner'");
				var cachedBefore = StructCount(request.wheels["$queryCache"]["author"]);

				g.setPagination(totalRecords = 50, currentPage = 1, perPage = 25, handle = "$queryCache");

				expect(StructKeyExists(request.wheels["$queryCache"], "author")).toBeTrue();
				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(cachedBefore);
			})

			// Read direction — the case showErrorInformation hides in production.
			it("does not return a framework struct for an unknown handle when errors are hidden", () => {
				application.wheels.showErrorInformation = false;
				request.wheels.tenant = {id = "acme", dataSource = "tenant_acme", config = {}, "$locked" = true};

				// Pre-fix this returned the tenant struct as though it were pagination data.
				// It must now fail to resolve rather than hand back foreign state.
				var result = {returnedTenant = false, threw = false};
				try {
					var pg = g.pagination("tenant");
					result.returnedTenant = IsStruct(pg) && StructKeyExists(pg, "dataSource");
				} catch (any e) {
					result.threw = true;
				}

				expect(result.returnedTenant).toBeFalse();
				expect(result.threw).toBeTrue();
			})

			it("still throws Wheels.QueryHandleNotFound for an unknown handle in development", () => {
				application.wheels.showErrorInformation = true;

				expect(function() {
					g.pagination("noSuchHandleXYZ");
				}).toThrow("Wheels.QueryHandleNotFound");
			})

			it("keeps distinct handles isolated from each other", () => {
				g.setPagination(totalRecords = 100, currentPage = 1, perPage = 10, handle = "articles");
				g.setPagination(totalRecords = 30, currentPage = 3, perPage = 5, handle = "comments");

				expect(g.pagination("articles").totalRecords).toBe(100);
				expect(g.pagination("comments").totalRecords).toBe(30);
				expect(g.pagination("comments").currentPage).toBe(3);
			})

		})

	}
}
