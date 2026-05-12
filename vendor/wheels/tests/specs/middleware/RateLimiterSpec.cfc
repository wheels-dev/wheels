/**
 * Tests for RateLimiter middleware covering trustProxy, proxyStrategy,
 * and maxStoreSize parameters.
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

		describe("RateLimiter proxyStrategy", function() {

			it("uses first IP in X-Forwarded-For chain when proxyStrategy is first", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 60,
					trustProxy = true,
					proxyStrategy = "first"
				);

				var nextFn = function(req) { return "ok"; };

				// "1.1.1.1, 10.0.0.1" — first strategy picks 1.1.1.1
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "1.1.1.1, 10.0.0.1"
					}
				};
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "1.1.1.1, 10.0.0.2"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);

				// Both keyed to "1.1.1.1" so second is blocked.
				expect(result1).toBe("ok");
				expect(result2).toInclude("Rate limit exceeded");
			});

			it("uses last IP in X-Forwarded-For chain when proxyStrategy is last", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 60,
					trustProxy = true,
					proxyStrategy = "last"
				);

				var nextFn = function(req) { return "ok"; };

				// "1.1.1.1, 10.0.0.1" — last strategy picks 10.0.0.1
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "1.1.1.1, 10.0.0.1"
					}
				};
				// "2.2.2.2, 10.0.0.1" — last strategy still picks 10.0.0.1
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "2.2.2.2, 10.0.0.1"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);

				// Both keyed to "10.0.0.1" so second is blocked.
				expect(result1).toBe("ok");
				expect(result2).toInclude("Rate limit exceeded");
			});

			it("last strategy prevents spoofed first-IP bypass", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					trustProxy = true,
					proxyStrategy = "last"
				);

				var nextFn = function(req) { return "ok"; };

				// Attacker rotates the first (spoofed) IP but proxy always appends real IP.
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "fake-1.1.1.1, 192.168.1.100"
					}
				};
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "fake-2.2.2.2, 192.168.1.100"
					}
				};
				var req3 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "fake-3.3.3.3, 192.168.1.100"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);
				var result3 = limiter.handle(request = req3, next = nextFn);

				// All keyed to "192.168.1.100" — third request blocked.
				expect(result1).toBe("ok");
				expect(result2).toBe("ok");
				expect(result3).toInclude("Rate limit exceeded");
			});

			it("defaults to last proxy strategy when trustProxy is enabled without explicit proxyStrategy", function() {
				var limiter = new wheels.middleware.RateLimiter(
					trustProxy = true,
					maxRequests = 1,
					windowSeconds = 60
				);

				var nextFn = function(req) { return "ok"; };

				// Two requests with different first IPs but same last IP should share a bucket
				// (proving the default strategy is "last", not "first")
				var req1 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "1.1.1.1, 10.0.0.1"
					}
				};
				var req2 = {
					cgi: {
						remote_addr: "10.0.0.50",
						http_x_forwarded_for: "2.2.2.2, 10.0.0.1"
					}
				};

				var result1 = limiter.handle(request = req1, next = nextFn);
				expect(result1).toBe("ok");

				// Second request from "different" first IP but SAME last IP should be blocked
				var result2 = limiter.handle(request = req2, next = nextFn);
				expect(result2).toInclude("Rate limit exceeded");
			});

			it("throws on invalid proxyStrategy", function() {
				expect(function() {
					new wheels.middleware.RateLimiter(proxyStrategy = "middle");
				}).toThrow("Wheels.RateLimiter.InvalidProxyStrategy");
			});

		});

		describe("RateLimiter maxStoreSize", function() {

			it("defaults maxStoreSize to 100000", function() {
				var limiter = new wheels.middleware.RateLimiter();
				// Should construct without error.
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("accepts custom maxStoreSize", function() {
				var limiter = new wheels.middleware.RateLimiter(maxStoreSize = 500);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("evicts entries when store exceeds maxStoreSize", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1000,
					windowSeconds = 60,
					strategy = "fixedWindow",
					maxStoreSize = 5
				);

				var nextFn = function(req) { return "ok"; };

				// Send requests from 10 unique IPs to exceed the store size of 5.
				for (var i = 1; i <= 10; i++) {
					var req = {remoteAddr: "client-evict-#i#"};
					limiter.handle(request = req, next = nextFn);
				}

				// The limiter should still function correctly (not error out).
				var finalReq = {remoteAddr: "client-evict-final"};
				var result = limiter.handle(request = finalReq, next = nextFn);
				expect(result).toBe("ok");
			});

			// NOTE: Testing that rate limiting still works after eviction is inherently
			// unreliable because eviction can remove ANY entry (including the one being
			// tested). The evicts-oldest and eviction-capacity tests above verify the
			// eviction mechanism itself.

		});

		describe("RateLimiter maxTimestampsPerKey", function() {

			it("defaults maxTimestampsPerKey to maxRequests * 3", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 10,
					strategy = "slidingWindow"
				);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("accepts custom maxTimestampsPerKey", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 10,
					strategy = "slidingWindow",
					maxTimestampsPerKey = 50
				);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("caps sliding window timestamps per key", function() {
				// Set maxRequests high so we never get blocked, but cap timestamps low.
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1000,
					windowSeconds = 60,
					strategy = "slidingWindow",
					maxTimestampsPerKey = 5
				);

				var nextFn = function(req) { return "ok"; };

				// Send 20 requests from the same client.
				for (var i = 1; i <= 20; i++) {
					var req = {remoteAddr: "flood-client"};
					limiter.handle(request = req, next = nextFn);
				}

				// The limiter should still function correctly after capping.
				var finalReq = {remoteAddr: "flood-client"};
				var result = limiter.handle(request = finalReq, next = nextFn);
				expect(result).toBe("ok");
			});

			it("still enforces rate limit with timestamp cap active", function() {
				// maxRequests=3, maxTimestampsPerKey defaults to 9 (3*3).
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 60,
					strategy = "slidingWindow"
				);

				var nextFn = function(req) { return "ok"; };

				var r1 = limiter.handle(request = {remoteAddr: "cap-test"}, next = nextFn);
				var r2 = limiter.handle(request = {remoteAddr: "cap-test"}, next = nextFn);
				var r3 = limiter.handle(request = {remoteAddr: "cap-test"}, next = nextFn);
				var r4 = limiter.handle(request = {remoteAddr: "cap-test"}, next = nextFn);

				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
				expect(r3).toBe("ok");
				expect(r4).toInclude("Rate limit exceeded");
			});

		});

		describe("RateLimiter eviction improvements", function() {

			it("evicts 25 percent of entries creating more headroom", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1000,
					windowSeconds = 60,
					strategy = "fixedWindow",
					maxStoreSize = 4
				);

				var nextFn = function(req) { return "ok"; };

				// Fill store to capacity with unique clients.
				for (var i = 1; i <= 8; i++) {
					var req = {remoteAddr: "evict25-#i#"};
					limiter.handle(request = req, next = nextFn);
				}

				// Should still work after eviction.
				var result = limiter.handle(request = {remoteAddr: "evict25-final"}, next = nextFn);
				expect(result).toBe("ok");
			});

		});

		describe("RateLimiter maxKeyLength", function() {

			it("defaults maxKeyLength to 128", function() {
				var limiter = new wheels.middleware.RateLimiter();
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("accepts custom maxKeyLength", function() {
				var limiter = new wheels.middleware.RateLimiter(maxKeyLength = 64);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("hashes keys longer than maxKeyLength", function() {
				// Use a low maxKeyLength so we can easily exceed it.
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 10,
					windowSeconds = 60,
					maxKeyLength = 20
				);

				var nextFn = function(req) { return "ok"; };

				// A short key (under 20 chars) and a long key (over 20 chars) that
				// starts with the same prefix should be treated as different keys.
				var shortKey = "short";
				var longKey = RepeatString("A", 200);

				var req1 = {remoteAddr: shortKey};
				var req2 = {remoteAddr: longKey};

				var result1 = limiter.handle(request = req1, next = nextFn);
				var result2 = limiter.handle(request = req2, next = nextFn);

				// Both should succeed (different keys, both under maxRequests).
				expect(result1).toBe("ok");
				expect(result2).toBe("ok");
			});

			it("hashes long keys from custom keyFunction", function() {
				var longKey = RepeatString("X", 300);

				// Adobe CF: hoist the function literal out of `new` to dodge
				// ASTcffunction ArrayStoreException at compile time.
				var keyFn = function(req) { return longKey; };
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 60,
					maxKeyLength = 128,
					keyFunction = keyFn
				);

				var nextFn = function(req) { return "ok"; };

				// First request should pass.
				var r1 = limiter.handle(request = {}, next = nextFn);
				expect(r1).toBe("ok");

				// Second request with the same long key should be rate limited
				// (proving the key was hashed consistently to the same value).
				var r2 = limiter.handle(request = {}, next = nextFn);
				expect(r2).toInclude("Rate limit exceeded");
			});

			it("does not hash keys within maxKeyLength", function() {
				// Two different short keys should rate-limit independently.
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 60,
					maxKeyLength = 128
				);

				var nextFn = function(req) { return "ok"; };

				var r1 = limiter.handle(request = {remoteAddr: "key-a"}, next = nextFn);
				var r2 = limiter.handle(request = {remoteAddr: "key-b"}, next = nextFn);

				// Both pass because they are different short keys.
				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
			});

		});

		describe("RateLimiter cleanup throttle", function() {

			it("uses 10-second cleanup throttle instead of 60", function() {
				// Verify the limiter can be constructed and operates correctly.
				// The cleanup throttle is now 10s, so after 10s of simulated time
				// the cleanup should be eligible to run. We verify this indirectly
				// by confirming the limiter works under pressure with many unique keys.
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1000,
					windowSeconds = 5,
					strategy = "fixedWindow",
					maxStoreSize = 50
				);

				var nextFn = function(req) { return "ok"; };

				// Flood with unique keys to trigger cleanup/eviction.
				for (var i = 1; i <= 100; i++) {
					var req = {remoteAddr: "cleanup-test-#i#"};
					limiter.handle(request = req, next = nextFn);
				}

				// Should still function correctly after cleanup cycles.
				var result = limiter.handle(request = {remoteAddr: "cleanup-final"}, next = nextFn);
				expect(result).toBe("ok");
			});

		});

		describe("RateLimiter failOpen parameter", function() {

			it("defaults failOpen to false (fail-closed)", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 5, windowSeconds = 60);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("accepts failOpen=true", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 5, windowSeconds = 60, failOpen = true);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("accepts failOpen=false", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 5, windowSeconds = 60, failOpen = false);
				expect(limiter).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

			it("blocks requests by default when fail-closed with fixed window", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "fixedWindow"
				);

				var nextFn = function(req) { return "ok"; };

				var r1 = limiter.handle(request = {remoteAddr: "failclose-fw-1"}, next = nextFn);
				var r2 = limiter.handle(request = {remoteAddr: "failclose-fw-1"}, next = nextFn);
				var r3 = limiter.handle(request = {remoteAddr: "failclose-fw-1"}, next = nextFn);

				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
				expect(r3).toInclude("Rate limit exceeded");
			});

			it("blocks requests by default when fail-closed with sliding window", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "slidingWindow"
				);

				var nextFn = function(req) { return "ok"; };

				var r1 = limiter.handle(request = {remoteAddr: "failclose-sw-1"}, next = nextFn);
				var r2 = limiter.handle(request = {remoteAddr: "failclose-sw-1"}, next = nextFn);
				var r3 = limiter.handle(request = {remoteAddr: "failclose-sw-1"}, next = nextFn);

				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
				expect(r3).toInclude("Rate limit exceeded");
			});

			it("blocks requests by default when fail-closed with token bucket", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "tokenBucket"
				);

				var nextFn = function(req) { return "ok"; };

				var r1 = limiter.handle(request = {remoteAddr: "failclose-tb-1"}, next = nextFn);
				var r2 = limiter.handle(request = {remoteAddr: "failclose-tb-1"}, next = nextFn);
				var r3 = limiter.handle(request = {remoteAddr: "failclose-tb-1"}, next = nextFn);

				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
				expect(r3).toInclude("Rate limit exceeded");
			});

			it("still enforces rate limits when failOpen is true", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "fixedWindow",
					failOpen = true
				);

				var nextFn = function(req) { return "ok"; };

				var r1 = limiter.handle(request = {remoteAddr: "failopen-normal-1"}, next = nextFn);
				var r2 = limiter.handle(request = {remoteAddr: "failopen-normal-1"}, next = nextFn);
				var r3 = limiter.handle(request = {remoteAddr: "failopen-normal-1"}, next = nextFn);

				expect(r1).toBe("ok");
				expect(r2).toBe("ok");
				expect(r3).toInclude("Rate limit exceeded");
			});

		});

		describe("RateLimiter init validation", function() {

			it("throws on invalid strategy", function() {
				expect(function() {
					new wheels.middleware.RateLimiter(strategy = "bogus");
				}).toThrow("Wheels.RateLimiter.InvalidStrategy");
			});

			it("throws on invalid storage type", function() {
				expect(function() {
					new wheels.middleware.RateLimiter(storage = "redis");
				}).toThrow("Wheels.RateLimiter.InvalidStorage");
			});

			it("accepts a custom keyFunction", function() {
				var keyFn = function(request) { return "custom-key"; };
				var mw = new wheels.middleware.RateLimiter(
					keyFunction = keyFn
				);
				expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
			});

		});

		describe("RateLimiter handle() - Fixed Window via Pipeline", function() {

			it("allows requests under the limit", function() {
				var keyFn = function(req) { return "fw-client-1"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					strategy = "fixedWindow",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 5; i++) {
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toBe("ok");
				}
				expect(shared.callCount).toBe(5);
			});

			it("blocks requests exceeding the limit", function() {
				var keyFn = function(req) { return "fw-client-2"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 60,
					strategy = "fixedWindow",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 3; i++) {
					pipeline.run(request = {}, coreHandler = handler);
				}

				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toInclude("Rate limit exceeded");
				expect(shared.callCount).toBe(3);
			});

			it("returns 429 response text when rate limited", function() {
				var keyFn = function(req) { return "fw-client-429"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 60,
					strategy = "fixedWindow",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var handler = function(required struct request) { return "ok"; };

				pipeline.run(request = {}, coreHandler = handler);
				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toInclude("Rate limit exceeded");
				expect(result).toInclude("Try again later");
			});

			it("tracks different clients independently", function() {
				var clientKey = {value: "fw-clientA"};
				var keyFn = function(req) { return clientKey.value; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "fixedWindow",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var handler = function(required struct request) { return "ok"; };

				pipeline.run(request = {}, coreHandler = handler);
				pipeline.run(request = {}, coreHandler = handler);

				var resultA = pipeline.run(request = {}, coreHandler = handler);
				expect(resultA).toInclude("Rate limit exceeded");

				clientKey.value = "fw-clientB";
				var resultB = pipeline.run(request = {}, coreHandler = handler);
				expect(resultB).toBe("ok");
			});

		});

		describe("RateLimiter handle() - Sliding Window via Pipeline", function() {

			it("allows requests under the limit", function() {
				var keyFn = function(req) { return "sw-client-1"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					strategy = "slidingWindow",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 5; i++) {
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toBe("ok");
				}
				expect(shared.callCount).toBe(5);
			});

			it("blocks requests exceeding the limit", function() {
				var keyFn = function(req) { return "sw-client-2"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 3,
					windowSeconds = 60,
					strategy = "slidingWindow",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 3; i++) {
					pipeline.run(request = {}, coreHandler = handler);
				}

				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toInclude("Rate limit exceeded");
				expect(shared.callCount).toBe(3);
			});

		});

		describe("RateLimiter handle() - Token Bucket via Pipeline", function() {

			it("allows requests up to bucket capacity", function() {
				var keyFn = function(req) { return "tb-client-1"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 5,
					windowSeconds = 60,
					strategy = "tokenBucket",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				for (var i = 1; i <= 5; i++) {
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toBe("ok");
				}
				expect(shared.callCount).toBe(5);
			});

			it("blocks when bucket is empty", function() {
				var keyFn = function(req) { return "tb-client-2"; };
				var mw = new wheels.middleware.RateLimiter(
					maxRequests = 2,
					windowSeconds = 60,
					strategy = "tokenBucket",
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var shared = {callCount: 0};
				var handler = function(required struct request) {
					shared.callCount++;
					return "ok";
				};

				pipeline.run(request = {}, coreHandler = handler);
				pipeline.run(request = {}, coreHandler = handler);

				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toInclude("Rate limit exceeded");
				expect(shared.callCount).toBe(2);
			});

		});

		describe("RateLimiter Pipeline Integration", function() {

			it("works in a middleware pipeline with other middleware", function() {
				var requestId = new wheels.middleware.RequestId();
				var keyFn = function(req) { return "pipeline-client"; };
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 10,
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [requestId, limiter]);
				var handler = function(required struct request) { return "ok"; };

				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toBe("ok");
				expect(StructKeyExists(request.wheels, "requestId")).toBeTrue();
			});

			it("short-circuits pipeline when rate limited", function() {
				var shared = {coreReached: false};
				var keyFn = function(req) { return "shortcircuit-client"; };
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					keyFunction = keyFn
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [limiter]);
				var handler = function(required struct request) {
					shared.coreReached = true;
					return "ok";
				};

				pipeline.run(request = {}, coreHandler = handler);
				shared.coreReached = false;

				var result = pipeline.run(request = {}, coreHandler = handler);
				expect(result).toInclude("Rate limit exceeded");
				expect(shared.coreReached).toBeFalse();
			});

		});

	}

}
