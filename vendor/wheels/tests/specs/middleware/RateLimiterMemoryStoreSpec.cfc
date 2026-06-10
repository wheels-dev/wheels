/**
 * Memory-storage maintenance hardening for RateLimiter (issue #2971):
 *
 * 1. handle() previously called $evictOldest() with no lock — concurrent
 *    requests raced the eviction bookkeeping (an eviction storm could purge
 *    far more than the intended 25% headroom). Emergency eviction now goes
 *    through $lockedEvictOldest(), double-checked under the same named
 *    maintenance lock the periodic cleanup uses.
 * 2. The eviction's second pass ran an ArraySort with a closure comparator
 *    over the entire remaining store on the unlucky request thread. It now
 *    uses bounded random sampling (Redis-style approximated oldest-first).
 * 3. The periodic cleanup scanned every key inline on the request thread.
 *    The scan is now capped per pass with a rotating cursor so successive
 *    passes cover the whole store.
 *
 * Concurrency itself can't be exercised deterministically from a spec, so
 * the lock discipline and the no-sort/bounded-scan facts are pinned at
 * source level (the established pattern for structural guarantees), while
 * the store-bound behavior is asserted behaviorally via $storeSize().
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.source = FileRead(ExpandPath("/wheels/middleware/RateLimiter.cfc"));
	}

	function run() {

		describe("RateLimiter memory-store maintenance (##2971)", () => {

			it("keeps the store at or below maxStoreSize under sustained unique-client pressure", () => {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1000,
					windowSeconds = 60,
					strategy = "fixedWindow",
					maxStoreSize = 5
				);
				var nextFn = function(req) { return "ok"; };

				for (var i = 1; i <= 50; i++) {
					var req = {remoteAddr: "pressure-client-#i#"};
					expect(limiter.handle(request = req, next = nextFn)).toBe("ok");
					expect(limiter.$storeSize()).toBeLTE(5);
				}
			});

			it("still admits and stores a new client immediately after eviction", () => {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1000,
					windowSeconds = 60,
					strategy = "tokenBucket",
					maxStoreSize = 4
				);
				var nextFn = function(req) { return "ok"; };

				for (var i = 1; i <= 12; i++) {
					var req = {remoteAddr: "bucket-client-#i#"};
					expect(limiter.handle(request = req, next = nextFn)).toBe("ok");
				}
				expect(limiter.$storeSize()).toBeLTE(4);
			});

			it("routes the emergency eviction through the maintenance lock", () => {
				// handle() must not call $evictOldest() directly — the locked
				// wrapper double-checks capacity under the shared named lock.
				expect(variables.source).toInclude("$lockedEvictOldest(");
				expect(variables.source).toInclude("wheels-ratelimit-maintenance");
			});

			it("does not sort the full store on the request thread", () => {
				expect(Find("ArraySort", variables.source)).toBe(
					0,
					"$evictOldest must use bounded sampling, not a full-store ArraySort with a closure comparator on the request thread."
				);
			});

			it("bounds the periodic cleanup scan with a rotating cursor", () => {
				expect(variables.source).toInclude("cleanupMaxScanKeys");
				expect(variables.source).toInclude("cleanupCursor");
			});

		});

	}

}
