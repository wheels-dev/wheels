component extends="wheels.WheelsTest" {

	function run() {

		describe("request-level query cache", () => {

			beforeEach(() => {
				originalCacheSetting = application.wheels.cacheQueriesDuringRequest;
				model("author").$clearRequestCache();
			})

			afterEach(() => {
				application.wheels.cacheQueriesDuringRequest = originalCacheSetting;
				model("author").$clearRequestCache();
			})

			it("stores a single entry per unique findAll call when enabled", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				model("author").findAll(where = "lastName = 'Djurner'");
				expect(StructCount(request.wheels["author"])).toBe(1);
				model("author").findAll(where = "lastName = 'Djurner'");
				expect(StructCount(request.wheels["author"])).toBe(1);
			})

			it("keeps distinct entries for same-shape queries that differ only by where values", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				var djurner = model("author").findAll(where = "lastName = 'Djurner'");
				var petruzzi = model("author").findAll(where = "lastName = 'Petruzzi'");
				expect(StructCount(request.wheels["author"])).toBe(2);
				expect(djurner.recordCount).toBe(1);
				expect(petruzzi.recordCount).toBe(1);
				expect(djurner.lastName).toBe("Djurner");
				expect(petruzzi.lastName).toBe("Petruzzi");
			})

			it("does not store query results when cacheQueriesDuringRequest is disabled", () => {
				application.wheels.cacheQueriesDuringRequest = false;
				model("author").findAll(where = "lastName = 'Djurner'");
				expect(StructCount(request.wheels["author"])).toBe(0);
			})

			it("findEach does not accumulate per-batch queries in the request cache", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				var expectedTotal = model("author").count();
				model("author").$clearRequestCache();
				var result = {count = 0};
				model("author").findEach(
					order = "id",
					batchSize = 2,
					callback = function(record) {
						result.count++;
					}
				);
				// Only the single up-front COUNT query may be cached, the per-batch id/data queries must not accumulate.
				expect(StructCount(request.wheels["author"])).toBeLTE(1);
				expect(result.count).toBe(expectedTotal);
			})

			it("does not fragment the application-scoped SQL cache by request-cache flag", () => {
				// The application-scoped SQL cache (category "sql") encodes only the SQL structure.
				// $useRequestCache governs request-level caching and produces no SQL output, so it must NOT participate in the shell key — otherwise every model that uses both batch and non-batch finders accumulates two SQL entries per shape.
				StructClear(application.wheels.cache.sql);
				application.wheels.cacheQueriesDuringRequest = true;
				model("author").$clearRequestCache();
				model("author").findAll(where = "lastName = 'Djurner'", order = "firstName");
				var sqlEntriesAfterRegular = StructCount(application.wheels.cache.sql);
				// Same SQL shape via the batch-finders' opt-out flag — must reuse the existing shell entry.
				model("author").findAll(where = "lastName = 'Djurner'", order = "firstName", $useRequestCache = false);
				expect(StructCount(application.wheels.cache.sql)).toBe(sqlEntriesAfterRegular);
			})

			it("findInBatches does not accumulate per-batch queries in the request cache", () => {
				application.wheels.cacheQueriesDuringRequest = true;
				var expectedTotal = model("author").count();
				model("author").$clearRequestCache();
				var result = {totalRecords = 0, batchCount = 0};
				model("author").findInBatches(
					order = "id",
					batchSize = 3,
					callback = function(records) {
						result.totalRecords += records.recordCount;
						result.batchCount++;
					}
				);
				// Only the single up-front COUNT query may be cached, the per-batch id/data queries must not accumulate.
				expect(StructCount(request.wheels["author"])).toBeLTE(1);
				expect(result.totalRecords).toBe(expectedTotal);
				expect(result.batchCount).toBeGTE(2);
			})

		})

	}
}
