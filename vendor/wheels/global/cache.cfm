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

		// we need to make sure we are looping through the passed in arguments in the same order everytime
		local.values = [];
		local.keyList = ListSort(StructKeyList(arguments), "textnocase", "asc");
		local.keyArray = ListToArray(local.keyList);
		local.iEnd = ArrayLen(local.keyArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			ArrayAppend(local.values, arguments[local.keyArray[local.i]]);
		}

		if (!ArrayIsEmpty(local.values)) {
			// this might fail if a query contains binary data so in those rare cases we fall back on using cfwddx (which is a little bit slower which is why we don't use it all the time)
			try {
				local.rv = SerializeJSON(local.values);
				local.rv = $engineAdapter().normalizeForHash(local.rv);
			} catch (any e) {
				local.rv = $wddx(input = local.values);
			}
		}
		return Hash(local.rv);
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
	 * Internal function.
	 */
	public void function $addToCache(
		required string key,
		required any value,
		numeric time = application.wheels.defaultCacheTime,
		string category = "main"
	) {
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
</cfscript>
