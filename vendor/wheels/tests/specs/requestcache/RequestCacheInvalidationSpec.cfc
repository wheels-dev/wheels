/**
 * #4429: the per-request finder cache (cacheQueriesDuringRequest) must be invalidated across models
 * on any ORM write, and on a transaction rollback — not just in the writing model's own slot.
 *
 * The core runner forces cacheQueriesDuringRequest OFF (tests/runner.cfm), so these specs turn it ON
 * themselves. The setting is read at call time in model/read.cfm, so a per-group flip works. beforeEach
 * flips it on; afterEach restores it AND restores the one post + author these specs mutate, and wipes
 * request.wheels["$queryCache"] — all of that runs even when a spec fails, so a failing spec can't leak
 * a mutated row or a cached row into the next spec (the whole suite runs in one request). Catch writes
 * would use `var state` (cross-engine invariant 11); none are needed here.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		var wo = application.wo;
		var post = wo.model("Post").findOne(where = "authorid IS NOT NULL", order = "id", returnAs = "query");
		variables.postId = post.id;
		variables.postTitle = post.title;
		variables.authorId = post.authorid;
		variables.authorFirstName = wo.model("Author").findByKey(variables.authorId).firstName;
	}

	function run() {

		describe("request query cache invalidation (4429)", () => {

			beforeEach(() => {
				variables.g = application.wo;
				variables.cacheWas = application.wheels.cacheQueriesDuringRequest;
				application.wheels.cacheQueriesDuringRequest = true;
				$wipeRequestQueryCache();
			});

			afterEach(() => {
				// Restore the rows the specs mutate, unconditionally, so a failed spec leaves no pollution.
				g.model("Post").findByKey(variables.postId).update(title = variables.postTitle);
				g.model("Author").findByKey(variables.authorId).update(firstName = variables.authorFirstName);
				application.wheels.cacheQueriesDuringRequest = variables.cacheWas;
				$wipeRequestQueryCache();
			});

			it("serves a repeated read from cache when no ORM write intervenes (cache really is on)", () => {
				var first = g.model("Post").findAll(where = "id = #variables.postId#", returnAs = "query").title;
				// A RAW write bypasses ORM invalidation, so with the cache ON the next read is still the
				// cached value — proof the cache is active (and why raw writes need forgetCachedQueries).
				$rawPostTitle(variables.postId, "RawTitle4429");
				var second = g.model("Post").findAll(where = "id = #variables.postId#", returnAs = "query").title;
				expect(second).toBe(first);
				expect(second).notToBe("RawTitle4429");
			});

			it("an ORM write to a model clears that model's own cached finder", () => {
				g.model("Post").findAll(where = "id = #variables.postId#", returnAs = "query");
				g.model("Post").findByKey(variables.postId).update(title = "Changed4429a");
				expect(g.model("Post").findAll(where = "id = #variables.postId#", returnAs = "query").title).toBe("Changed4429a");
			});

			it("an ORM write to an INCLUDED model clears a base model's include= cached query", () => {
				var sel = "c_o_r_e_posts.id, c_o_r_e_authors.firstName AS authorName4429";
				// Cache the Post finder that joins Author (lives in the Post slot, keyed by this SQL).
				g.model("Post").findAll(where = "c_o_r_e_posts.id = #variables.postId#", include = "author", select = sel, returnAs = "query");
				// An ORM write to the INCLUDED model. Pre-fix this cleared only the Author slot, so the
				// Post slot kept serving the pre-write author column for the rest of the request.
				g.model("Author").findByKey(variables.authorId).update(firstName = "Changed4429b");
				var after = g.model("Post").findAll(where = "c_o_r_e_posts.id = #variables.postId#", include = "author", select = sel, returnAs = "query").authorName4429;
				expect(after).toBe("Changed4429b");
			});

			it("a transaction rollback clears reads cached inside it (no phantom rows)", () => {
				// The probe writes then reads inside the transaction (caching the uncommitted row), then
				// returns false to roll back. Pre-fix the phantom row stayed cached after the rollback.
				g.model("Author").findByKey(variables.authorId).invokeWithTransaction(method = "$cacheRollbackProbe4429", transaction = "rollback");
				expect(g.model("Author").findByKey(variables.authorId).firstName).toBe(variables.authorFirstName);
			});

			it("a rollback through the exception (throw) path clears cached reads too", () => {
				// The probe throws instead of returning false, so the transaction rolls back through the
				// begin-catch branch of $runInTransaction, which must clear the cache just like the other path.
				var state = {threw = false};
				try {
					g.model("Author").findByKey(variables.authorId).invokeWithTransaction(method = "$throwRollbackProbe4429", transaction = "commit");
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
				expect(g.model("Author").findByKey(variables.authorId).firstName).toBe(variables.authorFirstName);
			});

			it("a savepoint rollback clears reads cached inside the savepoint (no phantom), outer carries on", () => {
				// The outer transaction commits; inside it a savepoint unit writes + reads (caching the
				// uncommitted row) then rolls back. Pre-fix the savepoint's phantom row stayed cached while
				// the outer transaction continued and committed.
				g.model("Author").findByKey(variables.authorId).invokeWithTransaction(method = "$savepointOuter4429", transaction = "commit");
				expect(g.model("Author").findByKey(variables.authorId).firstName).toBe(variables.authorFirstName);
			});

		});

	}

	private void function $wipeRequestQueryCache() {
		if (StructKeyExists(request, "wheels")) {
			request.wheels["$queryCache"] = {};
		}
	}

	private void function $rawPostTitle(required numeric id, required string title) {
		queryExecute(
			"UPDATE c_o_r_e_posts SET title = :title WHERE id = :id",
			{title = {value = arguments.title}, id = {value = arguments.id, cfsqltype = "cf_sql_integer"}},
			{datasource = application.wheels.dataSourceName}
		);
	}

}
