/**
 * The clock seam: $now() / $tick() read the real clock unless a spec has frozen it with travelTo().
 * Framework code reads the seam so a spec can travel it; in production no travelTo() runs, so the seam
 * returns the live clock and behaviour is unchanged. travelTo() restores the previous clock in a
 * catch-free finally, and the override lives in request scope so it cannot leak past the request.
 *
 * Note: the seam is read through a hoisted `var clock = application.wo` rather than a bare
 * `application.wo.$now()` — a zero-arg call through the application scope inside a closure does not
 * compile on Adobe 2025 (cross-engine invariant 16b); a local-var receiver does.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("clock seam ($now / $tick)", () => {

			it("$now() is the real clock (within tolerance) when no travel is active", () => {
				var clock = application.wo;
				var delta = Abs(DateDiff("s", clock.$now(), Now()));
				expect(delta).toBeLTE(2);
			});

			it("$tick() tracks GetTickCount() (within tolerance) when no travel is active", () => {
				var clock = application.wo;
				var delta = Abs(clock.$tick() - GetTickCount());
				expect(delta).toBeLTE(2000);
			});

			it("travelTo() freezes $now() to the given instant inside the callback", () => {
				var clock = application.wo;
				var seen = {at = ""};
				travelTo("2026-10-04 12:00:00", function() {
					seen.at = clock.$now();
				});
				expect(DateFormat(seen.at, "yyyy-mm-dd")).toBe("2026-10-04");
				expect(TimeFormat(seen.at, "HH:mm:ss")).toBe("12:00:00");
			});

			it("travelTo() freezes $tick() to the instant's epoch ms", () => {
				var clock = application.wo;
				var expectedTick = ParseDateTime("2026-10-04 12:00:00").getTime();
				var seen = {tick = 0};
				travelTo("2026-10-04 12:00:00", function() {
					seen.tick = clock.$tick();
				});
				expect(seen.tick).toBe(expectedTick);
			});

			it("restores the real clock after travelTo() returns", () => {
				var clock = application.wo;
				travelTo("2020-01-01 00:00:00", function() {});
				var delta = Abs(DateDiff("s", clock.$now(), Now()));
				expect(delta).toBeLTE(2);
			});

			it("restores the real clock even when the callback throws", () => {
				var clock = application.wo;
				var state = {threw = false};
				try {
					travelTo("2020-01-01 00:00:00", function() {
						Throw(type = "Test.Boom", message = "boom");
					});
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
				var delta = Abs(DateDiff("s", clock.$now(), Now()));
				expect(delta).toBeLTE(2);
			});

		});

		describe("the seam reaches real framework features (the payoff)", () => {

			it("a cached item is a miss once the clock travels past its expiry", () => {
				var clock = application.wo;
				var key = "clockseam_" & CreateUUID();
				clock.$addToCache(key = key, value = "cached-value", time = 5);
				expect(clock.$getFromCache(key)).toBe("cached-value");
				// Travel past the expiry window (cacheDatePart units) — the cull/expiry logic reads $now().
				var past = DateAdd(application.wheels.cacheDatePart, 10, Now());
				travelTo(past, function() {
					expect(clock.$getFromCache(key)).toBe(false);
				});
			});

			it("the rate-limit window resets once the clock travels past it", () => {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);
				var nextFn = function(req) {
					return "ok";
				};
				var req = {cgi = {remote_addr = "10.0.0.77"}};
				// Frozen inside one 60s window: first request passes, the second is blocked.
				travelTo("2026-10-04 12:00:00", function() {
					expect(limiter.handle(request = req, next = nextFn)).toBe("ok");
					expect(limiter.handle(request = req, next = nextFn)).toInclude("Rate limit exceeded");
				});
				// Two minutes later the window has rolled over, so a request passes again — deterministically,
				// with no sleeping, because RateLimiter reads $tick() through the seam.
				travelTo("2026-10-04 12:02:00", function() {
					expect(limiter.handle(request = req, next = nextFn)).toBe("ok");
				});
			});

		});

	}

}
