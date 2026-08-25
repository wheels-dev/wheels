/**
 * Hardener proofs for Cache BLOCKERs B1–B2 and SHOULDs S1–S9.
 * Desk IDs are stable. Do not renumber.
 *
 * Directory-scoped so `wheels test --core --ci --filter=caching`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("CoS lock: cacheFileChecking and named-action time/static", function() {

			it("keeps cacheFileChecking true", function() {
				var src = FileRead(ExpandPath("/wheels/events/init/caching.cfm"));
				expect(FindNoCase("application.$wheels.cacheFileChecking = true", src)).toBeGT(0);
			});

			it("keeps caches() time=60 and static=false defaults when an action is named", function() {
				var fnSrc = FileRead(ExpandPath("/wheels/events/init/functions.cfm"));
				expect(FindNoCase("functions.caches = {time = 60, static = false}", fnSrc)).toBeGT(0);
			});

		});

		describe("B1 processAction cache write/hit/key", function() {

			beforeEach(function() {
				$beginActionCacheProbe();
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				_controller.$clearCachableActions();
				_controller.flashClear();
			});

			afterEach(function() {
				_controller.$clearCachableActions();
				$endActionCacheProbe();
			});

			it("B1: one cached action writes a key, hits it, and keeps the same key", function() {
				_controller.caches(action = "cachedShow");
				request.hardenerCachePayload = "b1-write";

				var first = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				expect(first.processAction()).toBeTrue();
				expect(first.response()).toBe("b1-write");

				var className = first.$getControllerClassData().name;
				var params = {controller = "hardenerLifecycle", action = "cachedShow"};
				var hashedKey = g.$hashedKey(className, params);
				var storeKey = g.$actionCacheKey(hashedKey);
				expect(StructKeyExists(application.wheels.cache.action, storeKey)).toBeTrue(
					"processAction must write the action body under the session-qualified store key"
				);
				expect(g.$getFromCache(key = hashedKey, category = "action")).toBe("b1-write");
				expect(g.$cacheCount("action")).toBe(1);

				request.hardenerCachePayload = "b1-should-not-run";
				var second = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				expect(second.processAction()).toBeTrue();
				expect(second.response()).toBe("b1-write");
				expect(g.$cacheCount("action")).toBe(1);
				expect(StructKeyExists(application.wheels.cache.action, storeKey)).toBeTrue();
			});

		});

		describe("B2 $cacheSettingsForAction matches processAction first-match and keeps appendToKey", function() {

			beforeEach(function() {
				$beginActionCacheProbe();
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				_controller.$clearCachableActions();
				_controller.flashClear();
			});

			afterEach(function() {
				_controller.$clearCachableActions();
				StructDelete(request, "cacheProbeA");
				StructDelete(request, "cacheProbeB");
				$endActionCacheProbe();
			});

			it("B2: first matching caches() row wins and appendToKey survives", function() {
				_controller.caches(action = "cachedShow", time = 11, appendToKey = "request.cacheProbeA");
				_controller.caches(action = "cachedShow", time = 99, appendToKey = "request.cacheProbeB");

				var settings = _controller.$cacheSettingsForAction("cachedShow");
				expect(IsStruct(settings)).toBeTrue();
				expect(settings.time).toBe(11);
				expect(settings.static).toBeFalse();
				expect(settings).toHaveKey("appendToKey");
				expect(settings.appendToKey).toBe("request.cacheProbeA");
			});

			it("B2: a leading wildcard is first-match, same as processAction", function() {
				_controller.caches(action = "*", time = 7, appendToKey = "request.cacheProbeA");
				_controller.caches(action = "cachedShow", time = 99, appendToKey = "request.cacheProbeB");

				var settings = _controller.$cacheSettingsForAction("cachedShow");
				expect(settings.time).toBe(7);
				expect(settings.appendToKey).toBe("request.cacheProbeA");
			});

			it("B2: processAction keys the first-match appendToKey, not a later row", function() {
				_controller.caches(action = "cachedShow", time = 10, appendToKey = "request.cacheProbeA");
				_controller.caches(action = "cachedShow", time = 99, appendToKey = "request.cacheProbeB");

				request.cacheProbeA = "alpha";
				request.cacheProbeB = "bravo";
				request.hardenerCachePayload = "b2-first";

				var first = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				first.processAction();
				expect(first.response()).toBe("b2-first");

				var className = first.$getControllerClassData().name;
				var params = {controller = "hardenerLifecycle", action = "cachedShow"};
				var scopeMap = {
					"request": request,
					"arguments": {},
					"application": application,
					"session": session,
					"variables": {}
				};
				var expectedKey = g.$actionCacheKey(
					first.$appendToCacheKey(
						key = g.$hashedKey(className, params),
						appendToKey = "request.cacheProbeA",
						scopeMap = scopeMap
					)
				);
				expect(StructKeyExists(application.wheels.cache.action, expectedKey)).toBeTrue(
					"processAction must keep the first-match appendToKey on the cache key"
				);

				request.hardenerCachePayload = "b2-should-not-run";
				var second = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				second.processAction();
				expect(second.response()).toBe("b2-first");

				request.cacheProbeA = "alpha-changed";
				request.hardenerCachePayload = "b2-miss";
				var third = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				third.processAction();
				expect(third.response()).toBe("b2-miss");
			});

		});

		describe("S1 caches() requires named actions", function() {

			beforeEach(function() {
				_controller = g.controller("dummy", {controller = "dummy", action = "dummy"});
				_controller.$clearCachableActions();
			});

			it("S1: caches() with no action throws instead of silently becoming *", function() {
				expect(function() {
					_controller.caches();
				}).toThrow("Wheels.InvalidArgument");
			});

			it("S1: caches(static=true) with no action throws", function() {
				expect(function() {
					_controller.caches(static = true);
				}).toThrow("Wheels.InvalidArgument");
			});

			it("S1: an explicit * is still allowed when named", function() {
				_controller.caches(action = "*");
				expect(_controller.$cachableActions()[1].action).toBe("*");
			});

		});

		describe("S2 testing stays cache-off like development", function() {

			it("S2: only non-dev/non-test environments enable cacheActions/Pages/Partials/Images/Queries", function() {
				var src = FileRead(ExpandPath("/wheels/events/init/caching.cfm"));
				expect(FindNoCase("ListFindNoCase(""development,testing"", application.$wheels.environment)", src)).toBeGT(0);
				expect(FindNoCase("if (application.$wheels.environment != ""development"")", src)).toBe(0);
			});

		});

		describe("S3 action cache key includes session/user", function() {

			beforeEach(function() {
				$beginActionCacheProbe();
				if (StructKeyExists(session, "user")) {
					_priorSessionUser = Duplicate(session.user);
				}
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				_controller.$clearCachableActions();
				_controller.flashClear();
				_controller.caches(action = "cachedShow");
			});

			afterEach(function() {
				_controller.$clearCachableActions();
				if (StructKeyExists(variables, "_priorSessionUser")) {
					session.user = _priorSessionUser;
					StructDelete(variables, "_priorSessionUser");
				} else {
					StructDelete(session, "user");
				}
				$endActionCacheProbe();
			});

			it("S3: params-only pages do not leak one session's body to another", function() {
				session.user = {id = "alice"};
				request.hardenerCachePayload = "payload-alice";
				var alice = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				alice.processAction();
				expect(alice.response()).toBe("payload-alice");

				session.user = {id = "bob"};
				request.hardenerCachePayload = "payload-bob";
				var bob = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				bob.processAction();
				expect(bob.response()).toBe("payload-bob");
				expect(g.$cacheCount("action")).toBe(2);
			});

		});

		describe("S4 silent-drop when the cache is full", function() {

			beforeEach(function() {
				_originalCache = application.wheels.cache;
				_originalCacheCullPercentage = application.wheels.cacheCullPercentage;
				_originalCacheLastCulledAt = application.wheels.cacheLastCulledAt;
				_originalCacheCullInterval = application.wheels.cacheCullInterval;
				_originalMaximumItemsToCache = application.wheels.maximumItemsToCache;
				application.wheels.cache = {main = {}, other = {}};
				application.wheels.cacheCullPercentage = 100;
				application.wheels.cacheCullInterval = 1;
				application.wheels.cacheLastCulledAt = DateAdd("n", -10, Now());
			});

			afterEach(function() {
				application.wheels.cache = _originalCache;
				application.wheels.cacheCullPercentage = _originalCacheCullPercentage;
				application.wheels.cacheLastCulledAt = _originalCacheLastCulledAt;
				application.wheels.cacheCullInterval = _originalCacheCullInterval;
				application.wheels.maximumItemsToCache = _originalMaximumItemsToCache;
			});

			it("S4: drops the new item when nothing can be culled and the cache is still full", function() {
				for (var i = 1; i <= 5; i++) {
					application.wheels.cache.main["stillFresh#i#"] = {
						expiresAt = DateAdd("n", 30, Now()),
						value = "keep"
					};
				}
				application.wheels.maximumItemsToCache = 5;

				g.$addToCache(key = "newItem", value = "fresh", time = 60, category = "other");

				expect(StructKeyExists(application.wheels.cache.other, "newItem")).toBeFalse();
				expect(StructCount(application.wheels.cache.main)).toBe(5);
			});

		});

		describe("S5 cache store lock", function() {

			it("S5: $addToCache / $getFromCache / $clearCache take wheelsCacheStore", function() {
				var src = FileRead(ExpandPath("/wheels/global/cache.cfm"));
				var addPos = FindNoCase("function $addToCache", src);
				var getPos = FindNoCase("function $getFromCache", src);
				var clearPos = FindNoCase("function $clearCache", src);
				expect(addPos).toBeGT(0);
				expect(getPos).toBeGT(0);
				expect(clearPos).toBeGT(0);
				var addLock = FindNoCase("wheelsCacheStore", src, addPos);
				var getLock = FindNoCase("wheelsCacheStore", src, getPos);
				var clearLock = FindNoCase("wheelsCacheStore", src, clearPos);
				expect(addLock).toBeGT(0);
				expect(addLock).toBeLT(getPos);
				expect(getLock).toBeGT(0);
				expect(getLock).toBeLT(clearPos);
				expect(clearLock).toBeGT(0);
			});

			it("S5: add/get/clear still return the same public values", function() {
				var probeKey = "s5-lock-probe";
				g.$clearCache("main");
				g.$addToCache(key = probeKey, value = "s5-body", time = 60, category = "main");
				expect(g.$getFromCache(key = probeKey, category = "main")).toBe("s5-body");
				g.$clearCache("main");
				g.$getFromCache(key = probeKey, category = "main");
				expect(g.$isCacheMiss()).toBeTrue();
			});

		});

		describe("S6 clearCachableActions drops this-controller action bodies", function() {

			beforeEach(function() {
				$beginActionCacheProbe();
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				_controller.$clearCachableActions();
				_controller.flashClear();
			});

			afterEach(function() {
				_controller.$clearCachableActions();
				$endActionCacheProbe();
			});

			it("S6: clearCachableActions removes this controller's bodies and leaves others", function() {
				_controller.caches(action = "cachedShow");
				request.hardenerCachePayload = "s6-body";
				var first = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				first.processAction();
				expect(g.$cacheCount("action")).toBeGT(0);

				application.wheels.cache.action["other-controller-decoy"] = {
					expiresAt = DateAdd("n", 30, Now()),
					value = "keep-other"
				};

				_controller.clearCachableActions();
				expect(StructKeyExists(application.wheels.cache.action, "other-controller-decoy")).toBeTrue();
				expect(application.wheels.cache.action["other-controller-decoy"].value).toBe("keep-other");
				expect(g.$cacheCount("action")).toBe(1);
			});

		});

		describe("S7 $clearCache is targeted", function() {

			beforeEach(function() {
				_originalCache = Duplicate(application.wheels.cache);
			});

			afterEach(function() {
				application.wheels.cache = _originalCache;
			});

			it("S7: no-arg $clearCache() clears each category and keeps the buckets", function() {
				application.wheels.cache.main["s7-main"] = {expiresAt = DateAdd("n", 30, Now()), value = "m"};
				application.wheels.cache.action["s7-action"] = {expiresAt = DateAdd("n", 30, Now()), value = "a"};
				g.$clearCache();
				expect(application.wheels.cache).toHaveKey("main");
				expect(application.wheels.cache).toHaveKey("action");
				expect(IsStruct(application.wheels.cache.main)).toBeTrue();
				expect(IsStruct(application.wheels.cache.action)).toBeTrue();
				expect(StructCount(application.wheels.cache.main)).toBe(0);
				expect(StructCount(application.wheels.cache.action)).toBe(0);
			});

			it("S7: $clearCache no longer wipes the parent cache struct", function() {
				var src = FileRead(ExpandPath("/wheels/global/cache.cfm"));
				expect(ReFindNoCase("StructClear\s*\(\s*application\.wheels\.cache\s*\)", src)).toBe(0);
			});

		});

		describe("S8 caches(Foo) matches action foo", function() {

			beforeEach(function() {
				$beginActionCacheProbe();
				_controller = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				_controller.$clearCachableActions();
				_controller.flashClear();
			});

			afterEach(function() {
				_controller.$clearCachableActions();
				$endActionCacheProbe();
			});

			it("S8: $cacheSettingsForAction is case-insensitive", function() {
				_controller.caches(action = "CachedShow", time = 15);
				var settings = _controller.$cacheSettingsForAction("cachedShow");
				expect(IsStruct(settings)).toBeTrue();
				expect(settings.time).toBe(15);
			});

			it("S8: processAction caches CachedShow when the action is cachedShow", function() {
				_controller.caches(action = "CachedShow");
				request.hardenerCachePayload = "s8-body";
				var first = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				first.processAction();
				expect(first.response()).toBe("s8-body");
				expect(g.$cacheCount("action")).toBe(1);
			});

		});

		describe("S9 stored false is not a miss", function() {

			afterEach(function() {
				g.$clearCache("main");
			});

			it("S9: $addToCache(key, false) then $getFromCache returns false as a hit", function() {
				g.$clearCache("main");

				var miss = g.$getFromCache(key = "s9-missing", category = "main");
				expect(miss).toBeFalse();
				expect(g.$isCacheMiss()).toBeTrue();
				expect(StructKeyExists(application.wheels.cache.main, "s9-missing")).toBeFalse();

				g.$addToCache(key = "s9-false", value = false, time = 60, category = "main");
				var hit = g.$getFromCache(key = "s9-false", category = "main");
				expect(hit).toBeFalse();
				expect(g.$isCacheMiss()).toBeFalse();
				expect(StructKeyExists(application.wheels.cache.main, "s9-false")).toBeTrue();
			});

			it("S9: other falsey stored payloads are hits, not misses", function() {
				g.$clearCache("main");
				g.$addToCache(key = "s9-zero", value = 0, time = 60, category = "main");
				g.$addToCache(key = "s9-blank", value = "", time = 60, category = "main");
				expect(g.$getFromCache(key = "s9-zero", category = "main")).toBe(0);
				expect(g.$isCacheMiss()).toBeFalse();
				expect(g.$getFromCache(key = "s9-blank", category = "main")).toBe("");
				expect(g.$isCacheMiss()).toBeFalse();
			});

		});

	}

	public void function $beginActionCacheProbe() {
		_hadCacheActions = StructKeyExists(application.wheels, "cacheActions");
		if (_hadCacheActions) {
			_priorCacheActions = application.wheels.cacheActions;
		}
		application.wheels.cacheActions = true;
		_originalForm = Duplicate(form);
		StructClear(form);
		g.$clearCache("action");
	}

	public void function $endActionCacheProbe() {
		g.$clearCache("action");
		StructClear(form);
		StructAppend(form, _originalForm, false);
		if (_hadCacheActions) {
			application.wheels.cacheActions = _priorCacheActions;
		} else {
			StructDelete(application.wheels, "cacheActions");
		}
		StructDelete(request, "hardenerCachePayload");
	}

}
