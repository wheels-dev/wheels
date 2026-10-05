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

	/**
	 * Clears the per-request finder cache that `cacheQueriesDuringRequest` fills, namespaced under the
	 * reserved `request.wheels["$queryCache"]` key. Use this instead of reaching into that internal key.
	 *
	 *   model("Post").forgetCachedQueries()   clears just the Post model's slot (chainable — returns the model)
	 *   forgetCachedQueries("Post")           clears just the Post model's slot, by name (works anywhere)
	 *   forgetCachedQueries(all = true)        clears every model's cached results this request
	 *
	 * Called as a method on a model instance it scopes to that model automatically, because only a model
	 * carries `variables.wheels.class.modelName` (Controller / view / job / base Global do not). Called
	 * outside a model with neither a `modelName` nor `all`, it throws rather than silently wiping every
	 * model's cache — clearing everything has to be asked for explicitly.
	 *
	 * This is a single global helper on purpose: it cannot also be declared on the model, because Adobe CF
	 * forbids the same UDF name in both the Global mixin and a model fragment (both compile into the model
	 * component). A no-op when nothing has been cached yet.
	 *
	 * [section: Miscellaneous Functions]
	 * [category: General Functions]
	 *
	 * @modelName Clear only this model's slot. Defaults to the calling model's own name when invoked as
	 *   `model("X").forgetCachedQueries()`.
	 * @all Clear every model's cached queries for the request. Required (true) to wipe everything from
	 *   outside a model.
	 */
	public any function forgetCachedQueries(string modelName = "", boolean all = false) {
		local.slot = arguments.modelName;
		if (
			!Len(local.slot)
			&& StructKeyExists(variables, "wheels")
			&& StructKeyExists(variables.wheels, "class")
			&& IsStruct(variables.wheels.class)
			&& StructKeyExists(variables.wheels.class, "modelName")
		) {
			local.slot = variables.wheels.class.modelName;
		}

		if (!arguments.all && !Len(local.slot)) {
			Throw(
				type = "Wheels.InvalidArgument",
				message = "forgetCachedQueries() needs a model to clear, or all = true.",
				detail = "Call it on a model (model(""Post"").forgetCachedQueries()), name a model (forgetCachedQueries(""Post"")), or pass all = true to clear every model's cached queries for this request."
			);
		}

		if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "$queryCache")) {
			if (arguments.all) {
				StructDelete(request.wheels, "$queryCache");
			} else {
				// Empty just this model's slot, keeping the key — the same shape $clearRequestCache
				// leaves behind, so a re-query repopulates it in place.
				request.wheels["$queryCache"][local.slot] = {};
			}
		}
		return this;
	}
</cfscript>
