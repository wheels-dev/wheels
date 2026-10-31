/**
 * Pins the #3773 flake mechanism with the framework clock seam instead of real waits.
 *
 * fixedWindow counts requests per clock-aligned window, so two requests on either side of a
 * boundary are counted in different windows. The original spec reproduced that with multi-second
 * sleeps (`$sleepToWindowEnd()` then 1300/500 ms), which was slow and still timing-dependent on a
 * loaded runner. travelTo() freezes $tick() at an exact instant, so both sides of the boundary are
 * deterministic: the real RateLimiter (key resolution, fixed-window store, locking, assertions) is
 * still exercised; only the clock is faked.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("RateLimiter fixedWindow sequences near a window boundary (##3773)", () => {

			it("counts two requests that straddle a boundary in different windows", () => {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 2);
				var nextFn = function(req) {
					return "ok";
				};
				// 12:00:01 and 12:00:03 fall in different 2-second windows (aligned to the epoch),
				// so the second request starts a fresh window and is not limited.
				travelTo("2026-10-04 12:00:01", function() {
					expect(limiter.handle(request = {remoteAddr: "rl-boundary-straddle"}, next = nextFn)).toBe("ok");
				});
				travelTo("2026-10-04 12:00:03", function() {
					expect(limiter.handle(request = {remoteAddr: "rl-boundary-straddle"}, next = nextFn)).toBe("ok");
				});
			});

			it("keeps the same sequence inside one window", () => {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 2);
				var nextFn = function(req) {
					return "ok";
				};
				// Same frozen instant = same window, so the second request is limited.
				travelTo("2026-10-04 12:00:01", function() {
					expect(limiter.handle(request = {remoteAddr: "rl-boundary-same"}, next = nextFn)).toBe("ok");
					expect(limiter.handle(request = {remoteAddr: "rl-boundary-same"}, next = nextFn)).toInclude("Rate limit exceeded");
				});
			});

		});

	}

}
