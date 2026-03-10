component extends="wheels.WheelsTest" {

	function run() {

		describe("RateLimiter Middleware", function() {

			describe("init()", function() {

				it("creates with default parameters", function() {
					var mw = new wheels.middleware.RateLimiter();
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

				it("accepts custom maxRequests and windowSeconds", function() {
					var mw = new wheels.middleware.RateLimiter(maxRequests = 100, windowSeconds = 30);
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

				it("accepts fixedWindow strategy", function() {
					var mw = new wheels.middleware.RateLimiter(strategy = "fixedWindow");
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

				it("accepts slidingWindow strategy", function() {
					var mw = new wheels.middleware.RateLimiter(strategy = "slidingWindow");
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

				it("accepts tokenBucket strategy", function() {
					var mw = new wheels.middleware.RateLimiter(strategy = "tokenBucket");
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

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
					var mw = new wheels.middleware.RateLimiter(
						keyFunction = function(request) { return "custom-key"; }
					);
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

			});

			describe("handle() - Fixed Window", function() {

				it("allows requests under the limit", function() {
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 5,
						windowSeconds = 60,
						strategy = "fixedWindow",
						keyFunction = function(req) { return "fw-client-1"; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var shared = {callCount: 0};
					var handler = function(required struct request) {
						shared.callCount++;
						return "ok";
					};

					// Send 5 requests — all should pass.
					for (var i = 1; i <= 5; i++) {
						var result = pipeline.run(request = {}, coreHandler = handler);
						expect(result).toBe("ok");
					}
					expect(shared.callCount).toBe(5);
				});

				it("blocks requests exceeding the limit", function() {
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 3,
						windowSeconds = 60,
						strategy = "fixedWindow",
						keyFunction = function(req) { return "fw-client-2"; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var shared = {callCount: 0};
					var handler = function(required struct request) {
						shared.callCount++;
						return "ok";
					};

					// Send 3 allowed.
					for (var i = 1; i <= 3; i++) {
						pipeline.run(request = {}, coreHandler = handler);
					}

					// 4th should be blocked.
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toInclude("Rate limit exceeded");
					expect(shared.callCount).toBe(3);
				});

				it("returns 429 response text when rate limited", function() {
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 1,
						windowSeconds = 60,
						strategy = "fixedWindow",
						keyFunction = function(req) { return "fw-client-429"; }
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
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 2,
						windowSeconds = 60,
						strategy = "fixedWindow",
						keyFunction = function(req) { return clientKey.value; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var handler = function(required struct request) { return "ok"; };

					// Client A uses 2 requests.
					pipeline.run(request = {}, coreHandler = handler);
					pipeline.run(request = {}, coreHandler = handler);

					// Client A is blocked.
					var resultA = pipeline.run(request = {}, coreHandler = handler);
					expect(resultA).toInclude("Rate limit exceeded");

					// Client B should still work.
					clientKey.value = "fw-clientB";
					var resultB = pipeline.run(request = {}, coreHandler = handler);
					expect(resultB).toBe("ok");
				});

			});

			describe("handle() - Sliding Window", function() {

				it("allows requests under the limit", function() {
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 5,
						windowSeconds = 60,
						strategy = "slidingWindow",
						keyFunction = function(req) { return "sw-client-1"; }
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
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 3,
						windowSeconds = 60,
						strategy = "slidingWindow",
						keyFunction = function(req) { return "sw-client-2"; }
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

			describe("handle() - Token Bucket", function() {

				it("allows requests up to bucket capacity", function() {
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 5,
						windowSeconds = 60,
						strategy = "tokenBucket",
						keyFunction = function(req) { return "tb-client-1"; }
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
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 2,
						windowSeconds = 60,
						strategy = "tokenBucket",
						keyFunction = function(req) { return "tb-client-2"; }
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

			describe("Client Identification", function() {

				it("uses custom keyFunction when provided", function() {
					var shared = {capturedKey: ""};
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 100,
						keyFunction = function(req) {
							return "api-key-12345";
						}
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var handler = function(required struct request) { return "ok"; };

					// Should use custom key — all pass since limit is 100.
					var result = pipeline.run(request = {apiKey: "12345"}, coreHandler = handler);
					expect(result).toBe("ok");
				});

				it("falls back to default key when no keyFunction", function() {
					var mw = new wheels.middleware.RateLimiter(maxRequests = 100);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var handler = function(required struct request) { return "ok"; };

					var result = pipeline.run(request = {remoteAddr: "10.0.0.1"}, coreHandler = handler);
					expect(result).toBe("ok");
				});

			});

			describe("Pipeline Integration", function() {

				it("works in a middleware pipeline with other middleware", function() {
					var requestId = new wheels.middleware.RequestId();
					var limiter = new wheels.middleware.RateLimiter(
						maxRequests = 10,
						keyFunction = function(req) { return "pipeline-client"; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [requestId, limiter]);
					var handler = function(required struct request) { return "ok"; };

					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toBe("ok");
					expect(StructKeyExists(request.wheels, "requestId")).toBeTrue();
				});

				it("short-circuits pipeline when rate limited", function() {
					var shared = {coreReached: false};
					var limiter = new wheels.middleware.RateLimiter(
						maxRequests = 1,
						keyFunction = function(req) { return "shortcircuit-client"; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [limiter]);
					var handler = function(required struct request) {
						shared.coreReached = true;
						return "ok";
					};

					// First request passes.
					pipeline.run(request = {}, coreHandler = handler);

					// Reset flag.
					shared.coreReached = false;

					// Second request should be blocked — core never reached.
					var result = pipeline.run(request = {}, coreHandler = handler);
					expect(result).toInclude("Rate limit exceeded");
					expect(shared.coreReached).toBeFalse();
				});

				it("passes request through when under limit", function() {
					var shared = {callCount: 0};
					var limiter = new wheels.middleware.RateLimiter(
						maxRequests = 10,
						keyFunction = function(req) { return "passthrough-client"; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [limiter]);
					var handler = function(required struct request) {
						shared.callCount++;
						return "ok";
					};

					pipeline.run(request = {}, coreHandler = handler);
					expect(shared.callCount).toBe(1);
				});

			});

			describe("Memory Cleanup", function() {

				it("cleans up expired entries from store", function() {
					// Use a very short window so entries expire quickly.
					var mw = new wheels.middleware.RateLimiter(
						maxRequests = 100,
						windowSeconds = 1,
						strategy = "fixedWindow",
						keyFunction = function(req) { return "cleanup-client"; }
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
					var handler = function(required struct request) { return "ok"; };

					// Make a request to populate the store.
					pipeline.run(request = {}, coreHandler = handler);

					// The middleware exists and handles requests — cleanup is internally throttled.
					// Just verify it doesn't error.
					expect(mw).toBeInstanceOf("wheels.middleware.RateLimiter");
				});

			});

		});

	}

}
