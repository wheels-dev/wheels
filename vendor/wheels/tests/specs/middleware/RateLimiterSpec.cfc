/**
 * Tests for RateLimiter middleware, specifically covering the trustProxy setting
 * and its effect on client IP resolution for rate limiting.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("RateLimiter trustProxy default", function() {

			it("defaults trustProxy to false", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);

				var nextFn = function(req) { return "ok"; };

				// With default (trustProxy=false), both requests share the same
				// remote_addr bucket — the second should be blocked even though
				// the X-Forwarded-For values differ.
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "1.1.1.1"
					}
				};
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "2.2.2.2"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);
				expect(result1).toBe("ok");
				expect(result2).toInclude("Rate limit exceeded");
			});

			it("ignores X-Forwarded-For when trustProxy is false", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 2, windowSeconds = 60, trustProxy = false);

				var nextFn = function(req) { return "ok"; };

				// Two requests from same remote_addr but different X-Forwarded-For
				// should count against the SAME bucket (remote_addr).
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "1.1.1.1"
					}
				};
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "2.2.2.2"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);
				expect(result1).toBe("ok");
				expect(result2).toBe("ok");

				// Third request from same remote_addr (different X-Forwarded-For) should be blocked.
				var req3 = {
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "3.3.3.3"
					}
				};
				var result3 = limiter.handle(request = req3, next = nextFn);
				expect(result3).toInclude("Rate limit exceeded");
			});

			it("uses X-Forwarded-For when trustProxy is true", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 2, windowSeconds = 60, trustProxy = true);

				var nextFn = function(req) { return "ok"; };

				// Two requests from same remote_addr but DIFFERENT X-Forwarded-For
				// should count against DIFFERENT buckets when trustProxy is true.
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "1.1.1.1"
					}
				};
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "2.2.2.2"
					}
				};
				var req3 = {
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "3.3.3.3"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);
				var result3 = limiter.handle(request = req3, next = nextFn);

				// All three should pass because each has a unique X-Forwarded-For (separate buckets).
				expect(result1).toBe("ok");
				expect(result2).toBe("ok");
				expect(result3).toBe("ok");
			});

			it("blocks spoofed IPs when trustProxy is false (default)", function() {
				// With trustProxy=false, an attacker who rotates X-Forwarded-For
				// should still be rate limited by remote_addr.
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 3, windowSeconds = 60);

				var nextFn = function(req) { return "ok"; };
				var attackerIp = "10.0.0.99";

				// Attacker sends 3 requests with different spoofed X-Forwarded-For headers.
				for (var i = 1; i <= 3; i++) {
					var req = {
						cgi: {
							remote_addr: attackerIp,
							http_x_forwarded_for: "fake-#i#.#i#.#i#.#i#"
						}
					};
					limiter.handle(request = req, next = nextFn);
				}

				// Fourth request should be blocked regardless of spoofed header.
				var blockedReq = {
					cgi: {
						remote_addr: attackerIp,
						http_x_forwarded_for: "99.99.99.99"
					}
				};
				var result = limiter.handle(request = blockedReq, next = nextFn);
				expect(result).toInclude("Rate limit exceeded");
			});

			it("uses remoteAddr from request struct when present", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);

				var nextFn = function(req) { return "ok"; };

				// remoteAddr in request struct takes priority (test-friendly path).
				var req1 = {
					remoteAddr: "test-client-1",
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "5.5.5.5"
					}
				};
				var req2 = {
					remoteAddr: "test-client-2",
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "6.6.6.6"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);

				// Both should pass because they have different remoteAddr keys.
				expect(result1).toBe("ok");
				expect(result2).toBe("ok");
			});

		});

	}

}
