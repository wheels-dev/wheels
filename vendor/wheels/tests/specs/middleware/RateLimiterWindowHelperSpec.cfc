/**
 * Pins the #3773 flake mechanism and the spec helper that avoids it.
 *
 * fixedWindow counts requests per clock-aligned window, so two requests on
 * either side of a boundary are counted in different windows. A spec that
 * expects the second of two requests to be limited therefore fails whenever
 * its requests straddle a boundary. `$awaitRateLimitWindow()`
 * (rateLimiterWindow.cfm) waits out the tail of a window first.
 *
 * Deterministic: a 1-second window, forced to within 300 ms of a boundary,
 * with 500 ms between the requests, so each case has hundreds of milliseconds
 * of margin on a slow runner.
 */
component extends="wheels.WheelsTest" {

	include "rateLimiterWindow.cfm";

	/** Sleep until `leadMs` before the next boundary of a `windowSeconds` window. */
	public void function $sleepToWindowEnd(required numeric windowSeconds, required numeric leadMs) {
		var nowMs = GetTickCount();
		var windowMs = arguments.windowSeconds * 1000;
		var untilEndMs = windowMs - (nowMs - Int(nowMs / windowMs) * windowMs);
		if (untilEndMs > arguments.leadMs) {
			Sleep(untilEndMs - arguments.leadMs);
		} else {
			// Too close to this boundary: aim at the next one instead.
			Sleep(untilEndMs + windowMs - arguments.leadMs);
		}
	}

	function run() {

		describe("RateLimiter fixedWindow sequences near a window boundary (##3773)", () => {

			it("counts two requests that straddle a boundary in different windows", () => {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 1);
				var nextFn = function(req) {
					return "ok";
				};
				$sleepToWindowEnd(1, 300);
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-straddle"}, next = nextFn)).toBe("ok");
				Sleep(500);
				// The second request lands in the next window, so it is not limited.
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-straddle"}, next = nextFn)).toBe("ok");
			});

			it("$awaitRateLimitWindow keeps the same sequence inside one window", () => {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 1);
				var nextFn = function(req) {
					return "ok";
				};
				$sleepToWindowEnd(1, 300);
				$awaitRateLimitWindow(1, 0.5);
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-helper"}, next = nextFn)).toBe("ok");
				Sleep(500);
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-helper"}, next = nextFn)).toInclude("Rate limit exceeded");
			});

		});

	}

}
