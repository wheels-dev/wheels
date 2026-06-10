component extends="wheels.WheelsTest" {

	function beforeAll() {
		_originalCache = application.wheels.cache
		_originalCacheCullPercentage = application.wheels.cacheCullPercentage
		_originalCacheLastCulledAt = application.wheels.cacheLastCulledAt
		_originalCacheCullInterval = application.wheels.cacheCullInterval
		_originalMaximumItemsToCache = application.wheels.maximumItemsToCache
	}

	function afterAll() {
		application.wheels.cache = _originalCache
		application.wheels.cacheCullPercentage = _originalCacheCullPercentage
		application.wheels.cacheLastCulledAt = _originalCacheLastCulledAt
		application.wheels.cacheCullInterval = _originalCacheCullInterval
		application.wheels.maximumItemsToCache = _originalMaximumItemsToCache
	}

	function run() {

		describe("Tests that $addToCache culling", () => {

			beforeEach(() => {
				application.wheels.cache = {main = {}, other = {}}
				application.wheels.cacheCullPercentage = 100
				application.wheels.cacheCullInterval = 1
				application.wheels.cacheLastCulledAt = DateAdd("n", -10, Now())
			})

			it("frees room for a write to one category by culling expired items in other categories", () => {
				// fill "main" with expired items up to the global cache maximum
				for (var i = 1; i <= 5; i++) {
					application.wheels.cache.main["expired#i#"] = {
						expiresAt = DateAdd("n", -5, Now()),
						value = "stale"
					}
				}
				application.wheels.maximumItemsToCache = 5

				application.wo.$addToCache(key = "newItem", value = "fresh", time = 60, category = "other")

				expect(StructKeyExists(application.wheels.cache.other, "newItem")).toBeTrue()
			})

			it("does not delete unexpired items while culling", () => {
				application.wheels.cache.main["stillFresh"] = {
					expiresAt = DateAdd("n", 30, Now()),
					value = "keep"
				}
				for (var i = 1; i <= 4; i++) {
					application.wheels.cache.main["expired#i#"] = {
						expiresAt = DateAdd("n", -5, Now()),
						value = "stale"
					}
				}
				application.wheels.maximumItemsToCache = 5

				application.wo.$addToCache(key = "newItem", value = "fresh", time = 60, category = "other")

				expect(StructKeyExists(application.wheels.cache.main, "stillFresh")).toBeTrue()
				expect(StructKeyExists(application.wheels.cache.other, "newItem")).toBeTrue()
			})

			it("stops culling once the cull percentage has been deleted", () => {
				application.wheels.cacheCullPercentage = 50
				for (var i = 1; i <= 10; i++) {
					application.wheels.cache.main["expired#i#"] = {
						expiresAt = DateAdd("n", -5, Now()),
						value = "stale"
					}
				}
				application.wheels.maximumItemsToCache = 10

				application.wo.$addToCache(key = "newItem", value = "fresh", time = 60, category = "main")

				// 50% of 10 items culled (5) plus the newly stored item
				expect(StructCount(application.wheels.cache.main)).toBe(6)
				expect(StructKeyExists(application.wheels.cache.main, "newItem")).toBeTrue()
			})

			it("drops the new item when nothing can be culled and the cache is still full", () => {
				for (var i = 1; i <= 5; i++) {
					application.wheels.cache.main["stillFresh#i#"] = {
						expiresAt = DateAdd("n", 30, Now()),
						value = "keep"
					}
				}
				application.wheels.maximumItemsToCache = 5

				application.wo.$addToCache(key = "newItem", value = "fresh", time = 60, category = "other")

				expect(StructKeyExists(application.wheels.cache.other, "newItem")).toBeFalse()
				expect(StructCount(application.wheels.cache.main)).toBe(5)
			})
		})
	}
}
