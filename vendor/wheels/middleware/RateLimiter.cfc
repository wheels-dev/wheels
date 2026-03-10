/**
 * Rate limiting middleware for controlling request throughput.
 * Supports fixed window, sliding window, and token bucket strategies
 * with in-memory or database-backed storage.
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	/**
	 * Creates the RateLimiter middleware with configurable options.
	 *
	 * @maxRequests Maximum number of requests allowed per window.
	 * @windowSeconds Duration of the rate limit window in seconds.
	 * @strategy Algorithm: "fixedWindow", "slidingWindow", or "tokenBucket".
	 * @storage Backend: "memory" or "database".
	 * @keyFunction Closure that receives the request struct and returns a string key. Defaults to client IP.
	 * @headerPrefix Prefix for rate limit response headers.
	 * @trustProxy Whether to use X-Forwarded-For for client IP resolution.
	 */
	public RateLimiter function init(
		numeric maxRequests = 60,
		numeric windowSeconds = 60,
		string strategy = "fixedWindow",
		string storage = "memory",
		any keyFunction = "",
		string headerPrefix = "X-RateLimit",
		boolean trustProxy = true
	) {
		if (!ListFindNoCase("fixedWindow,slidingWindow,tokenBucket", arguments.strategy)) {
			throw(
				type = "Wheels.RateLimiter.InvalidStrategy",
				message = "Invalid rate limiter strategy: #arguments.strategy#. Must be fixedWindow, slidingWindow, or tokenBucket."
			);
		}

		if (!ListFindNoCase("memory,database", arguments.storage)) {
			throw(
				type = "Wheels.RateLimiter.InvalidStorage",
				message = "Invalid rate limiter storage: #arguments.storage#. Must be memory or database."
			);
		}

		variables.maxRequests = arguments.maxRequests;
		variables.windowSeconds = arguments.windowSeconds;
		variables.strategy = arguments.strategy;
		variables.storage = arguments.storage;
		variables.keyFunction = arguments.keyFunction;
		variables.headerPrefix = arguments.headerPrefix;
		variables.trustProxy = arguments.trustProxy;

		// In-memory store using ConcurrentHashMap for thread safety.
		if (variables.storage == "memory") {
			variables.store = CreateObject("java", "java.util.concurrent.ConcurrentHashMap").init();
		}

		// Throttle cleanup to once per minute.
		variables.lastCleanup = 0;

		// Track whether DB table has been verified.
		variables.tableVerified = false;

		return this;
	}

	/**
	 * Handle the incoming request — check rate limit, set headers, and either pass through or block.
	 */
	public string function handle(required struct request, required any next) {
		local.clientKey = $resolveKey(arguments.request);
		local.now = GetTickCount() / 1000;

		// Periodic cleanup for memory storage.
		if (variables.storage == "memory") {
			$maybeCleanup(local.now);
		}

		// Check rate limit based on strategy.
		switch (variables.strategy) {
			case "fixedWindow":
				local.result = $checkFixedWindow(local.clientKey, local.now);
				break;
			case "slidingWindow":
				local.result = $checkSlidingWindow(local.clientKey, local.now);
				break;
			case "tokenBucket":
				local.result = $checkTokenBucket(local.clientKey, local.now);
				break;
		}

		// Set rate limit headers.
		try {
			cfheader(name = "#variables.headerPrefix#-Limit", value = variables.maxRequests);
			cfheader(name = "#variables.headerPrefix#-Remaining", value = Max(0, local.result.remaining));
			cfheader(name = "#variables.headerPrefix#-Reset", value = Ceiling(local.result.resetAt));
		} catch (any e) {
		}

		// Block if over limit.
		if (!local.result.allowed) {
			try {
				cfheader(statusCode = "429", statusText = "Too Many Requests");
				cfheader(name = "Retry-After", value = Ceiling(local.result.resetAt - local.now));
			} catch (any e) {
			}
			return "Rate limit exceeded. Try again later.";
		}

		return arguments.next(arguments.request);
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Resolve the client key from the request — uses keyFunction if provided, otherwise client IP.
	 */
	private string function $resolveKey(required struct request) {
		if (IsCustomFunction(variables.keyFunction) || IsClosure(variables.keyFunction)) {
			return variables.keyFunction(arguments.request);
		}
		return $getClientIp(arguments.request);
	}

	/**
	 * Get the client IP address from the request, respecting proxy headers if configured.
	 */
	private string function $getClientIp(required struct request) {
		// Check request struct first (test-friendly).
		if (StructKeyExists(arguments.request, "remoteAddr")) {
			return arguments.request.remoteAddr;
		}

		// Trust proxy: check X-Forwarded-For header.
		if (variables.trustProxy) {
			try {
				local.forwarded = "";
				if (StructKeyExists(arguments.request, "cgi") && StructKeyExists(arguments.request.cgi, "http_x_forwarded_for")) {
					local.forwarded = arguments.request.cgi.http_x_forwarded_for;
				} else {
					local.forwarded = cgi.http_x_forwarded_for;
				}
				if (Len(Trim(local.forwarded))) {
					return Trim(ListFirst(local.forwarded));
				}
			} catch (any e) {
			}
		}

		// Fall back to CGI remote_addr.
		try {
			if (StructKeyExists(arguments.request, "cgi") && StructKeyExists(arguments.request.cgi, "remote_addr")) {
				return arguments.request.cgi.remote_addr;
			}
			return cgi.remote_addr;
		} catch (any e) {
		}

		return "unknown";
	}

	// ---------------------------------------------------------------------------
	// Fixed Window Strategy
	// ---------------------------------------------------------------------------

	/**
	 * Fixed window: discrete time buckets. Simple counter per window ID.
	 */
	private struct function $checkFixedWindow(required string clientKey, required numeric now) {
		local.windowId = Int(arguments.now / variables.windowSeconds);
		local.storeKey = arguments.clientKey & ":" & local.windowId;
		local.resetAt = (local.windowId + 1) * variables.windowSeconds;

		if (variables.storage == "database") {
			return $dbIncrement(arguments.clientKey, local.storeKey, local.resetAt);
		}

		// In-memory with per-key locking.
		local.allowed = true;
		local.remaining = variables.maxRequests;

		try {
			cflock(name = "wheels-ratelimit-#local.storeKey#", type = "exclusive", timeout = 1) {
				local.count = 0;
				if (variables.store.containsKey(local.storeKey)) {
					local.count = variables.store.get(local.storeKey);
				}
				if (local.count >= variables.maxRequests) {
					local.allowed = false;
					local.remaining = 0;
				} else {
					local.count++;
					variables.store.put(local.storeKey, local.count);
					local.remaining = variables.maxRequests - local.count;
				}
			}
		} catch (any e) {
			// Fail open on lock timeout.
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: local.resetAt};
	}

	// ---------------------------------------------------------------------------
	// Sliding Window Strategy
	// ---------------------------------------------------------------------------

	/**
	 * Sliding window: maintains a timestamp log per client. More accurate but uses more memory.
	 */
	private struct function $checkSlidingWindow(required string clientKey, required numeric now) {
		local.windowStart = arguments.now - variables.windowSeconds;
		local.resetAt = arguments.now + variables.windowSeconds;

		if (variables.storage == "database") {
			return $dbSlidingWindow(arguments.clientKey, arguments.now, local.windowStart, local.resetAt);
		}

		local.allowed = true;
		local.remaining = variables.maxRequests;

		try {
			cflock(name = "wheels-ratelimit-#arguments.clientKey#", type = "exclusive", timeout = 1) {
				// Get or create timestamp array.
				local.timestamps = [];
				if (variables.store.containsKey(arguments.clientKey)) {
					local.timestamps = variables.store.get(arguments.clientKey);
				}

				// Prune expired entries.
				local.pruned = [];
				for (local.ts in local.timestamps) {
					if (local.ts > local.windowStart) {
						ArrayAppend(local.pruned, local.ts);
					}
				}

				if (ArrayLen(local.pruned) >= variables.maxRequests) {
					local.allowed = false;
					local.remaining = 0;
					// Update resetAt to when the oldest entry expires.
					if (ArrayLen(local.pruned) > 0) {
						local.resetAt = local.pruned[1] + variables.windowSeconds;
					}
				} else {
					ArrayAppend(local.pruned, arguments.now);
					local.remaining = variables.maxRequests - ArrayLen(local.pruned);
				}

				variables.store.put(arguments.clientKey, local.pruned);
			}
		} catch (any e) {
			// Fail open on lock timeout.
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: local.resetAt};
	}

	// ---------------------------------------------------------------------------
	// Token Bucket Strategy
	// ---------------------------------------------------------------------------

	/**
	 * Token bucket: allows bursts up to capacity, refills at a steady rate.
	 */
	private struct function $checkTokenBucket(required string clientKey, required numeric now) {
		local.refillRate = variables.maxRequests / variables.windowSeconds;
		local.resetAt = arguments.now + (1 / local.refillRate);

		if (variables.storage == "database") {
			return $dbTokenBucket(arguments.clientKey, arguments.now, local.refillRate, local.resetAt);
		}

		local.allowed = true;
		local.remaining = variables.maxRequests;

		try {
			cflock(name = "wheels-ratelimit-#arguments.clientKey#", type = "exclusive", timeout = 1) {
				local.bucket = {};
				if (variables.store.containsKey(arguments.clientKey)) {
					local.bucket = variables.store.get(arguments.clientKey);
				} else {
					local.bucket = {tokens: variables.maxRequests, lastRefill: arguments.now};
				}

				// Refill tokens based on elapsed time.
				local.elapsed = arguments.now - local.bucket.lastRefill;
				local.newTokens = local.elapsed * local.refillRate;
				local.bucket.tokens = Min(variables.maxRequests, local.bucket.tokens + local.newTokens);
				local.bucket.lastRefill = arguments.now;

				if (local.bucket.tokens < 1) {
					local.allowed = false;
					local.remaining = 0;
					// Time until one token is available.
					local.resetAt = arguments.now + ((1 - local.bucket.tokens) / local.refillRate);
				} else {
					local.bucket.tokens -= 1;
					local.remaining = Int(local.bucket.tokens);
				}

				variables.store.put(arguments.clientKey, local.bucket);
			}
		} catch (any e) {
			// Fail open on lock timeout.
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: local.resetAt};
	}

	// ---------------------------------------------------------------------------
	// Memory Cleanup
	// ---------------------------------------------------------------------------

	/**
	 * Periodically clean up stale entries from in-memory store (throttled to once per minute).
	 */
	private void function $maybeCleanup(required numeric now) {
		if ((arguments.now - variables.lastCleanup) < 60) {
			return;
		}

		try {
			cflock(name = "wheels-ratelimit-cleanup", type = "exclusive", timeout = 1) {
				// Double-check after acquiring lock.
				if ((arguments.now - variables.lastCleanup) < 60) {
					return;
				}
				variables.lastCleanup = arguments.now;

				local.currentWindowId = Int(arguments.now / variables.windowSeconds);
				local.keysToRemove = [];
				local.keys = variables.store.keySet().toArray();

				for (local.key in local.keys) {
					local.value = "";
					if (variables.store.containsKey(local.key)) {
						local.value = variables.store.get(local.key);
					}

					// Fixed window: key format is "clientKey:windowId" — remove old windows.
					if (variables.strategy == "fixedWindow" && Find(":", local.key)) {
						local.windowId = Val(ListLast(local.key, ":"));
						if (local.windowId < local.currentWindowId) {
							ArrayAppend(local.keysToRemove, local.key);
						}
					}

					// Sliding window: remove clients with all timestamps expired.
					if (variables.strategy == "slidingWindow" && IsArray(local.value)) {
						local.windowStart = arguments.now - variables.windowSeconds;
						local.hasValid = false;
						for (local.ts in local.value) {
							if (local.ts > local.windowStart) {
								local.hasValid = true;
								break;
							}
						}
						if (!local.hasValid) {
							ArrayAppend(local.keysToRemove, local.key);
						}
					}

					// Token bucket: remove fully-refilled buckets (idle clients).
					if (variables.strategy == "tokenBucket" && IsStruct(local.value) && StructKeyExists(local.value, "tokens")) {
						if (local.value.tokens >= variables.maxRequests && (arguments.now - local.value.lastRefill) > variables.windowSeconds) {
							ArrayAppend(local.keysToRemove, local.key);
						}
					}
				}

				for (local.key in local.keysToRemove) {
					variables.store.remove(local.key);
				}
			}
		} catch (any e) {
			// Lock timeout or error — skip cleanup this time.
		}
	}

	// ---------------------------------------------------------------------------
	// Database Storage
	// ---------------------------------------------------------------------------

	/**
	 * Database-backed fixed window increment.
	 */
	private struct function $dbIncrement(required string clientKey, required string storeKey, required numeric resetAt) {
		$ensureTable();

		local.allowed = true;
		local.remaining = variables.maxRequests;

		try {
			// Try to insert a new row.
			QueryExecute(
				"INSERT INTO wheels_rate_limits (store_key, counter, expires_at) VALUES (:storeKey, 1, :expiresAt)",
				{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}, expiresAt: {value: DateAdd("s", variables.windowSeconds, Now()), cfsqltype: "cf_sql_timestamp"}}
			);
			local.remaining = variables.maxRequests - 1;
		} catch (any e) {
			// Row exists — update the counter.
			try {
				local.qUpdate = QueryExecute(
					"UPDATE wheels_rate_limits SET counter = counter + 1 WHERE store_key = :storeKey",
					{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}}
				);
				// Read current count.
				local.qCount = QueryExecute(
					"SELECT counter FROM wheels_rate_limits WHERE store_key = :storeKey",
					{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}}
				);
				if (local.qCount.recordCount && local.qCount.counter > variables.maxRequests) {
					local.allowed = false;
					local.remaining = 0;
				} else if (local.qCount.recordCount) {
					local.remaining = variables.maxRequests - local.qCount.counter;
				}
			} catch (any e2) {
				// Fail open.
			}
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: arguments.resetAt};
	}

	/**
	 * Database-backed sliding window check.
	 */
	private struct function $dbSlidingWindow(required string clientKey, required numeric now, required numeric windowStart, required numeric resetAt) {
		$ensureTable();

		local.allowed = true;
		local.remaining = variables.maxRequests;
		local.expiresAt = DateAdd("s", variables.windowSeconds, Now());

		try {
			// Clean expired entries for this client.
			QueryExecute(
				"DELETE FROM wheels_rate_limits WHERE store_key = :clientKey AND expires_at < :now",
				{clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}, now: {value: Now(), cfsqltype: "cf_sql_timestamp"}}
			);

			// Count current entries.
			local.qCount = QueryExecute(
				"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE store_key = :clientKey",
				{clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}}
			);

			if (local.qCount.cnt >= variables.maxRequests) {
				local.allowed = false;
				local.remaining = 0;
			} else {
				// Insert a new timestamp entry.
				QueryExecute(
					"INSERT INTO wheels_rate_limits (store_key, counter, expires_at) VALUES (:clientKey, 1, :expiresAt)",
					{clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}, expiresAt: {value: local.expiresAt, cfsqltype: "cf_sql_timestamp"}}
				);
				local.remaining = variables.maxRequests - local.qCount.cnt - 1;
			}
		} catch (any e) {
			// Fail open.
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: arguments.resetAt};
	}

	/**
	 * Database-backed token bucket check.
	 */
	private struct function $dbTokenBucket(required string clientKey, required numeric now, required numeric refillRate, required numeric resetAt) {
		$ensureTable();

		local.allowed = true;
		local.remaining = variables.maxRequests;

		try {
			local.qBucket = QueryExecute(
				"SELECT counter, expires_at FROM wheels_rate_limits WHERE store_key = :clientKey",
				{clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}}
			);

			if (local.qBucket.recordCount) {
				// Calculate token refill.
				local.lastRefill = local.qBucket.expires_at;
				local.elapsed = DateDiff("s", local.lastRefill, Now());
				local.currentTokens = Min(variables.maxRequests, local.qBucket.counter + (local.elapsed * arguments.refillRate));

				if (local.currentTokens < 1) {
					local.allowed = false;
					local.remaining = 0;
				} else {
					local.currentTokens -= 1;
					local.remaining = Int(local.currentTokens);
					QueryExecute(
						"UPDATE wheels_rate_limits SET counter = :tokens, expires_at = :now WHERE store_key = :clientKey",
						{
							tokens: {value: Int(local.currentTokens), cfsqltype: "cf_sql_integer"},
							now: {value: Now(), cfsqltype: "cf_sql_timestamp"},
							clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}
						}
					);
				}
			} else {
				// First request — create bucket with maxRequests - 1 tokens.
				local.remaining = variables.maxRequests - 1;
				QueryExecute(
					"INSERT INTO wheels_rate_limits (store_key, counter, expires_at) VALUES (:clientKey, :tokens, :now)",
					{
						clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"},
						tokens: {value: local.remaining, cfsqltype: "cf_sql_integer"},
						now: {value: Now(), cfsqltype: "cf_sql_timestamp"}
					}
				);
			}
		} catch (any e) {
			// Fail open.
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: arguments.resetAt};
	}

	/**
	 * Auto-create the wheels_rate_limits table if it doesn't exist.
	 */
	private void function $ensureTable() {
		if (variables.tableVerified) {
			return;
		}

		try {
			QueryExecute(
				"CREATE TABLE IF NOT EXISTS wheels_rate_limits (
					id INT AUTO_INCREMENT PRIMARY KEY,
					store_key VARCHAR(255) NOT NULL,
					counter INT DEFAULT 1,
					expires_at TIMESTAMP,
					INDEX idx_store_key (store_key),
					INDEX idx_expires_at (expires_at)
				)"
			);
		} catch (any e) {
			// Table may already exist or DB doesn't support IF NOT EXISTS — that's fine.
		}

		variables.tableVerified = true;
	}

}
