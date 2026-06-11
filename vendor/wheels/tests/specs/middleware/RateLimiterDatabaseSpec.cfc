/**
 * Tests for RateLimiter middleware with storage="database".
 * Covers enforcement for all three strategies, single-row counter accumulation,
 * portable table auto-creation (schema v2 with row_type/client_key and a
 * UNIQUE store_key index), the automatic v1-to-v2 upgrade path, expired-row
 * purging, and failOpen behavior when the table is unavailable.
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

				// Schema v2 tags counter rows with row_type='counter' and stores the
				// raw client key in client_key (store_key is "c:<clientKey>:<windowId>").
				var qRows = QueryExecute(
					"SELECT COUNT(*) AS rowTotal, MAX(counter) AS maxCounter FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'counter'",
					{clientKey: {value: clientKey, cfsqltype: "cf_sql_varchar"}},
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
					"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, 'counter', 1, :expiresAt)",
					{
						storeKey: {value: staleKey, cfsqltype: "cf_sql_varchar"},
						clientKey: {value: staleKey, cfsqltype: "cf_sql_varchar"},
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
				// Sliding window stores one row per request; under schema v2 each
				// event row gets a synthetic UUID-suffixed store_key so the
				// UNIQUE(store_key) index holds for every strategy.
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

		describe("RateLimiter database storage — schema v2 and upgrade", function() {

			afterEach(function() {
				$cleanRateLimitRows();
			});

			it("creates the v2 schema with row_type and client_key columns", function() {
				var dsOpts = {datasource: application.wheels.dataSourceName};
				try {
					QueryExecute("DROP TABLE wheels_rate_limits", {}, dsOpts);
				} catch (any e) {
					// Table didn't exist — fine.
				}

				var keyFn = function(req) {
					return "v2-schema-client";
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 3600,
					strategy = "fixedWindow",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var handler = function(required struct request) {
					return "ok";
				};

				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toBe("ok");

				// The freshly auto-created table must expose the v2 discriminator columns.
				var probe = {threw: false};
				try {
					QueryExecute("SELECT row_type, client_key FROM wheels_rate_limits WHERE 1=0", {}, dsOpts);
				} catch (any e) {
					probe.threw = true;
				}
				expect(probe.threw).toBeFalse();
			});

			it("enforces unique store_key at the database level", function() {
				var dsOpts = {datasource: application.wheels.dataSourceName};

				// Make sure the limiter has (re)created the v2 table.
				var keyFn = function(req) {
					return "uq-setup-client";
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 3600,
					strategy = "fixedWindow",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var handler = function(required struct request) {
					return "ok";
				};
				pipeline.run(request = {}, coreHandler = handler);

				var probeKey = "uq-probe-#CreateUUID()#";
				QueryExecute(
					"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, 't', 'counter', 1, :expiresAt)",
					{
						storeKey: {value: probeKey, cfsqltype: "cf_sql_varchar"},
						expiresAt: {value: DateAdd("s", 3600, Now()), cfsqltype: "cf_sql_timestamp"}
					},
					dsOpts
				);

				// A second insert with the same store_key must violate the UNIQUE index.
				var dup = {threw: false};
				try {
					QueryExecute(
						"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, 't', 'counter', 1, :expiresAt)",
						{
							storeKey: {value: probeKey, cfsqltype: "cf_sql_varchar"},
							expiresAt: {value: DateAdd("s", 3600, Now()), cfsqltype: "cf_sql_timestamp"}
						},
						dsOpts
					);
				} catch (any e) {
					dup.threw = true;
				}
				expect(dup.threw).toBeTrue();
			});

			it("upgrades a legacy wheels_rate_limits table to the v2 schema without breaking enforcement", function() {
				var dsOpts = {datasource: application.wheels.dataSourceName};
				try {
					QueryExecute("DROP TABLE wheels_rate_limits", {}, dsOpts);
				} catch (any e) {
					// Table didn't exist — fine.
				}

				// Recreate the v1 shape (no client_key/row_type, no unique index).
				// PostgreSQL/Oracle reject DATETIME — retry with TIMESTAMP.
				var ddl = {needRetry: false};
				try {
					QueryExecute(
						"CREATE TABLE wheels_rate_limits (store_key VARCHAR(255) NOT NULL, counter INT, expires_at DATETIME)",
						{},
						dsOpts
					);
				} catch (any e) {
					ddl.needRetry = true;
				}
				if (ddl.needRetry) {
					QueryExecute(
						"CREATE TABLE wheels_rate_limits (store_key VARCHAR(255) NOT NULL, counter INT, expires_at TIMESTAMP)",
						{},
						dsOpts
					);
				}

				var legacyKey = "legacy-row-#CreateUUID()#";
				QueryExecute(
					"INSERT INTO wheels_rate_limits (store_key, counter, expires_at) VALUES (:storeKey, 7, :expiresAt)",
					{
						storeKey: {value: legacyKey, cfsqltype: "cf_sql_varchar"},
						expiresAt: {value: DateAdd("s", 3600, Now()), cfsqltype: "cf_sql_timestamp"}
					},
					dsOpts
				);

				var clientKey = "upgrade-client-#CreateUUID()#";
				var keyFn = function(req) {
					return clientKey;
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 3600,
					strategy = "fixedWindow",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				var r1 = pipeline.run(request = {}, coreHandler = handler);
				var r2 = pipeline.run(request = {}, coreHandler = handler);
				var r3 = pipeline.run(request = {}, coreHandler = handler);

				// Enforcement must survive the upgrade: 2 allowed, third blocked.
				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
				expect(r3).toInclude("Rate limit exceeded");
				expect(shared.callCount).toBe(2);

				// The table must now be schema v2.
				var probe = {threw: false};
				try {
					QueryExecute("SELECT row_type FROM wheels_rate_limits WHERE 1=0", {}, dsOpts);
				} catch (any e) {
					probe.threw = true;
				}
				expect(probe.threw).toBeFalse();

				// The legacy row was dropped with the v1 table (no copy-migration).
				var qLegacy = QueryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE store_key = :storeKey",
					{storeKey: {value: legacyKey, cfsqltype: "cf_sql_varchar"}},
					dsOpts
				);
				expect(qLegacy.cnt).toBe(0);
			});

		});

		describe("RateLimiter database storage — enforcement and locking", function() {

			afterEach(function() {
				$cleanRateLimitRows();
			});

			it("enforces fixedWindow limits across requests with storage=database", function() {
				var clientKey = "fw-db-enforce-#CreateUUID()#";
				var keyFn = function(req) {
					return clientKey;
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 3600,
					strategy = "fixedWindow",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				var lastResult = "";
				for (var i = 1; i <= 5; i++) {
					lastResult = pipeline.run(request = {}, coreHandler = handler);
				}

				expect(shared.callCount).toBe(3);
				expect(lastResult).toInclude("Rate limit exceeded");
			});

			it("keeps exactly one counter row per window for fixedWindow", function() {
				var clientKey = "fw-db-onerow-#CreateUUID()#";
				var keyFn = function(req) {
					return clientKey;
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 3600,
					strategy = "fixedWindow",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var handler = function(required struct request) {
					return "ok";
				};

				for (var i = 1; i <= 5; i++) {
					pipeline.run(request = {}, coreHandler = handler);
				}

				// Counter rows are upserted, never duplicated — exactly one row per
				// (client, window) pair regardless of how many requests arrive.
				var qRows = QueryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'counter'",
					{clientKey: {value: clientKey, cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(qRows.cnt).toBe(1);
			});

			it("enforces slidingWindow limits with storage=database and tags event rows", function() {
				var clientKey = "sw-db-enforce-#CreateUUID()#";
				var keyFn = function(req) {
					return clientKey;
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 3600,
					strategy = "slidingWindow",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 5; i++) {
					pipeline.run(request = {}, coreHandler = handler);
				}

				expect(shared.callCount).toBe(3);

				var dsOpts = {datasource: application.wheels.dataSourceName};
				var qEvents = QueryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'event'",
					{clientKey: {value: clientKey, cfsqltype: "cf_sql_varchar"}},
					dsOpts
				);
				expect(qEvents.cnt).toBe(3);

				// Exactly one lockable anchor row per client serializes the
				// read-modify-write sequence across nodes.
				var qAnchor = QueryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'anchor'",
					{clientKey: {value: clientKey, cfsqltype: "cf_sql_varchar"}},
					dsOpts
				);
				expect(qAnchor.cnt).toBe(1);
			});

			it("enforces tokenBucket limits with storage=database", function() {
				var clientKey = "tb-db-enforce-#CreateUUID()#";
				var keyFn = function(req) {
					return clientKey;
				};
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 3600,
					strategy = "tokenBucket",
					storage = "database",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 4; i++) {
					pipeline.run(request = {}, coreHandler = handler);
				}

				expect(shared.callCount).toBe(2);

				var qBucket = QueryExecute(
					"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'bucket'",
					{clientKey: {value: clientKey, cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(qBucket.cnt).toBe(1);
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
