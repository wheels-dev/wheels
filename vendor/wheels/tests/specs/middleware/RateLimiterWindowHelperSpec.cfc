/**
 * Pins the #3773 flake mechanism and the spec helper that avoids it.
 *
 * fixedWindow counts requests per clock-aligned window, so two requests on
 * either side of a boundary are counted in different windows. A spec that
 * expects the second of two requests to be limited therefore fails whenever
 * its requests straddle a boundary. `$awaitRateLimitWindow()`
 * (rateLimiterWindow.cfm) waits out the tail of a window first.
 *
 * Deterministic on a slow runner: a 2-second window, a warm-up request first
 * (so first-call cost can't push the timed request past the boundary), then
 * a start 900 ms before a boundary. Case 1 sends its second request 1300 ms
 * later (400 ms into the next window); case 2 keeps its two requests 500 ms
 * apart inside one fresh window. Every edge has several hundred ms of slack.
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
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 2);
				var nextFn = function(req) {
					return "ok";
				};
				// Warm-up on another client: pay first-call cost before the timed part.
				limiter.handle(request = {remoteAddr: "rl-boundary-warmup-1"}, next = nextFn);
				$sleepToWindowEnd(2, 900);
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-straddle"}, next = nextFn)).toBe("ok");
				Sleep(1300);
				// The second request lands in the next window, so it is not limited.
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-straddle"}, next = nextFn)).toBe("ok");
			});

			it("$awaitRateLimitWindow keeps the same sequence inside one window", () => {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 2);
				var nextFn = function(req) {
					return "ok";
				};
				limiter.handle(request = {remoteAddr: "rl-boundary-warmup-2"}, next = nextFn);
				$sleepToWindowEnd(2, 900);
				$awaitRateLimitWindow(2, 1);
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-helper"}, next = nextFn)).toBe("ok");
				Sleep(500);
				expect(limiter.handle(request = {remoteAddr: "rl-boundary-helper"}, next = nextFn)).toInclude("Rate limit exceeded");
			});

		});

	}

}
