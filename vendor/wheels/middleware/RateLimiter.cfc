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
	 * @trustProxy Whether to use X-Forwarded-For for client IP resolution. Defaults to false for security.
	 *   WARNING: Only enable this when your application sits behind a trusted reverse proxy (e.g. nginx,
	 *   HAProxy, AWS ALB) that strips or overwrites the X-Forwarded-For header from downstream clients.
	 *   Without a proxy that sanitizes this header, any client can spoof arbitrary IPs to bypass rate
	 *   limiting entirely. Your proxy MUST be configured to either: (a) drop incoming X-Forwarded-For and
	 *   set it to the real client IP, or (b) append the client IP so the rightmost entry is trustworthy.
	 *   If your proxy appends, set proxyStrategy="last" to use the rightmost (proxy-added) IP.
	 * @proxyStrategy Which IP to extract from X-Forwarded-For: "first" (leftmost, client-supplied — default
	 *   for backwards compatibility) or "last" (rightmost, added by the nearest trusted proxy — recommended
	 *   when the proxy appends rather than overwrites the header).
	 * @maxStoreSize Maximum number of entries allowed in the in-memory store. When exceeded during cleanup,
	 *   the oldest entries are evicted. Prevents unbounded memory growth from attackers rotating client keys.
	 *   Only applies when storage="memory". Default: 100000.
	 * @maxTimestampsPerKey Maximum number of timestamps stored per client key in the sliding window strategy.
	 *   Prevents a single attacker from exhausting heap memory by making rapid requests. After pruning expired
	 *   entries, arrays exceeding this limit are truncated to keep only the most recent timestamps.
	 *   Default: maxRequests * 3. Only applies to the "slidingWindow" strategy with storage="memory".
	 * @maxKeyLength Maximum length of a client key before it is replaced with a SHA-256 hash.
	 *   Prevents unbounded memory consumption from attackers supplying arbitrarily long keys
	 *   (e.g., via long X-Forwarded-For chains or custom key functions). Default: 128.
	 * @failOpen When true, requests are allowed through if the rate limiter lock times out.
	 *   Default false (fail-closed, secure by default). Set to true if availability
	 *   is more important than strict rate enforcement.
	 */
	public RateLimiter function init(
		numeric maxRequests = 60,
		numeric windowSeconds = 60,
		string strategy = "fixedWindow",
		string storage = "memory",
		any keyFunction = "",
		string headerPrefix = "X-RateLimit",
		boolean trustProxy = false,
		string proxyStrategy = "first",
		numeric maxStoreSize = 100000,
		numeric maxTimestampsPerKey = 0,
		numeric maxKeyLength = 128,
		boolean failOpen = false
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

		if (!ListFindNoCase("first,last", arguments.proxyStrategy)) {
			throw(
				type = "Wheels.RateLimiter.InvalidProxyStrategy",
				message = "Invalid proxy strategy: #arguments.proxyStrategy#. Must be first or last."
			);
		}

		variables.maxRequests = arguments.maxRequests;
		variables.windowSeconds = arguments.windowSeconds;
		variables.strategy = arguments.strategy;
		variables.storage = arguments.storage;
		variables.keyFunction = arguments.keyFunction;
		variables.headerPrefix = arguments.headerPrefix;
		variables.trustProxy = arguments.trustProxy;
		variables.proxyStrategy = arguments.proxyStrategy;
		variables.maxStoreSize = arguments.maxStoreSize;
		variables.maxTimestampsPerKey = arguments.maxTimestampsPerKey > 0 ? arguments.maxTimestampsPerKey : arguments.maxRequests * 3;
		variables.maxKeyLength = arguments.maxKeyLength;
		variables.failOpen = arguments.failOpen;

		// In-memory store using ConcurrentHashMap for thread safety.
		if (variables.storage == "memory") {
			variables.store = CreateObject("java", "java.util.concurrent.ConcurrentHashMap").init();
		}

		// Throttle cleanup interval in seconds.
		variables.cleanupThrottleSeconds = 10;
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
			// Emergency eviction if store is at capacity and this is a new key.
			if (variables.store.size() >= variables.maxStoreSize && !variables.store.containsKey(local.clientKey)) {
				$evictOldest(local.now);
			}
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
				cfheader(statusCode = "429");
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
	 * Keys exceeding maxKeyLength are replaced with their SHA-256 hash to bound memory usage.
	 */
	private string function $resolveKey(required struct request) {
		if (IsCustomFunction(variables.keyFunction) || IsClosure(variables.keyFunction)) {
			local.key = variables.keyFunction(arguments.request);
		} else {
			local.key = $getClientIp(arguments.request);
		}

		if (Len(local.key) > variables.maxKeyLength) {
			local.key = Hash(local.key, "SHA-256");
		}

		return local.key;
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
					if (variables.proxyStrategy == "last") {
						return Trim(ListLast(local.forwarded));
					}
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

	/**
	 * Handle a rate limiter error (lock timeout or DB failure) according to the failOpen setting.
	 * Returns a struct with `allowed` and `remaining` reflecting the decision.
	 */
	private struct function $handleError(required string context, required string clientKey) {
		local.mode = variables.failOpen ? "fail-open" : "fail-closed";
		writeLog(
			text = "Rate limiter #arguments.context# (#local.mode#) for key: #arguments.clientKey#",
			type = "warning",
			file = "wheels_ratelimiter"
		);
		return {
			allowed: variables.failOpen,
			remaining: 0
		};
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
			local.err = $handleError("lock timeout", local.storeKey);
			local.allowed = local.err.allowed;
			local.remaining = local.err.remaining;
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

				// Cap per-key array size to prevent memory exhaustion from rapid requests.
				if (ArrayLen(local.pruned) > variables.maxTimestampsPerKey) {
					local.pruned = local.pruned.slice(ArrayLen(local.pruned) - variables.maxTimestampsPerKey + 1);
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
			local.err = $handleError("lock timeout", arguments.clientKey);
			local.allowed = local.err.allowed;
			local.remaining = local.err.remaining;
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
			local.err = $handleError("lock timeout", arguments.clientKey);
			local.allowed = local.err.allowed;
			local.remaining = local.err.remaining;
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: local.resetAt};
	}

	// ---------------------------------------------------------------------------
	// Memory Cleanup
	// ---------------------------------------------------------------------------

	/**
	 * Periodically clean up stale entries from in-memory store (throttled to once per cleanupThrottleSeconds).
	 */
	private void function $maybeCleanup(required numeric now) {
		if ((arguments.now - variables.lastCleanup) < variables.cleanupThrottleSeconds) {
			return;
		}

		try {
			cflock(name = "wheels-ratelimit-cleanup", type = "exclusive", timeout = 1) {
				// Double-check after acquiring lock.
				if ((arguments.now - variables.lastCleanup) < variables.cleanupThrottleSeconds) {
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

				// If store still exceeds maxStoreSize after expiry cleanup, evict oldest entries.
				if (variables.store.size() > variables.maxStoreSize) {
					$evictOldest(arguments.now);
				}
			}
		} catch (any e) {
			// Lock timeout or error — skip cleanup this time.
		}
	}

	/**
	 * Evict entries from the in-memory store when it exceeds maxStoreSize.
	 * First removes fully expired entries, then evicts the oldest 25% to create headroom.
	 * Entries whose age cannot be determined score 0 (youngest) and are evicted last.
	 */
	private void function $evictOldest(required numeric now) {
		try {
			local.keys = variables.store.keySet().toArray();
			local.storeSize = ArrayLen(local.keys);
			local.targetSize = Int(variables.maxStoreSize * 0.75);
			local.toEvict = local.storeSize - local.targetSize;

			if (local.toEvict <= 0) {
				return;
			}

			// First pass: remove fully expired entries (cheap, no sorting needed).
			local.currentWindowId = Int(arguments.now / variables.windowSeconds);
			local.windowStart = arguments.now - variables.windowSeconds;
			local.expiredCount = 0;
			for (local.key in local.keys) {
				if (local.expiredCount >= local.toEvict) {
					break;
				}
				if (variables.store.containsKey(local.key)) {
					local.value = variables.store.get(local.key);
					local.isExpired = false;

					if (variables.strategy == "fixedWindow" && Find(":", local.key)) {
						local.windowId = Val(ListLast(local.key, ":"));
						local.isExpired = local.windowId < local.currentWindowId;
					} else if (variables.strategy == "slidingWindow" && IsArray(local.value)) {
						if (ArrayLen(local.value) == 0) {
							local.isExpired = true;
						} else {
							// Expired if newest timestamp is outside the window.
							local.isExpired = local.value[ArrayLen(local.value)] <= local.windowStart;
						}
					} else if (variables.strategy == "tokenBucket" && IsStruct(local.value) && StructKeyExists(local.value, "tokens")) {
						local.isExpired = local.value.tokens >= variables.maxRequests && (arguments.now - local.value.lastRefill) > variables.windowSeconds;
					}

					if (local.isExpired) {
						variables.store.remove(local.key);
						local.expiredCount++;
					}
				}
			}

			// If expired-entry removal was sufficient, skip the expensive sort.
			if (local.expiredCount >= local.toEvict) {
				return;
			}

			// Second pass: sort remaining entries by age and evict oldest.
			local.remainingToEvict = local.toEvict - local.expiredCount;
			local.keys = variables.store.keySet().toArray();
			local.entries = [];
			for (local.key in local.keys) {
				local.age = 0;
				if (variables.store.containsKey(local.key)) {
					local.value = variables.store.get(local.key);

					if (variables.strategy == "fixedWindow" && Find(":", local.key)) {
						local.windowId = Val(ListLast(local.key, ":"));
						local.age = local.currentWindowId - local.windowId;
					} else if (variables.strategy == "slidingWindow" && IsArray(local.value) && ArrayLen(local.value) > 0) {
						local.age = arguments.now - local.value[1];
					} else if (variables.strategy == "tokenBucket" && IsStruct(local.value) && StructKeyExists(local.value, "lastRefill")) {
						local.age = arguments.now - local.value.lastRefill;
					}
				}
				ArrayAppend(local.entries, {key: local.key, age: local.age});
			}

			// Sort by age descending (oldest first).
			ArraySort(local.entries, function(a, b) {
				return (b.age < a.age) ? -1 : ((b.age > a.age) ? 1 : 0);
			});

			// Evict the oldest entries.
			local.evicted = 0;
			for (local.entry in local.entries) {
				if (local.evicted >= local.remainingToEvict) {
					break;
				}
				variables.store.remove(local.entry.key);
				local.evicted++;
			}
		} catch (any e) {
			// Best-effort eviction — don't let errors propagate.
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
				local.err = $handleError("DB error", arguments.clientKey);
				local.allowed = local.err.allowed;
				local.remaining = local.err.remaining;
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
			local.err = $handleError("DB error", arguments.clientKey);
			local.allowed = local.err.allowed;
			local.remaining = local.err.remaining;
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
			local.err = $handleError("DB error", arguments.clientKey);
			local.allowed = local.err.allowed;
			local.remaining = local.err.remaining;
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
