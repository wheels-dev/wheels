/**
 * forgetCachedQueries() is the public way to drop the per-request finder cache that
 * `cacheQueriesDuringRequest` fills — replacing the old advice to reach into the reserved
 * `request.wheels["$queryCache"]` key directly. One global helper, scoped by how it's called:
 *   - model("Post").forgetCachedQueries()  clears that model's slot and returns the model (chainable)
 *   - forgetCachedQueries("Post")          clears a named model's slot from anywhere
 *   - forgetCachedQueries(all = true)       clears every model's slot this request
 *   - forgetCachedQueries() outside a model throws (no silent wipe-all)
 * The cache is namespaced under $queryCache per model name (#3336), so clearing is per-slot.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("forgetCachedQueries() — public request query-cache clear", () => {

			beforeEach(() => {
				originalCacheSetting = application.wheels.cacheQueriesDuringRequest;
				application.wheels.cacheQueriesDuringRequest = true;
				model("author").$clearRequestCache();
				model("post").$clearRequestCache();
			})

			afterEach(() => {
				application.wheels.cacheQueriesDuringRequest = originalCacheSetting;
				model("author").$clearRequestCache();
				model("post").$clearRequestCache();
			})

			it("clears one model's cached finder results and returns the model for chaining", () => {
				model("author").findAll(where = "lastName = 'Djurner'");
				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(1);

				var chained = model("author").forgetCachedQueries();

				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(0);
				// chainable: the returned model answers a finder straight away
				expect(chained.findAll(where = "lastName = 'Djurner'").recordCount).toBe(1);
			})

			it("clears only the named model, leaving other models' cached results in place", () => {
				model("author").findAll(where = "lastName = 'Djurner'");
				model("post").findAll(where = "id > 0");
				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(1);
				expect(StructCount(request.wheels["$queryCache"]["post"])).toBe(1);

				model("author").forgetCachedQueries();

				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(0);
				expect(StructCount(request.wheels["$queryCache"]["post"])).toBe(1);
			})

			it("clears a named model's slot via the modelName argument", () => {
				model("author").findAll(where = "lastName = 'Djurner'");
				model("post").findAll(where = "id > 0");

				application.wo.forgetCachedQueries("author");

				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(0);
				expect(StructCount(request.wheels["$queryCache"]["post"])).toBe(1);
			})

			it("normalises a namespaced model name to the bare cache slot", () => {
				model("author").findAll(where = "lastName = 'Djurner'");
				// The cache is keyed by ListLast(name, "/"), so "admin/author" must hit the "author" slot.
				application.wo.forgetCachedQueries("admin/author");

				expect(StructCount(request.wheels["$queryCache"]["author"])).toBe(0);
			})

			it("forgetCachedQueries(all = true) clears every model's cached results this request", () => {
				model("author").findAll(where = "lastName = 'Djurner'");
				model("post").findAll(where = "id > 0");
				expect(StructKeyExists(request.wheels, "$queryCache")).toBeTrue();

				application.wo.forgetCachedQueries(all = true);

				expect(StructKeyExists(request.wheels, "$queryCache")).toBeFalse();
			})

			it("a bare call outside a model throws rather than silently wiping every model", () => {
				expect(function() {
					application.wo.forgetCachedQueries();
				}).toThrow("Wheels.InvalidArgument");
			})

			it("the all = true clear is a safe no-op when nothing has been cached yet", () => {
				if (StructKeyExists(request.wheels, "$queryCache")) {
					StructDelete(request.wheels, "$queryCache");
				}
				application.wo.forgetCachedQueries(all = true);
				expect(StructKeyExists(request.wheels, "$queryCache")).toBeFalse();
			})

		})

	}

}
