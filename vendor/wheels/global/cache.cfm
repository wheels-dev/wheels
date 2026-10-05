<cfscript>
/**
 * wheels.Global include: cache
 * Application-scope cache helpers.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// CACHE FUNCTIONS
	// ======================================================================

	/**
	 * Creates a unique string based on any arguments passed in (used as a key for caching mostly).
	 */
	public string function $hashedKey() {
		local.rv = "";

		// make all cache keys domain specific (do not use request scope below since it may not always be initialized)
		StructInsert(arguments, ListLen(StructKeyList(arguments)) + 1, cgi.http_host, true);

		// Build a tagged, order-preserving structure (struct keys sorted, argument names, array elements
		// and query rows kept in order) and serialize it once, so the key ignores struct key order only.
		local.keyArray = ListToArray(ListSort(StructKeyList(arguments), "textnocase", "asc"));
		try {
			local.rv = SerializeJSON($canonicalCacheStruct(arguments, local.keyArray, 0));
		} catch (any e) {
			// values the canonical encoder cannot represent (e.g. driver-specific Java objects) fall back on cfwddx
			local.values = [];
			local.iEnd = ArrayLen(local.keyArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (StructKeyExists(arguments, local.keyArray[local.i])) {
					ArrayAppend(local.values, arguments[local.keyArray[local.i]]);
				}
			}
			local.rv = $wddx(input = local.values);
		}
		return Hash(local.rv);
	}

	/**
	 * Internal function.
	 * Canonical form of a struct (or the arguments scope) for `$hashedKey()`: a "t"-tagged array of
	 * lower-cased key / value pairs in the given key order. Simple values are inlined; complex values
	 * become tagged arrays, and an undefined value becomes an empty array, so the forms cannot collide.
	 */
	public array function $canonicalCacheStruct(required any container, required array keys, numeric depth = 0) {
		local.rv = ["t"];
		local.iEnd = ArrayLen(arguments.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = arguments.keys[local.i];
			ArrayAppend(local.rv, LCase(local.key));
			if (!StructKeyExists(arguments.container, local.key)) {
				ArrayAppend(local.rv, []);
			} else if (IsSimpleValue(arguments.container[local.key])) {
				ArrayAppend(local.rv, arguments.container[local.key]);
			} else {
				ArrayAppend(local.rv, $canonicalCacheValue(arguments.container[local.key], arguments.depth + 1));
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 * Canonical form of a value for `$hashedKey()`. Struct keys are sorted (their engine iteration order
	 * is not stable), while array elements and query rows keep their position. Queries are embedded as-is
	 * and serialized natively, which preserves row and cell order.
	 */
	public any function $canonicalCacheValue(any value, numeric depth = 0) {
		// `value` is optional because some engines report a declared-but-unpassed argument as a key
		// holding null, which then arrives here as a missing argument
		if (!StructKeyExists(arguments, "value") || IsNull(arguments.value)) {
			return [];
		}
		if (arguments.depth > 64) {
			Throw(type = "Wheels.CacheKeyTooDeep", message = "Value is nested too deeply to build a cache key.");
		}
		if (IsBinary(arguments.value)) {
			return ["x", Hash(ToBase64(arguments.value))];
		}
		if (IsSimpleValue(arguments.value)) {
			return arguments.value;
		}
		if (IsQuery(arguments.value)) {
			return ["q", arguments.value];
		}
		if (IsArray(arguments.value)) {
			local.rv = ["a"];
			local.iEnd = ArrayLen(arguments.value);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (!ArrayIsDefined(arguments.value, local.i)) {
					ArrayAppend(local.rv, []);
				} else if (IsSimpleValue(arguments.value[local.i])) {
					ArrayAppend(local.rv, arguments.value[local.i]);
				} else {
					ArrayAppend(local.rv, $canonicalCacheValue(arguments.value[local.i], arguments.depth + 1));
				}
			}
			return local.rv;
		}
		if (IsObject(arguments.value)) {
			// model objects are keyed on their class and current property values
			if (StructKeyExists(arguments.value, "$classData") && StructKeyExists(arguments.value, "properties")) {
				local.object = arguments.value;
				return ["m", local.object.$classData().modelName, $canonicalCacheValue(local.object.properties(), arguments.depth + 1)];
			}
			return ["o", SerializeJSON(arguments.value)];
		}
		if (IsStruct(arguments.value)) {
			local.keys = StructKeyArray(arguments.value);
			ArraySort(local.keys, "textnocase");
			return $canonicalCacheStruct(arguments.value, local.keys, arguments.depth + 1);
		}
		return ["o", SerializeJSON(arguments.value)];
	}

	/**
	 * Session/user identity folded into action cache keys so params-only
	 * pages do not leak across sessions.
	 */
	public string function $sessionCacheIdentity() {
		var identity = "";
		try {
			if (IsDefined("session.user.id")) {
				identity = ToString(session.user.id);
			} else if (IsDefined("session.user") && IsSimpleValue(session.user)) {
				identity = ToString(session.user);
			} else if (IsDefined("session.sessionid")) {
				identity = ToString(session.sessionid);
			}
		} catch (any e) {
		}
		return identity;
	}

	/**
	 * Store key for category=action: hashed key plus session/user identity.
	 */
	public string function $actionCacheKey(required string key) {
		return arguments.key & ":" & $sessionCacheIdentity();
	}

	/**
	 * True when the last $getFromCache was a miss (absent, expired, or culled).
	 * A stored falsey value is a hit. Do not infer miss from the returned value.
	 */
	public boolean function $isCacheMiss() {
		return !IsDefined("request.wheels.cacheLastHit") || !request.wheels.cacheLastHit;
	}


	/**
	 * Internal function.
	 * Case-sensitive, constant-time string comparison. Both values are hashed with
	 * SHA-256 before being compared via MessageDigest.isEqual so the comparison
	 * neither leaks length information nor exits early on the first differing byte.
	 * Used by the reload/restart password gate and the environment-switch gate.
	 */
	public boolean function $secureCompare(required string candidate, required string comparedValue) {
		return CreateObject("java", "java.security.MessageDigest").isEqual(
			Hash(arguments.candidate, "SHA-256").getBytes("UTF-8"),
			Hash(arguments.comparedValue, "SHA-256").getBytes("UTF-8")
		);
	}


	/**
	 * Internal function.
	 */
	public any function $timeSpanForCache(
		required any cache,
		numeric defaultCacheTime = application.wheels.defaultCacheTime,
		string cacheDatePart = application.wheels.cacheDatePart
	) {
		local.cache = arguments.defaultCacheTime;
		if (IsNumeric(arguments.cache)) {
			local.cache = arguments.cache;
		}
		local.listArray = [0, 0, 0, 0];
		local.dateParts = "d,h,n,s";
		local.datePartsArray = ListToArray(local.dateParts);
		local.iEnd = ArrayLen(local.datePartsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (arguments.cacheDatePart == local.datePartsArray[local.i]) {
				local.listArray[local.i] = local.cache;
			}
		}
		local.rv = CreateTimespan(local.listArray[1], local.listArray[2], local.listArray[3], local.listArray[4]);
		return local.rv;
	}


	/**
	 * Internal function. Returns `true` when the value was stored, `false` when the cache was full.
	 */
	public boolean function $addToCache(
		required string key,
		required any value,
		numeric time = application.wheels.defaultCacheTime,
		string category = "main"
	) {
		local.stored = false;
		lock name="#application.applicationName#wheelsCacheStore" type="exclusive" timeout="30" {
		local.storeKey = arguments.key;
		if (arguments.category == "action") {
			local.storeKey = $actionCacheKey(arguments.key);
		}
		local.currentCount = $cacheCount();
		if (
			application.wheels.cacheCullPercentage > 0
			&& application.wheels.cacheLastCulledAt < DateAdd("n", -application.wheels.cacheCullInterval, Now())
			&& local.currentCount >= application.wheels.maximumItemsToCache
		) {
			// the cache is full so flush out expired items to make more room if possible
			// (the maximum applies to the cache as a whole so we cull across all categories,
			// otherwise a write to a small category would free nothing and get dropped)
			local.deletedItems = 0;
			if (application.wheels.cacheCullPercentage < 100) {
				local.maxItemsToDelete = Ceiling(local.currentCount * application.wheels.cacheCullPercentage / 100);
			} else {
				local.maxItemsToDelete = local.currentCount;
			}
			local.now = Now();
			local.categories = StructKeyArray(application.wheels.cache);
			local.iEnd = ArrayLen(local.categories);
			for (local.i = 1; local.i <= local.iEnd && local.deletedItems < local.maxItemsToDelete; local.i++) {
				local.cacheCategory = local.categories[local.i];
				// snapshot the keys so we never delete from the struct we are iterating over
				local.cacheKeys = StructKeyArray(application.wheels.cache[local.cacheCategory]);
				local.jEnd = ArrayLen(local.cacheKeys);
				for (local.j = 1; local.j <= local.jEnd && local.deletedItems < local.maxItemsToDelete; local.j++) {
					local.cacheKey = local.cacheKeys[local.j];
					if (
						StructKeyExists(application.wheels.cache[local.cacheCategory], local.cacheKey)
						&& local.now > application.wheels.cache[local.cacheCategory][local.cacheKey].expiresAt
					) {
						$removeFromCache(key = local.cacheKey, category = local.cacheCategory);
						local.deletedItems++;
					}
				}
			}
			local.currentCount -= local.deletedItems;
			application.wheels.cacheLastCulledAt = Now();
		}
		if (local.currentCount < application.wheels.maximumItemsToCache) {
			local.cacheItem = {};
			local.cacheItem.expiresAt = DateAdd(application.wheels.cacheDatePart, arguments.time, Now());
			if (IsSimpleValue(arguments.value)) {
				local.cacheItem.value = arguments.value;
			} else {
				local.cacheItem.value = Duplicate(arguments.value);
			}
			application.wheels.cache[arguments.category][local.storeKey] = local.cacheItem;
			local.stored = true;
			if (arguments.category == "action" && StructKeyExists(variables, "$class") && StructKeyExists(variables.$class, "name")) {
				if (!StructKeyExists(application.wheels, "cacheActionIndex")) {
					application.wheels.cacheActionIndex = {};
				}
				local.owner = variables.$class.name;
				local.actionName = "*";
				if (StructKeyExists(variables, "params") && IsStruct(variables.params) && StructKeyExists(variables.params, "action")) {
					local.actionName = variables.params.action;
				}
				if (!StructKeyExists(application.wheels.cacheActionIndex, local.owner)) {
					application.wheels.cacheActionIndex[local.owner] = {};
				}
				if (!StructKeyExists(application.wheels.cacheActionIndex[local.owner], local.actionName)) {
					application.wheels.cacheActionIndex[local.owner][local.actionName] = {};
				}
				application.wheels.cacheActionIndex[local.owner][local.actionName][local.storeKey] = true;
			}
		}
		}
		return local.stored;
	}


	/**
	 * Internal function.
	 */
	public any function $getFromCache(required string key, string category = "main") {
		local.rv = false;
		local.hit = false;
		lock name="#application.applicationName#wheelsCacheStore" type="exclusive" timeout="30" {
			try {
				local.storeKey = arguments.key;
				if (arguments.category == "action") {
					local.storeKey = $actionCacheKey(arguments.key);
				}
				if (StructKeyExists(application.wheels.cache[arguments.category], local.storeKey)) {
					if (Now() > application.wheels.cache[arguments.category][local.storeKey].expiresAt) {
						$removeFromCache(key = local.storeKey, category = arguments.category);
					} else {
						if (IsSimpleValue(application.wheels.cache[arguments.category][local.storeKey].value)) {
							local.rv = application.wheels.cache[arguments.category][local.storeKey].value;
						} else {
							local.rv = Duplicate(application.wheels.cache[arguments.category][local.storeKey].value);
						}
						local.hit = true;
					}
				}
			} catch (any e) {
			}
		}
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		request.wheels.cacheLastHit = local.hit;
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public void function $removeFromCache(required string key, string category = "main") {
		StructDelete(application.wheels.cache[arguments.category], arguments.key);
	}


	/**
	 * Internal function.
	 */
	public numeric function $cacheCount(string category = "") {
		if (Len(arguments.category)) {
			local.rv = StructCount(application.wheels.cache[arguments.category]);
		} else {
			local.rv = 0;
			for (local.key in application.wheels.cache) {
				local.rv += StructCount(application.wheels.cache[local.key]);
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public void function $clearCache(string category = "") {
		lock name="#application.applicationName#wheelsCacheStore" type="exclusive" timeout="30" {
			if (Len(arguments.category)) {
				if (StructKeyExists(application.wheels.cache, arguments.category) && IsStruct(application.wheels.cache[arguments.category])) {
					StructClear(application.wheels.cache[arguments.category]);
				}
			} else {
				local.categories = StructKeyArray(application.wheels.cache);
				$clearCacheCategories(categories = local.categories);
			}
		}
	}

	/**
	 * Clears each category struct in place. Hoisted so $clearCache() can
	 * call it from the lock body without a for-loop in a finally-like shape
	 * that Lucee 7 miscompiles (cross-engine invariant 12).
	 */
	public void function $clearCacheCategories(required array categories) {
		local.iEnd = ArrayLen(arguments.categories);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.cacheCategory = arguments.categories[local.i];
			if (StructKeyExists(application.wheels.cache, local.cacheCategory) && IsStruct(application.wheels.cache[local.cacheCategory])) {
				StructClear(application.wheels.cache[local.cacheCategory]);
			}
		}
	}


	// ======================================================================
	// APPLICATION DATA CACHE (public)
	// ======================================================================

	/**
	 * Returns the value cached under `key`. On a miss, calls `callback`, caches what it returns for `time`
	 * and returns it. A cached `false`, `0` or `""` counts as a hit, so `callback` isn't called again
	 * until the entry expires or is deleted. When `callback` returns nothing, nothing is cached and `""`
	 * is returned; when it throws, nothing is cached and the error propagates. `callback` runs outside
	 * the cache lock, so two requests that miss at the same moment may both call it (the later write
	 * wins). The cache lives in this server's memory and empties on an application reload or restart.
	 *
	 * [section: Global Helpers]
	 * [category: Caching Functions]
	 *
	 * @key A string, or a struct or array of values (struct key order doesn't matter).
	 * @callback A function that computes the value.
	 * @time How long to keep the value, in `cacheDatePart` units (minutes by default).
	 */
	public any function appCacheFetch(
		required any key,
		required any callback,
		numeric time = application.wheels.defaultCacheTime
	) {
		local.storeKey = $appCacheKey(arguments.key);
		local.value = $getFromCache(key = local.storeKey, category = $appCacheCategory());
		if (!$isCacheMiss()) {
			return local.value;
		}
		local.fn = arguments.callback;
		local.result = local.fn();
		if (!StructKeyExists(local, "result")) {
			return "";
		}
		$addToCache(key = local.storeKey, value = local.result, time = arguments.time, category = $appCacheCategory());
		return local.result;
	}

	/**
	 * Returns the value cached under `key`, or `defaultValue` when there is no unexpired entry. A cached
	 * `false`, `0` or `""` is returned as it is. Complex values come back as a copy.
	 *
	 * [section: Global Helpers]
	 * [category: Caching Functions]
	 *
	 * @key A string, or a struct or array of values (struct key order doesn't matter).
	 * @defaultValue What to return on a miss. The named argument `default` is also accepted.
	 */
	public any function appCacheRead(required any key, any defaultValue = "") {
		local.value = $getFromCache(key = $appCacheKey(arguments.key), category = $appCacheCategory());
		if (!$isCacheMiss()) {
			return local.value;
		}
		// `default` is a reserved word Adobe CF won't bind as a parameter name, but a named argument
		// still arrives under its literal key on every engine.
		if (StructKeyExists(arguments, "default")) {
			return arguments.default;
		}
		return arguments.defaultValue;
	}

	/**
	 * Caches `value` under `key` for `time`, replacing any entry already there. Complex values are
	 * stored as a copy. Returns `false` when the value wasn't stored because the cache is full
	 * (`maximumItemsToCache`).
	 *
	 * [section: Global Helpers]
	 * [category: Caching Functions]
	 *
	 * @key A string, or a struct or array of values (struct key order doesn't matter).
	 * @value The value to cache.
	 * @time How long to keep the value, in `cacheDatePart` units (minutes by default).
	 */
	public boolean function appCacheWrite(
		required any key,
		required any value,
		numeric time = application.wheels.defaultCacheTime
	) {
		return $addToCache(
			key = $appCacheKey(arguments.key),
			value = arguments.value,
			time = arguments.time,
			category = $appCacheCategory()
		);
	}

	/**
	 * Returns `true` when an unexpired entry exists for `key`, even one holding `false`, `0` or `""`.
	 *
	 * [section: Global Helpers]
	 * [category: Caching Functions]
	 *
	 * @key A string, or a struct or array of values (struct key order doesn't matter).
	 */
	public boolean function appCacheExists(required any key) {
		local.storeKey = $appCacheKey(arguments.key);
		local.category = $appCacheCategory();
		lock name="#application.applicationName#wheelsCacheStore" type="readonly" timeout="30" {
			local.rv = StructKeyExists(application.wheels.cache[local.category], local.storeKey)
				&& Now() <= application.wheels.cache[local.category][local.storeKey].expiresAt;
		}
		return local.rv;
	}

	/**
	 * Removes the entry for `key`. Returns `true` when there was an unexpired entry to remove.
	 *
	 * [section: Global Helpers]
	 * [category: Caching Functions]
	 *
	 * @key A string, or a struct or array of values (struct key order doesn't matter).
	 */
	public boolean function appCacheDelete(required any key) {
		local.storeKey = $appCacheKey(arguments.key);
		local.category = $appCacheCategory();
		lock name="#application.applicationName#wheelsCacheStore" type="exclusive" timeout="30" {
			local.rv = StructKeyExists(application.wheels.cache[local.category], local.storeKey)
				&& Now() <= application.wheels.cache[local.category][local.storeKey].expiresAt;
			StructDelete(application.wheels.cache[local.category], local.storeKey);
		}
		return local.rv;
	}

	/**
	 * Removes every entry from the application data cache. The framework's own caches (actions, pages,
	 * partials, queries) are left alone.
	 *
	 * [section: Global Helpers]
	 * [category: Caching Functions]
	 */
	public void function appCacheClear() {
		$clearCache(category = $appCacheCategory());
	}

	/**
	 * Internal function. The `application.wheels.cache` category the application data cache uses,
	 * created here when the running application started before it existed.
	 */
	public string function $appCacheCategory() {
		if (!StructKeyExists(application.wheels.cache, "data")) {
			lock name="#application.applicationName#wheelsCacheStore" type="exclusive" timeout="30" {
				if (!StructKeyExists(application.wheels.cache, "data")) {
					application.wheels.cache.data = {};
				}
			}
		}
		return "data";
	}

	/**
	 * Internal function. The store key for an application data cache key. A string is hashed as it is, so
	 * keys stay case-sensitive even though the cache struct isn't; anything else is hashed from its
	 * canonical form, so struct key order doesn't matter. Unlike `$hashedKey()`, the host name isn't part
	 * of it, so a job and a request share entries.
	 */
	public string function $appCacheKey(required any key) {
		if (IsSimpleValue(arguments.key)) {
			return "s:" & Hash(arguments.key, "SHA-256");
		}
		return "c:" & Hash(SerializeJSON($canonicalCacheValue(value = arguments.key)), "SHA-256");
	}
</cfscript>
