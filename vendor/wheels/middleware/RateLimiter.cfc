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
	 *   If your proxy appends, the default proxyStrategy="last" uses the rightmost (proxy-added) IP.
	 * @proxyStrategy Which IP to extract from X-Forwarded-For: "last" (rightmost, added by the nearest
	 *   trusted proxy — default, secure when the proxy appends the real client IP) or "first" (leftmost,
	 *   client-supplied — available for backward compatibility but vulnerable to spoofing).
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
		string proxyStrategy = "last",
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

		if (arguments.windowSeconds <= 0) {
			throw(
				type = "Wheels.RateLimiter.InvalidConfiguration",
				message = "Invalid rate limiter windowSeconds: #arguments.windowSeconds#. Must be a positive number — every strategy treats this as a divisor or an interval, so zero or negative values would either divide by zero (fixedWindow, tokenBucket) or let every request through (slidingWindow)."
			);
		}

		if (arguments.maxRequests < 0) {
			throw(
				type = "Wheels.RateLimiter.InvalidConfiguration",
				message = "Invalid rate limiter maxRequests: #arguments.maxRequests#. Must be zero or positive. Use maxRequests=0 to block every request (kill-switch); negative values are meaningless."
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
		// Bounded cleanup scan (#2971): at most cleanupMaxScanKeys keys are
		// examined per cleanup pass, starting at a rotating cursor so
		// successive passes cover the whole store.
		variables.cleanupCursor = 0;
		variables.cleanupMaxScanKeys = 1000;

		// Track whether DB table has been verified.
		variables.tableVerified = false;

		// Datasource for database storage is resolved lazily (see $queryOptions()) because
		// middleware is typically constructed in config/settings.cfm, before
		// application.wheels.dataSourceName is guaranteed to exist.
		variables.datasourceResolved = false;
		variables.resolvedDatasource = "";

		// Throttle markers for database housekeeping (epoch seconds via GetTickCount() / 1000).
		variables.lastDbPurge = 0;
		variables.lastTableAttempt = 0;

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
			// Routed through the maintenance lock: concurrent requests racing
			// an unguarded $evictOldest() each evicted their own 25% headroom,
			// purging far more entries than intended (#2971).
			if (variables.store.size() >= variables.maxStoreSize && !variables.store.containsKey(local.clientKey)) {
				$lockedEvictOldest(local.now, local.clientKey);
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
			// Counter rows get a "c:" namespace prefix so the UNIQUE(store_key)
			// schema can hold counter/bucket/event/anchor rows side by side without
			// cross-strategy key collisions. The in-memory store key stays
			// unprefixed — it is opaque there and the memory cleanup parsers
			// (ListLast(key, ":")) are untouched.
			return $dbIncrement(arguments.clientKey, "c:" & local.storeKey, local.resetAt);
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
		// Kill-switch: maxRequests = 0 blocks every request. Short-circuit here so the
		// refillRate (0 / windowSeconds = 0) and the subsequent 1 / refillRate division
		// never execute. Without this guard tokenBucket would throw a generic
		// "You cannot divide by zero." while fixedWindow and slidingWindow already block.
		if (variables.maxRequests == 0) {
			return {allowed: false, remaining: 0, resetAt: arguments.now + variables.windowSeconds};
		}

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
			// Shared maintenance lock: periodic cleanup and emergency eviction
			// ($lockedEvictOldest) serialize on the same name so only one
			// thread mutates the store's bookkeeping at a time (#2971).
			cflock(name = "wheels-ratelimit-maintenance", type = "exclusive", timeout = 1) {
				// Double-check after acquiring lock.
				if ((arguments.now - variables.lastCleanup) < variables.cleanupThrottleSeconds) {
					return;
				}
				variables.lastCleanup = arguments.now;

				local.currentWindowId = Int(arguments.now / variables.windowSeconds);
				local.keysToRemove = [];
				local.keys = variables.store.keySet().toArray();
				local.keyCount = ArrayLen(local.keys);

				// Bounded scan (#2971): examine at most cleanupMaxScanKeys keys
				// per pass, starting at a rotating cursor so successive passes
				// cover the whole store — the unlucky request that triggers
				// cleanup no longer pays a full-store scan at high cardinality.
				local.scanLimit = Min(local.keyCount, variables.cleanupMaxScanKeys);

				for (local.offset = 0; local.offset < local.scanLimit; local.offset++) {
					local.key = local.keys[((variables.cleanupCursor + local.offset) % local.keyCount) + 1];
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

				variables.cleanupCursor = local.keyCount > 0
					? (variables.cleanupCursor + local.scanLimit) % local.keyCount
					: 0;

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
	 * Internal probe. Public ONLY so specs can assert the store-bound
	 * invariant ($storeSize() <= maxStoreSize) without reaching into the
	 * variables scope. Returns 0 for non-memory storage.
	 */
	public numeric function $storeSize() {
		return variables.storage == "memory" ? variables.store.size() : 0;
	}

	/**
	 * Emergency eviction entry point for handle(): re-checks capacity under
	 * the shared maintenance lock before evicting, so concurrent requests
	 * that all saw a full store don't each purge their own 25% headroom
	 * (the pre-#2971 unguarded path). A lock timeout skips eviction — the
	 * ConcurrentHashMap stays consistent and the next request retries.
	 */
	private void function $lockedEvictOldest(required numeric now, required string clientKey) {
		try {
			cflock(name = "wheels-ratelimit-maintenance", type = "exclusive", timeout = 1) {
				// Double-check: a concurrent evictor may have created headroom
				// (or another thread already stored this key) while we waited.
				if (
					variables.store.size() >= variables.maxStoreSize
					&& !variables.store.containsKey(arguments.clientKey)
				) {
					$evictOldest(arguments.now);
				}
			}
		} catch (any e) {
			// Lock timeout — skip; the store remains internally consistent.
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

			// Second pass: approximated oldest-first eviction via bounded
			// random sampling (Redis-style). The previous implementation built
			// an entries array for the ENTIRE remaining store and ran a full
			// closure-comparator sort on the request thread — O(n log n) at
			// exactly the moment the store is at its largest. Sampling caps
			// the per-eviction work at a small constant while still strongly
			// preferring idle entries (#2971).
			local.remainingToEvict = local.toEvict - local.expiredCount;
			local.keys = variables.store.keySet().toArray();
			local.keyCount = ArrayLen(local.keys);
			if (local.keyCount == 0) {
				return;
			}
			local.sampleSize = 8;
			local.evicted = 0;
			// Attempt bound: repeated samples can land on already-evicted keys,
			// so cap total iterations to keep the worst case bounded too.
			local.maxAttempts = local.remainingToEvict * 4;
			local.attempts = 0;
			while (local.evicted < local.remainingToEvict && local.attempts < local.maxAttempts) {
				local.attempts++;
				local.bestKey = "";
				local.bestAge = -1;
				for (local.s = 1; local.s <= local.sampleSize; local.s++) {
					local.candidate = local.keys[RandRange(1, local.keyCount)];
					if (!variables.store.containsKey(local.candidate)) {
						continue;
					}
					local.age = $entryAge(local.candidate, arguments.now, local.currentWindowId);
					if (local.age > local.bestAge) {
						local.bestAge = local.age;
						local.bestKey = local.candidate;
					}
				}
				if (Len(local.bestKey)) {
					variables.store.remove(local.bestKey);
					local.evicted++;
				}
			}
		} catch (any e) {
			// Best-effort eviction — don't let errors propagate.
		}
	}

	/**
	 * Age score for an in-memory store entry (higher = older / more idle).
	 * Entries whose age cannot be determined score 0 (youngest), so they are
	 * evicted last — same semantics the pre-sampling sort used.
	 */
	private numeric function $entryAge(required string storeKey, required numeric now, required numeric currentWindowId) {
		local.age = 0;
		local.value = variables.store.get(arguments.storeKey);
		if (IsNull(local.value)) {
			return local.age;
		}
		if (variables.strategy == "fixedWindow" && Find(":", arguments.storeKey)) {
			local.windowId = Val(ListLast(arguments.storeKey, ":"));
			local.age = arguments.currentWindowId - local.windowId;
		} else if (variables.strategy == "slidingWindow" && IsArray(local.value) && ArrayLen(local.value) > 0) {
			local.age = arguments.now - local.value[1];
		} else if (variables.strategy == "tokenBucket" && IsStruct(local.value) && StructKeyExists(local.value, "lastRefill")) {
			local.age = arguments.now - local.value.lastRefill;
		}
		return local.age;
	}

	// ---------------------------------------------------------------------------
	// Database Storage
	// ---------------------------------------------------------------------------

	/**
	 * Database-backed fixed window increment.
	 * On engines with a native atomic upsert (MySQL/MariaDB, PostgreSQL, SQLite) the
	 * counter row is created-or-incremented in a single statement keyed on the
	 * UNIQUE(store_key) index. Everywhere else (SQL Server, Oracle, H2, unrecognized
	 * engines) an UPDATE-first algorithm runs: increment the existing counter row,
	 * INSERT when no row exists yet, and treat an insert failure as having lost the
	 * first-insert race — the UNIQUE index turns that race into a caught constraint
	 * violation, after which a single re-read returns the concurrent row.
	 */
	private struct function $dbIncrement(required string clientKey, required string storeKey, required numeric resetAt) {
		if (!$ensureTable()) {
			local.err = $handleError("table unavailable", arguments.clientKey);
			return {allowed: local.err.allowed, remaining: local.err.remaining, resetAt: arguments.resetAt};
		}

		// Kill-switch: maxRequests = 0 blocks every request. Short-circuit before the
		// INSERT path, which would otherwise allow the first request per window through
		// because local.allowed is initialised to true and the counter > maxRequests
		// check (line below) only fires once a counter row exists.
		if (variables.maxRequests == 0) {
			return {allowed: false, remaining: 0, resetAt: arguments.resetAt};
		}

		local.allowed = true;
		local.remaining = variables.maxRequests;

		try {
			$dbPurgeExpired();

			if (ListFindNoCase("mysql,postgresql,sqlite", $detectDatabaseType())) {
				local.count = $dbAtomicIncrement(arguments.storeKey, arguments.clientKey);
			} else {
				local.count = $dbUpdateAndCount(arguments.storeKey);
				if (local.count == -1) {
					// No counter row for this window yet — create it.
					if ($dbTryInsert(arguments.storeKey, arguments.clientKey)) {
						local.count = 1;
					} else {
						// Lost the first-insert race to a concurrent request — re-read once.
						local.count = $dbUpdateAndCount(arguments.storeKey);
					}
				}
			}
			if (local.count == -1) {
				// Still no row — surface as a DB error via the catch below.
				throw(
					type = "Wheels.RateLimiter.StoreUnavailable",
					message = "The wheels_rate_limits counter row could not be created or read."
				);
			}

			if (local.count > variables.maxRequests) {
				local.allowed = false;
				local.remaining = 0;
			} else {
				local.remaining = variables.maxRequests - local.count;
			}
		} catch (any e) {
			local.err = $handleError("DB error", arguments.clientKey);
			local.allowed = local.err.allowed;
			local.remaining = local.err.remaining;
		}

		return {allowed: local.allowed, remaining: local.remaining, resetAt: arguments.resetAt};
	}

	/**
	 * Atomically create-or-increment the counter row via the engine's native upsert.
	 * Only called for engines whose dialect is known: MySQL/MariaDB (ON DUPLICATE KEY
	 * UPDATE) and PostgreSQL/SQLite (ON CONFLICT ... DO UPDATE). Both forms require the
	 * UNIQUE index on store_key — without it MySQL's upsert silently always-inserts,
	 * which is why $ensureTable() refuses to leave a table without that index behind.
	 * The upsert-then-select pair is not atomic as a pair, but an interleaved request
	 * can only make the re-read count HIGHER (stricter enforcement), never lower.
	 */
	private numeric function $dbAtomicIncrement(required string storeKey, required string clientKey) {
		if ($detectDatabaseType() == "mysql") {
			local.sql = "INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, 'counter', 1, :expiresAt) ON DUPLICATE KEY UPDATE counter = counter + 1";
		} else {
			// PostgreSQL and SQLite share the ON CONFLICT syntax; both accept the
			// table-name-qualified reference to the existing row's counter.
			local.sql = "INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, 'counter', 1, :expiresAt) ON CONFLICT (store_key) DO UPDATE SET counter = wheels_rate_limits.counter + 1";
		}
		QueryExecute(
			local.sql,
			{
				storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"},
				clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"},
				expiresAt: {value: DateAdd("s", variables.windowSeconds, Now()), cfsqltype: "cf_sql_timestamp"}
			},
			$queryOptions()
		);
		local.qCount = QueryExecute(
			"SELECT counter FROM wheels_rate_limits WHERE store_key = :storeKey",
			{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}},
			$queryOptions()
		);
		if (!local.qCount.recordCount || !IsNumeric(local.qCount.counter)) {
			return -1;
		}
		return local.qCount.counter;
	}

	/**
	 * Increment the counter for a store key and return the resulting count.
	 * Returns -1 when no counter row exists yet (MAX() over zero rows returns a single
	 * row with NULL, so IsNumeric — not recordCount — is the reliable "no row" signal).
	 */
	private numeric function $dbUpdateAndCount(required string storeKey) {
		QueryExecute(
			"UPDATE wheels_rate_limits SET counter = counter + 1 WHERE store_key = :storeKey",
			{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}},
			$queryOptions()
		);
		local.qCount = QueryExecute(
			"SELECT MAX(counter) AS counter FROM wheels_rate_limits WHERE store_key = :storeKey",
			{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}},
			$queryOptions()
		);
		if (!IsNumeric(local.qCount.counter)) {
			return -1;
		}
		return local.qCount.counter;
	}

	/**
	 * Insert the first counter row for a store key.
	 * Returns false when the insert fails (losing the first-insert race against a
	 * concurrent request trips the UNIQUE store_key index) so the caller can re-read
	 * instead — the constraint-backed insert-retry idiom for engines without a
	 * portable native upsert.
	 */
	private boolean function $dbTryInsert(required string storeKey, required string clientKey) {
		try {
			QueryExecute(
				"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, 'counter', 1, :expiresAt)",
				{
					storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"},
					clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"},
					expiresAt: {value: DateAdd("s", variables.windowSeconds, Now()), cfsqltype: "cf_sql_timestamp"}
				},
				$queryOptions()
			);
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Select a row by store key with a cross-node row lock where the engine supports
	 * one: SELECT ... FOR UPDATE on PostgreSQL/MySQL/Oracle/H2, an UPDLOCK/ROWLOCK
	 * table hint on SQL Server. SQLite and unrecognized engines get a plain SELECT —
	 * there the serialization guarantee comes from the caller's in-process cflock
	 * only (sufficient on a single node, not a multi-node guarantee).
	 * Must be called inside a transaction for the lock to be held.
	 */
	private query function $dbRowLockSelect(required string storeKey) {
		local.dbType = $detectDatabaseType();
		if (local.dbType == "sqlserver") {
			local.sql = "SELECT counter, expires_at FROM wheels_rate_limits WITH (UPDLOCK, ROWLOCK) WHERE store_key = :storeKey";
		} else if (ListFindNoCase("postgresql,mysql,oracle,h2", local.dbType)) {
			local.sql = "SELECT counter, expires_at FROM wheels_rate_limits WHERE store_key = :storeKey FOR UPDATE";
		} else {
			local.sql = "SELECT counter, expires_at FROM wheels_rate_limits WHERE store_key = :storeKey";
		}
		return QueryExecute(
			local.sql,
			{storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"}},
			$queryOptions()
		);
	}

	/**
	 * Insert a wheels_rate_limits row if no row with the same store key exists yet,
	 * without ever surfacing the duplicate-key violation to the enclosing
	 * transaction. Uses the engine's insert-if-absent form where one exists
	 * (MySQL/MariaDB, PostgreSQL, SQLite); elsewhere a plain INSERT with the
	 * violation swallowed. The conditional forms are load-bearing on PostgreSQL,
	 * not style: there ANY raised statement error — even one caught in CFML —
	 * aborts the open transaction (SQLSTATE 25P02), dooming every follow-up
	 * statement including the re-read that recovers from losing a first-insert
	 * race. The engines on the try/catch branch (SQL Server, Oracle, H2,
	 * unrecognized) all survive a failed statement with the transaction intact.
	 */
	private void function $dbEnsureRow(
		required string storeKey,
		required string clientKey,
		required string rowType,
		required numeric counter,
		required date expiresAt
	) {
		local.params = {
			storeKey: {value: arguments.storeKey, cfsqltype: "cf_sql_varchar"},
			clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"},
			rowType: {value: arguments.rowType, cfsqltype: "cf_sql_varchar"},
			counter: {value: arguments.counter, cfsqltype: "cf_sql_integer"},
			expiresAt: {value: arguments.expiresAt, cfsqltype: "cf_sql_timestamp"}
		};
		local.dbType = $detectDatabaseType();
		if (local.dbType == "mysql") {
			QueryExecute(
				"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, :rowType, :counter, :expiresAt) ON DUPLICATE KEY UPDATE counter = counter",
				local.params,
				$queryOptions()
			);
		} else if (ListFindNoCase("postgresql,sqlite", local.dbType)) {
			QueryExecute(
				"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, :rowType, :counter, :expiresAt) ON CONFLICT (store_key) DO NOTHING",
				local.params,
				$queryOptions()
			);
		} else {
			try {
				QueryExecute(
					"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, :rowType, :counter, :expiresAt)",
					local.params,
					$queryOptions()
				);
			} catch (any e) {
				// Duplicate key — a concurrent request created the row first. Fine.
			}
		}
	}

	/**
	 * Ensure the per-client anchor row ("a:" prefix) exists for the sliding window
	 * strategy. The anchor is the single lockable row that serializes the
	 * delete-count-insert sequence across nodes via $dbRowLockSelect().
	 */
	private void function $dbEnsureAnchor(required string clientKey) {
		$dbEnsureRow(
			storeKey = "a:" & arguments.clientKey,
			clientKey = arguments.clientKey,
			rowType = "anchor",
			counter = 0,
			expiresAt = DateAdd("s", variables.windowSeconds, Now())
		);
	}

	/**
	 * Database-backed sliding window check.
	 * One "event" row is inserted per allowed request (store_key carries a synthetic
	 * UUID suffix so the UNIQUE store_key index holds), and the whole
	 * delete-count-insert read-modify-write sequence runs inside a transaction while
	 * holding both an in-process cflock and a cross-node row lock on the client's
	 * "anchor" row (see $dbRowLockSelect for which engines get a real SQL lock).
	 * Results route through the local.outcome struct: catch-block writes to bare
	 * local.X don't persist on BoxLang, struct-field writes do.
	 */
	private struct function $dbSlidingWindow(required string clientKey, required numeric now, required numeric windowStart, required numeric resetAt) {
		if (!$ensureTable()) {
			local.err = $handleError("table unavailable", arguments.clientKey);
			return {allowed: local.err.allowed, remaining: local.err.remaining, resetAt: arguments.resetAt};
		}

		local.outcome = {allowed: true, remaining: variables.maxRequests};
		local.expiresAt = DateAdd("s", variables.windowSeconds, Now());

		// Global purge stays outside the lock and transaction (it never throws).
		$dbPurgeExpired();

		try {
			cflock(name = "wheels-ratelimit-db-#arguments.clientKey#", type = "exclusive", timeout = 1) {
				transaction action="begin" {
					try {
						// Ensure and lock the per-client anchor row — this serializes
						// concurrent checks for the same client across nodes.
						$dbEnsureAnchor(arguments.clientKey);
						$dbRowLockSelect("a:" & arguments.clientKey);

						// Clean expired event rows for this client.
						QueryExecute(
							"DELETE FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'event' AND expires_at < :now",
							{clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}, now: {value: Now(), cfsqltype: "cf_sql_timestamp"}},
							$queryOptions()
						);

						// Count current event rows.
						local.qCount = QueryExecute(
							"SELECT COUNT(*) AS cnt FROM wheels_rate_limits WHERE client_key = :clientKey AND row_type = 'event'",
							{clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"}},
							$queryOptions()
						);

						if (local.qCount.cnt >= variables.maxRequests) {
							local.outcome.allowed = false;
							local.outcome.remaining = 0;
						} else {
							// Record this request as an event row.
							QueryExecute(
								"INSERT INTO wheels_rate_limits (store_key, client_key, row_type, counter, expires_at) VALUES (:storeKey, :clientKey, 'event', 1, :expiresAt)",
								{
									storeKey: {value: "e:" & arguments.clientKey & ":" & CreateUUID(), cfsqltype: "cf_sql_varchar"},
									clientKey: {value: arguments.clientKey, cfsqltype: "cf_sql_varchar"},
									expiresAt: {value: local.expiresAt, cfsqltype: "cf_sql_timestamp"}
								},
								$queryOptions()
							);
							local.outcome.remaining = variables.maxRequests - local.qCount.cnt - 1;
						}
						transaction action="commit";
					} catch (any dbError) {
						transaction action="rollback";
						local.err = $handleError("DB error", arguments.clientKey);
						local.outcome.allowed = local.err.allowed;
						local.outcome.remaining = local.err.remaining;
					}
				}
			}
		} catch (any lockError) {
			local.err = $handleError("lock timeout", arguments.clientKey);
			local.outcome.allowed = local.err.allowed;
			local.outcome.remaining = local.err.remaining;
		}

		return {allowed: local.outcome.allowed, remaining: local.outcome.remaining, resetAt: arguments.resetAt};
	}

	/**
	 * Database-backed token bucket check.
	 * The bucket row ("b:" prefix) is read under a transaction with a cross-node row
	 * lock plus an in-process cflock, so the refill-and-consume read-modify-write is
	 * serialized per client (see $dbRowLockSelect for engine lock support). A cold
	 * bucket is created FULL via the never-raising insert-if-absent helper
	 * ($dbEnsureRow) and then read back under the row lock, so the creator and a
	 * node that lost the first-insert race take the same path: lock whatever row
	 * exists now, refill, consume. The conditional insert is what keeps the
	 * recovery reachable on PostgreSQL — a raised duplicate-key violation there
	 * aborts the open transaction (SQLSTATE 25P02) even when CFML catches it, and
	 * the re-read would throw "current transaction is aborted" instead of locking
	 * the winning row. Results route through the local.outcome struct: catch-block
	 * writes to bare local.X don't persist on BoxLang, struct-field writes do.
	 */
	private struct function $dbTokenBucket(required string clientKey, required numeric now, required numeric refillRate, required numeric resetAt) {
		if (!$ensureTable()) {
			local.err = $handleError("table unavailable", arguments.clientKey);
			return {allowed: local.err.allowed, remaining: local.err.remaining, resetAt: arguments.resetAt};
		}

		local.outcome = {allowed: true, remaining: variables.maxRequests};
		local.bucketKey = "b:" & arguments.clientKey;

		// Global purge stays outside the lock and transaction (it never throws).
		$dbPurgeExpired();

		try {
			cflock(name = "wheels-ratelimit-db-#arguments.clientKey#", type = "exclusive", timeout = 1) {
				transaction action="begin" {
					try {
						local.qBucket = $dbRowLockSelect(local.bucketKey);
						if (!local.qBucket.recordCount) {
							// First request — create the bucket FULL (counter holds the
							// tokens, expires_at carries the last-refill time) via the
							// insert-if-absent helper, then lock whatever row exists
							// afterwards: ours, or a concurrent node's that won the
							// first-insert race. Creating full instead of pre-consumed
							// lets the refill-and-consume below treat both cases
							// identically — a fresh bucket reads as elapsed 0 ->
							// maxRequests tokens and consumes one, the same end state
							// the old insert-at-maxRequests-minus-one produced.
							$dbEnsureRow(
								storeKey = local.bucketKey,
								clientKey = arguments.clientKey,
								rowType = "bucket",
								counter = variables.maxRequests,
								expiresAt = Now()
							);
							local.qBucket = $dbRowLockSelect(local.bucketKey);
							if (!local.qBucket.recordCount) {
								throw(
									type = "Wheels.RateLimiter.StoreUnavailable",
									message = "The wheels_rate_limits bucket row could not be created or read."
								);
							}
						}

						// Calculate token refill on the locked row.
						local.elapsed = $secondsSince(local.qBucket.expires_at);
						local.currentTokens = Min(variables.maxRequests, local.qBucket.counter + (local.elapsed * arguments.refillRate));

						if (local.currentTokens < 1) {
							local.outcome.allowed = false;
							local.outcome.remaining = 0;
						} else {
							local.currentTokens -= 1;
							local.outcome.remaining = Int(local.currentTokens);
							QueryExecute(
								"UPDATE wheels_rate_limits SET counter = :tokens, expires_at = :now WHERE store_key = :storeKey",
								{
									tokens: {value: Int(local.currentTokens), cfsqltype: "cf_sql_integer"},
									now: {value: Now(), cfsqltype: "cf_sql_timestamp"},
									storeKey: {value: local.bucketKey, cfsqltype: "cf_sql_varchar"}
								},
								$queryOptions()
							);
						}
						transaction action="commit";
					} catch (any dbError) {
						transaction action="rollback";
						local.err = $handleError("DB error", arguments.clientKey);
						local.outcome.allowed = local.err.allowed;
						local.outcome.remaining = local.err.remaining;
					}
				}
			}
		} catch (any lockError) {
			local.err = $handleError("lock timeout", arguments.clientKey);
			local.outcome.allowed = local.err.allowed;
			local.outcome.remaining = local.err.remaining;
		}

		return {allowed: local.outcome.allowed, remaining: local.outcome.remaining, resetAt: arguments.resetAt};
	}

	/**
	 * Seconds elapsed since a stored timestamp value. SQLite has no real DATETIME
	 * type — depending on the engine + JDBC driver combination, a cf_sql_timestamp
	 * binding round-trips as a date object, a datetime string, or a raw
	 * epoch-milliseconds number (observed on Adobe CF with sqlite-jdbc, where
	 * IsDate() is false and DateDiff() against the raw number silently produces a
	 * huge bogus elapsed value that reads every token bucket as fully refilled).
	 * Normalize: dates/datetime strings go through DateDiff, raw numbers are
	 * treated as epoch milliseconds against GetTickCount() (epoch ms on both
	 * Lucee and Adobe).
	 */
	private numeric function $secondsSince(required any storedTime) {
		if (IsDate(arguments.storedTime)) {
			return DateDiff("s", arguments.storedTime, Now());
		}
		return Int((GetTickCount() - arguments.storedTime) / 1000);
	}

	/**
	 * Resolve query options for database storage. The Wheels datasource is resolved
	 * lazily (not in init()) because middleware is constructed in config/settings.cfm
	 * before application.wheels.dataSourceName may be set. Apps relying on a default
	 * datasource (this.datasource in Application.cfc) keep working: when nothing
	 * resolves, an empty options struct preserves the previous behavior.
	 */
	private struct function $queryOptions() {
		if (!variables.datasourceResolved) {
			try {
				if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
					variables.resolvedDatasource = application.wheels.dataSourceName;
					variables.datasourceResolved = true;
				}
			} catch (any e) {
				// No application scope available — fall through to the default datasource.
			}
		}
		if (Len(variables.resolvedDatasource)) {
			return {datasource: variables.resolvedDatasource};
		}
		return {};
	}

	/**
	 * Detect the database type from the actual datasource via JDBC metadata.
	 * Returns: "oracle", "postgresql", "h2", "mysql", "sqlserver", "sqlite", or "default".
	 * The result is memoized after the first successful cfdbinfo call — this now runs
	 * on the hot request path for dialect SQL selection, and a metadata round-trip per
	 * request is unacceptable. A failed cfdbinfo returns "default" WITHOUT caching,
	 * because the datasource may simply not be resolvable yet (middleware is
	 * constructed before application.wheels.dataSourceName exists).
	 */
	private string function $detectDatabaseType() {
		if (StructKeyExists(variables, "dbTypeCached")) {
			return variables.dbTypeCached;
		}
		try {
			local.options = $queryOptions();
			if (StructKeyExists(local.options, "datasource")) {
				cfdbinfo(type = "version", datasource = "#local.options.datasource#", name = "local.info");
			} else {
				cfdbinfo(type = "version", name = "local.info");
			}
			local.product = local.info.database_productname;
			local.detected = "default";
			if (FindNoCase("oracle", local.product)) {
				local.detected = "oracle";
			} else if (FindNoCase("postgre", local.product)) {
				local.detected = "postgresql";
			} else if (FindNoCase("h2", local.product)) {
				local.detected = "h2";
			} else if (FindNoCase("mysql", local.product) || FindNoCase("mariadb", local.product)) {
				local.detected = "mysql";
			} else if (FindNoCase("sql server", local.product)) {
				local.detected = "sqlserver";
			} else if (FindNoCase("sqlite", local.product)) {
				local.detected = "sqlite";
			}
			variables.dbTypeCached = local.detected;
			return local.detected;
		} catch (any e) {
			// cfdbinfo not available — fall through to default without caching.
		}
		return "default";
	}

	/**
	 * Throttled global purge of expired rows so the table doesn't grow without bound.
	 * The cutoff trails Now() by windowSeconds because the token bucket strategy stores
	 * its last-refill time in expires_at: a bucket idle longer than windowSeconds is
	 * fully refilled, so deleting it is semantically a no-op, while purging at Now()
	 * would wipe live buckets. For fixed/sliding window rows the extra lag is harmless.
	 */
	private void function $dbPurgeExpired() {
		local.nowSeconds = GetTickCount() / 1000;
		if ((local.nowSeconds - variables.lastDbPurge) < variables.cleanupThrottleSeconds) {
			return;
		}
		variables.lastDbPurge = local.nowSeconds;

		try {
			QueryExecute(
				"DELETE FROM wheels_rate_limits WHERE expires_at < :cutoff",
				{cutoff: {value: DateAdd("s", -variables.windowSeconds, Now()), cfsqltype: "cf_sql_timestamp"}},
				$queryOptions()
			);
		} catch (any e) {
			// Best-effort purge — never block the rate limit check.
		}
	}

	/**
	 * Auto-create the wheels_rate_limits table (schema v2) if it doesn't exist, using
	 * database-appropriate column types. Returns true only when the v2 table — with
	 * the row_type discriminator, the client_key lookup column, and a UNIQUE
	 * store_key index — is verified to exist. Legacy v1 tables (no discriminator)
	 * are dropped and recreated: a copy-migration is deliberately NOT attempted
	 * because v1 rows carry no row_type (counter rows and sliding-window event rows
	 * are indistinguishable) and the unindexed v1 table may already hold duplicate
	 * store_key rows from the first-insert race. Every row is ephemeral
	 * (TTL <= windowSeconds, idle buckets refill), so dropping resets in-flight
	 * counters for at most one window. Failed creation attempts are throttled so a
	 * permanently broken configuration doesn't run DDL on every request, but the
	 * limiter can still recover once the database becomes available.
	 */
	private boolean function $ensureTable() {
		if (variables.tableVerified) {
			return true;
		}

		// Throttle re-attempts after a failure so a broken configuration doesn't
		// probe and run DDL on every request.
		local.nowSeconds = GetTickCount() / 1000;
		if (variables.lastTableAttempt > 0 && (local.nowSeconds - variables.lastTableAttempt) < variables.cleanupThrottleSeconds) {
			return false;
		}

		// Probe for the v2 schema (extra columns beyond it are fine).
		try {
			QueryExecute("SELECT row_type, client_key, counter FROM wheels_rate_limits WHERE 1=0", {}, $queryOptions());
			variables.tableVerified = true;
			return true;
		} catch (any e) {
			// Not a v2 table — missing, unreachable, or a legacy v1 shape. Sort out below.
		}

		variables.lastTableAttempt = local.nowSeconds;

		// Legacy v1 table: drop it so the v2 CREATE below can run (see docblock for
		// why no rows are copied).
		try {
			QueryExecute("SELECT counter FROM wheels_rate_limits WHERE 1=0", {}, $queryOptions());
			try {
				QueryExecute("DROP TABLE wheels_rate_limits", {}, $queryOptions());
			} catch (any dropError) {
				// A concurrent node may have dropped it already — fall through to create.
			}
			writeLog(
				text = "Upgraded wheels_rate_limits to schema v2; in-flight rate-limit counters reset (bounded to one window)",
				type = "warning",
				file = "wheels_ratelimiter"
			);
		} catch (any e) {
			// No table at all (or unreachable) — try to create it below.
		}

		try {
			// Use database-appropriate types (same map as wheels.Job's wheels_jobs table).
			// SQL Server must get DATETIME — TIMESTAMP means rowversion there and
			// rejects explicit inserts.
			local.dbType = $detectDatabaseType();
			if (local.dbType == "oracle") {
				local.varcharType = "VARCHAR2";
				local.datetimeType = "TIMESTAMP";
			} else if (local.dbType == "postgresql") {
				local.varcharType = "VARCHAR";
				local.datetimeType = "TIMESTAMP";
			} else if (local.dbType == "h2") {
				local.varcharType = "VARCHAR";
				local.datetimeType = "TIMESTAMP";
			} else {
				local.varcharType = "VARCHAR";
				local.datetimeType = "DATETIME";
			}

			QueryExecute("
				CREATE TABLE wheels_rate_limits (
					store_key #local.varcharType#(255) NOT NULL,
					client_key #local.varcharType#(255) NOT NULL,
					row_type #local.varcharType#(16) NOT NULL,
					counter INT,
					expires_at #local.datetimeType#
				)
			", {}, $queryOptions());

			// The UNIQUE index is load-bearing, not an optimization: MySQL's
			// ON DUPLICATE KEY UPDATE silently degrades to always-insert without a
			// unique key, capping every counter at 1 and disabling enforcement
			// entirely. If it can't be created the table must not survive
			// (fail-closed) — a non-unique v2 table would pass the probe but break
			// the upsert contract.
			try {
				QueryExecute("CREATE UNIQUE INDEX uq_wrl_store_key ON wheels_rate_limits (store_key)", {}, $queryOptions());
			} catch (any uniqueIndexError) {
				try {
					QueryExecute("DROP TABLE wheels_rate_limits", {}, $queryOptions());
				} catch (any dropError) {
				}
				writeLog(
					text = "Failed to create the UNIQUE store_key index on wheels_rate_limits — table dropped (fail-closed): #uniqueIndexError.message#",
					type = "error",
					file = "wheels_ratelimiter"
				);
				return false;
			}

			// Plain lookup indexes are optional — don't fail table creation if they
			// can't be created.
			try {
				QueryExecute("CREATE INDEX idx_wrl_client_key ON wheels_rate_limits (client_key)", {}, $queryOptions());
				QueryExecute("CREATE INDEX idx_wrl_expires_at ON wheels_rate_limits (expires_at)", {}, $queryOptions());
			} catch (any indexError) {
			}

			writeLog(text = "Auto-created wheels_rate_limits table (schema v2)", type = "information", file = "wheels_ratelimiter");
			variables.tableVerified = true;
			return true;
		} catch (any createError) {
			// A concurrent node or thread may have created the table between our probe
			// and the CREATE — re-probe once (against the v2 column set) before
			// reporting failure.
			try {
				QueryExecute("SELECT row_type, client_key, counter FROM wheels_rate_limits WHERE 1=0", {}, $queryOptions());
				variables.tableVerified = true;
				return true;
			} catch (any reprobeError) {
			}
			writeLog(
				text = "Failed to auto-create wheels_rate_limits table: #createError.message#",
				type = "error",
				file = "wheels_ratelimiter"
			);
			return false;
		}
	}

}
