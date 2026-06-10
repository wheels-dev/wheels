/**
 * Tests for RateLimiter middleware with storage="database".
 * Covers enforcement for all three strategies, single-row counter accumulation,
 * portable table auto-creation, expired-row purging, and failOpen behavior
 * when the table is unavailable.
 *
 * The in-memory storage tests live in RateLimiterSpec.cfc.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("RateLimiter database storage", function() {

			beforeEach(function() {
				$cleanRateLimitRows();
			});

			afterEach(function() {
				$cleanRateLimitRows();
			});

			it("fixedWindow + database enforces the limit", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 3600,
					storage = "database"
				);
				var nextFn = function(req) {
					return "passed";
				};
				var clientKey = "rl-db-fixed-#CreateUUID()#";

				var result1 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result2 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result3 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result4 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);

				expect(result1).toBe("passed");
				expect(result2).toBe("passed");
				expect(result3).toBe("passed");
				expect(result4).toInclude("Rate limit exceeded");
			});

			it("counter accumulates in a single row", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 10,
					windowSeconds = 3600,
					storage = "database"
				);
				var nextFn = function(req) {
					return "passed";
				};
				var clientKey = "rl-db-row-#CreateUUID()#";

				limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);

				// Fixed window store keys are "<clientKey>:<windowId>".
				var qRows = QueryExecute(
					"SELECT COUNT(*) AS rowTotal, MAX(counter) AS maxCounter FROM wheels_rate_limits WHERE store_key LIKE :pattern",
					{pattern: {value: clientKey & ":%", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(qRows.rowTotal).toBe(1);
				expect(qRows.maxCounter).toBe(2);
			});

			it("$ensureTable creates the table and reports success", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					storage = "database"
				);
				prepareMock(limiter);
				makePublic(limiter, "$ensureTable");

				expect(limiter.$ensureTable()).toBeTrue();

				// The table must really exist now — a direct probe should not throw.
				var qProbe = QueryExecute(
					"SELECT counter FROM wheels_rate_limits WHERE 1=0",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(qProbe.recordCount).toBe(0);
			});

			it("purges expired rows", function() {
				// Make sure the table exists before inserting directly.
				var setupLimiter = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					storage = "database"
				);
				prepareMock(setupLimiter);
				makePublic(setupLimiter, "$ensureTable");
				expect(setupLimiter.$ensureTable()).toBeTrue();

				var staleKey = "rl-db-stale-#CreateUUID()#";
				QueryExecute(
					"INSERT INTO wheels_rate_limits (store_key, counter, expires_at) VALUES (:storeKey, 1, :expiresAt)",
					{
						storeKey: {value: staleKey, cfsqltype: "cf_sql_varchar"},
						expiresAt: {value: DateAdd("d", -1, Now()), cfsqltype: "cf_sql_timestamp"}
					},
					{datasource: application.wheels.dataSourceName}
				);

				// A fresh limiter (lastDbPurge = 0) purges on its first request.
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					storage = "database"
				);
				var nextFn = function(req) {
					return "passed";
				};
				limiter.handle(request = {remoteAddr: "rl-db-purger-#CreateUUID()#"}, next = nextFn);

				var qStale = QueryExecute(
					"SELECT COUNT(*) AS rowTotal FROM wheels_rate_limits WHERE store_key = :storeKey",
					{storeKey: {value: staleKey, cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(qStale.rowTotal).toBe(0);
			});

			it("slidingWindow + database enforces the limit", function() {
				// Also a regression guard: sliding window stores one row per request
				// under the same store_key, so the fix must NOT add a UNIQUE index.
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "slidingWindow",
					storage = "database"
				);
				var nextFn = function(req) {
					return "passed";
				};
				var clientKey = "rl-db-sliding-#CreateUUID()#";

				var result1 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result2 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result3 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);

				expect(result1).toBe("passed");
				expect(result2).toBe("passed");
				expect(result3).toInclude("Rate limit exceeded");
			});

			it("tokenBucket + database enforces the limit", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "tokenBucket",
					storage = "database"
				);
				var nextFn = function(req) {
					return "passed";
				};
				var clientKey = "rl-db-bucket-#CreateUUID()#";

				var result1 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result2 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);
				var result3 = limiter.handle(request = {remoteAddr: clientKey}, next = nextFn);

				expect(result1).toBe("passed");
				expect(result2).toBe("passed");
				expect(result3).toInclude("Rate limit exceeded");
			});

			it("fails closed when the table is unavailable and failOpen is false", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					storage = "database",
					failOpen = false
				);
				prepareMock(limiter);
				limiter.$property(propertyName = "datasourceResolved", propertyScope = "variables", mock = true);
				limiter.$property(propertyName = "resolvedDatasource", propertyScope = "variables", mock = "wheels_bogus_dsn_#Left(CreateUUID(), 8)#");

				var nextFn = function(req) {
					return "passed";
				};
				var state = {blocked: "", errored: false};
				try {
					state.blocked = limiter.handle(request = {remoteAddr: "rl-db-closed-#CreateUUID()#"}, next = nextFn);
				} catch (any e) {
					state.errored = true;
				}

				expect(state.errored).toBeFalse();
				expect(state.blocked).toInclude("Rate limit exceeded");
			});

			it("fails open when the table is unavailable and failOpen is true", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					storage = "database",
					failOpen = true
				);
				prepareMock(limiter);
				limiter.$property(propertyName = "datasourceResolved", propertyScope = "variables", mock = true);
				limiter.$property(propertyName = "resolvedDatasource", propertyScope = "variables", mock = "wheels_bogus_dsn_#Left(CreateUUID(), 8)#");

				var nextFn = function(req) {
					return "passed";
				};
				var state = {result: "", errored: false};
				try {
					state.result = limiter.handle(request = {remoteAddr: "rl-db-open-#CreateUUID()#"}, next = nextFn);
				} catch (any e) {
					state.errored = true;
				}

				expect(state.errored).toBeFalse();
				expect(state.result).toBe("passed");
			});
		});
	}

	/**
	 * Remove every row from wheels_rate_limits so tests are isolated.
	 * The table may not exist yet on a clean database — that's fine.
	 */
	private void function $cleanRateLimitRows() {
		try {
			QueryExecute(
				"DELETE FROM wheels_rate_limits",
				{},
				{datasource: application.wheels.dataSourceName}
			);
		} catch (any e) {
			// Table doesn't exist yet — nothing to clean.
		}
	}

}
