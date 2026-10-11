/**
 * The application data cache: appCacheFetch(), appCacheRead(), appCacheWrite(), appCacheExists(),
 * appCacheDelete() and appCacheClear(). Entries live in their own `data` category, so clearing them
 * never touches the framework's action, page, partial or query caches.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("The application data cache", () => {

			beforeEach(() => {
				g.appCacheClear();
			});

			afterEach(() => {
				g.appCacheClear();
			});

			it("computes a value on a miss and returns the cached one on a hit", () => {
				var calls = {count = 0};
				var compute = function() {
					calls.count++;
					return "computed-" & calls.count;
				};
				expect(g.appCacheFetch("f3-fetch", compute, 5)).toBe("computed-1");
				expect(g.appCacheFetch("f3-fetch", compute, 5)).toBe("computed-1");
				expect(calls.count).toBe(1);
				expect(g.appCacheExists("f3-fetch")).toBeTrue();
			});

			it("treats a cached false, 0 or empty string as a hit", () => {
				var calls = {count = 0};
				var compute = function() {
					calls.count++;
					return "recomputed";
				};
				expect(g.appCacheWrite("f3-false", false)).toBeTrue();
				expect(g.appCacheWrite("f3-zero", 0)).toBeTrue();
				expect(g.appCacheWrite("f3-blank", "")).toBeTrue();
				expect(g.appCacheExists("f3-false")).toBeTrue();
				expect(g.appCacheExists("f3-zero")).toBeTrue();
				expect(g.appCacheExists("f3-blank")).toBeTrue();
				expect(g.appCacheRead("f3-false", "missing")).toBeFalse();
				expect(g.appCacheRead("f3-zero", "missing")).toBe(0);
				expect(g.appCacheRead("f3-blank", "missing")).toBe("");
				expect(g.appCacheFetch("f3-false", compute)).toBeFalse();
				expect(g.appCacheFetch("f3-zero", compute)).toBe(0);
				expect(g.appCacheFetch("f3-blank", compute)).toBe("");
				expect(calls.count).toBe(0);
			});

			it("returns the default on a miss, under either argument name", () => {
				expect(g.appCacheRead("f3-absent")).toBe("");
				expect(g.appCacheRead("f3-absent", "fallback")).toBe("fallback");
				expect(g.appCacheRead(key = "f3-absent", defaultValue = "by-name")).toBe("by-name");
				expect(g.appCacheRead(key = "f3-absent", default = "legacy-name")).toBe("legacy-name");
				expect(g.appCacheExists("f3-absent")).toBeFalse();
			});

			it("stops returning an entry once it expires", () => {
				g.appCacheWrite("f3-expiring", "fresh", 5);
				application.wheels.cache.data[g.$appCacheKey("f3-expiring")].expiresAt = DateAdd("n", -1, Now());
				expect(g.appCacheExists("f3-expiring")).toBeFalse();
				expect(g.appCacheRead("f3-expiring", "gone")).toBe("gone");
				expect(g.appCacheFetch("f3-expiring", () => "recomputed")).toBe("recomputed");
				expect(g.appCacheRead("f3-expiring")).toBe("recomputed");
			});

			it("deletes one entry and reports whether it was there", () => {
				g.appCacheWrite("f3-delete", "x");
				expect(g.appCacheDelete("f3-delete")).toBeTrue();
				expect(g.appCacheExists("f3-delete")).toBeFalse();
				expect(g.appCacheDelete("f3-delete")).toBeFalse();
			});

			it("clears only its own entries, never the framework's", () => {
				g.$addToCache(key = "f3-framework-entry", value = "kept", time = 5, category = "main");
				try {
					g.appCacheWrite("f3-framework-entry", "data value");
					g.appCacheClear();
					expect(g.appCacheExists("f3-framework-entry")).toBeFalse();
					expect(g.$getFromCache(key = "f3-framework-entry", category = "main")).toBe("kept");
					expect(g.$isCacheMiss()).toBeFalse();
				} finally {
					g.$removeFromCache(key = "f3-framework-entry", category = "main");
				}
			});

			it("hashes a struct or array key, ignoring struct key order", () => {
				g.appCacheWrite({user = 42, section = "orders"}, "by-struct");
				expect(g.appCacheRead({section = "orders", user = 42})).toBe("by-struct");
				g.appCacheWrite(["user", 42, "orders"], "by-array");
				expect(g.appCacheRead(["user", 42, "orders"])).toBe("by-array");
				expect(g.appCacheRead(["orders", 42, "user"], "other")).toBe("other");
				expect(g.appCacheDelete({section = "orders", user = 42})).toBeTrue();
			});

			it("keeps string keys case-sensitive", () => {
				g.appCacheWrite("f3-Case", "upper");
				expect(g.appCacheRead("f3-case", "lower-missing")).toBe("lower-missing");
			});

			it("stores and returns copies of complex values", () => {
				var original = {items = [1, 2]};
				g.appCacheWrite("f3-copy", original);
				ArrayAppend(original.items, 3);
				var first = g.appCacheRead("f3-copy");
				expect(ArrayLen(first.items)).toBe(2);
				ArrayAppend(first.items, 99);
				expect(ArrayLen(g.appCacheRead("f3-copy").items)).toBe(2);
			});

			it("caches nothing when the callback returns nothing", () => {
				var noValue = function() {
					var ignored = 1;
				};
				expect(g.appCacheFetch("f3-void", noValue)).toBe("");
				expect(g.appCacheExists("f3-void")).toBeFalse();
			});

			it("caches nothing and passes the error on when the callback throws", () => {
				var state = {type = ""};
				var boom = function() {
					Throw(type = "Wheels.AppCacheSpecBoom", message = "boom");
				};
				try {
					g.appCacheFetch("f3-throw", boom);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.AppCacheSpecBoom");
				expect(g.appCacheExists("f3-throw")).toBeFalse();
			});

			it("returns false from appCacheWrite when the cache is full", () => {
				var saved = {
					maximumItemsToCache = application.wheels.maximumItemsToCache,
					cacheCullPercentage = application.wheels.cacheCullPercentage
				};
				try {
					application.wheels.cacheCullPercentage = 0;
					application.wheels.maximumItemsToCache = g.$cacheCount();
					expect(g.appCacheWrite("f3-full", "x")).toBeFalse();
					expect(g.appCacheExists("f3-full")).toBeFalse();
				} finally {
					application.wheels.maximumItemsToCache = saved.maximumItemsToCache;
					application.wheels.cacheCullPercentage = saved.cacheCullPercentage;
				}
			});

			it("creates its category when the running application started without one", () => {
				var savedData = application.wheels.cache.data;
				StructDelete(application.wheels.cache, "data");
				try {
					expect(g.appCacheWrite("f3-recreated", "ok")).toBeTrue();
					expect(g.appCacheRead("f3-recreated")).toBe("ok");
				} finally {
					application.wheels.cache.data = savedData;
				}
			});

		});

	}

}
