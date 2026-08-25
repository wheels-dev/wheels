/**
 * Hardener proofs for Cache BLOCKERs B1–B2 and SHOULDs S1–S8.
 * Desk IDs are stable. Do not renumber.
 *
 * Directory-scoped so `wheels test --core --ci --filter=caching`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("CoS lock: cache public defaults stay conservative", function() {

			it("keeps cacheActions/Pages/Partials/Images/Queries off in development only", function() {
				var src = FileRead(ExpandPath("/wheels/events/init/caching.cfm"));
				expect(FindNoCase("application.$wheels.cacheActions = false", src)).toBeGT(0);
				expect(FindNoCase("application.$wheels.cacheImages = false", src)).toBeGT(0);
				expect(FindNoCase("application.$wheels.cachePages = false", src)).toBeGT(0);
				expect(FindNoCase("application.$wheels.cachePartials = false", src)).toBeGT(0);
				expect(FindNoCase("application.$wheels.cacheQueries = false", src)).toBeGT(0);
				expect(FindNoCase("if (application.$wheels.environment != ""development"")", src)).toBeGT(0);
			});

			it("keeps cacheFileChecking true", function() {
				var src = FileRead(ExpandPath("/wheels/events/init/caching.cfm"));
				expect(FindNoCase("application.$wheels.cacheFileChecking = true", src)).toBeGT(0);
			});

			it("keeps caches() empty-action wildcard and time/static defaults", function() {
				var cachesSrc = FileRead(ExpandPath("/wheels/controller/caching.cfc"));
				var fnSrc = FileRead(ExpandPath("/wheels/events/init/functions.cfm"));
				expect(FindNoCase("arguments.action = ""*""", cachesSrc)).toBeGT(0);
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
				var expectedKey = g.$hashedKey(className, params);
				expect(StructKeyExists(application.wheels.cache.action, expectedKey)).toBeTrue(
					"processAction must write the action body under $hashedKey(class, params)"
				);
				expect(g.$getFromCache(key = expectedKey, category = "action")).toBe("b1-write");
				expect(g.$cacheCount("action")).toBe(1);

				request.hardenerCachePayload = "b1-should-not-run";
				var second = g.controller("hardenerLifecycle", {controller = "hardenerLifecycle", action = "cachedShow"});
				expect(second.processAction()).toBeTrue();
				expect(second.response()).toBe("b1-write");
				expect(g.$cacheCount("action")).toBe(1);
				expect(StructKeyExists(application.wheels.cache.action, expectedKey)).toBeTrue();
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
				var expectedKey = first.$appendToCacheKey(
					key = g.$hashedKey(className, params),
					appendToKey = "request.cacheProbeA",
					scopeMap = scopeMap
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
				expect(g.$getFromCache(key = probeKey, category = "main")).toBeFalse();
			});

		});

		describe("HELD: S7 $clearCache still wipes the bucket with StructClear", function() {

			it("S7: $clearCache keeps StructClear (do not change wipe policy)", function() {
				var src = FileRead(ExpandPath("/wheels/global/cache.cfm"));
				expect(FindNoCase("StructClear(application.wheels.cache[arguments.category])", src)).toBeGT(0);
				expect(FindNoCase("StructClear(application.wheels.cache)", src)).toBeGT(0);
			});

		});

		describe("HELD: S3 action key does not fold in session by default", function() {

			it("S3: $hashedKey still seeds only arguments plus cgi.http_host", function() {
				var src = FileRead(ExpandPath("/wheels/global/cache.cfm"));
				expect(FindNoCase("StructInsert(arguments, ListLen(StructKeyList(arguments)) + 1, cgi.http_host, true)", src)).toBeGT(0);
				expect(FindNoCase("session", src)).toBe(0);
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
