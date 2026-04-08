/**
 * Tests for CORS middleware security defaults and origin handling.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CORS middleware", function() {

			it("defaults allowOrigins to empty string", function() {
				local.cors = new wheels.middleware.Cors();
				// With no origins configured and no Origin header, request passes through.
				local.reqCtx = {};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "passthrough";
					}
				);
				expect(local.result).toBe("passthrough");
			});

			it("returns empty response when allowOrigins is empty and request has Origin header", function() {
				local.cors = new wheels.middleware.Cors();
				local.reqCtx = {cgi = {http_origin = "https://evil.com"}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "should-not-reach";
					}
				);
				// Should block the request, returning empty string (403).
				expect(local.result).toBe("");
			});

			it("does not call next when allowOrigins is empty and Origin is present", function() {
				local.cors = new wheels.middleware.Cors();
				local.reqCtx = {cgi = {http_origin = "https://attacker.com"}};
				var tracker = {nextCalled = false};
				local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						tracker.nextCalled = true;
						return "reached";
					}
				);
				expect(tracker.nextCalled).toBeFalse();
			});

			it("allows requests when origin matches explicit allowOrigins", function() {
				local.cors = new wheels.middleware.Cors(allowOrigins = "https://myapp.com");
				local.reqCtx = {cgi = {http_origin = "https://myapp.com"}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "allowed";
					}
				);
				expect(local.result).toBe("allowed");
			});

			it("proceeds without CORS headers when origin does not match explicit allowOrigins", function() {
				local.cors = new wheels.middleware.Cors(allowOrigins = "https://myapp.com");
				local.reqCtx = {cgi = {http_origin = "https://evil.com"}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "proceeded";
					}
				);
				// Request proceeds but without CORS headers; the browser enforces the block.
				expect(local.result).toBe("proceeded");
			});

			it("allows wildcard origin when explicitly configured", function() {
				local.cors = new wheels.middleware.Cors(allowOrigins = "*");
				local.reqCtx = {cgi = {http_origin = "https://anything.com"}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "wildcard-ok";
					}
				);
				expect(local.result).toBe("wildcard-ok");
			});

			it("passes through requests with no Origin header even when allowOrigins is empty", function() {
				local.cors = new wheels.middleware.Cors();
				local.reqCtx = {cgi = {}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "same-origin";
					}
				);
				expect(local.result).toBe("same-origin");
			});

		});

	}

}
