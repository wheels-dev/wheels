/**
 * Tests for CORS middleware security defaults and origin handling.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CORS middleware", function() {

			it("defaults allowOrigins to empty string", function() {
				local.cors = new wheels.middleware.Cors();
				// With no origins configured and no Origin header, request passes through.
				local.reqCtx = {cgi = {}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "passthrough";
					}
				);
				expect(local.result).toBe("passthrough");
			});

			it("proceeds without CORS headers when allowOrigins is empty and request has Origin header", function() {
				local.cors = new wheels.middleware.Cors();
				local.reqCtx = {cgi = {http_origin = "https://evil.com"}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "proceeded";
					}
				);
				// Middleware passes through without CORS headers; the browser enforces the block.
				expect(local.result).toBe("proceeded");
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

			it("short-circuits OPTIONS preflight with empty string instead of calling next", function() {
				// Cors.handle() prefers request.cgi.request_method (when present)
				// over the engine CGI scope, mirroring its http_origin lookup.
				// If the OPTIONS branch fires, the result is "" (empty body).
				// If the middleware falls through to next(), the closure below
				// would return "should-not-reach" instead.
				local.cors = new wheels.middleware.Cors(allowOrigins = "https://example.com");
				local.reqCtx = {cgi = {request_method = "OPTIONS", http_origin = "https://example.com"}};
				local.result = local.cors.handle(
					request = local.reqCtx,
					next = function(required struct request) {
						return "should-not-reach";
					}
				);
				expect(local.result).toBe("");
			});

			describe("wildcard + credentials validation", function() {

				it("throws when allowOrigins is wildcard and allowCredentials is true", function() {
					expect(function() {
						new wheels.middleware.Cors(allowOrigins = "*", allowCredentials = true);
					}).toThrow("Wheels.Cors.InvalidConfiguration");
				});

				it("includes a descriptive error message for the invalid combination", function() {
					var caught = {};
					try {
						new wheels.middleware.Cors(allowOrigins = "*", allowCredentials = true);
					} catch (any e) {
						caught = e;
					}
					expect(caught).toHaveKey("message");
					expect(caught.message).toInclude("allowOrigins");
					expect(caught.message).toInclude("allowCredentials");
					expect(caught.message).toInclude("CORS specification");
				});

				it("allows wildcard origin with allowCredentials false", function() {
					local.cors = new wheels.middleware.Cors(allowOrigins = "*", allowCredentials = false);
					local.reqCtx = {cgi = {http_origin = "https://any.com"}};
					local.result = local.cors.handle(
						request = local.reqCtx,
						next = function(required struct request) {
							return "ok";
						}
					);
					expect(local.result).toBe("ok");
				});

				it("allows specific origins with allowCredentials true", function() {
					local.cors = new wheels.middleware.Cors(
						allowOrigins = "https://myapp.com",
						allowCredentials = true
					);
					local.reqCtx = {cgi = {http_origin = "https://myapp.com"}};
					local.result = local.cors.handle(
						request = local.reqCtx,
						next = function(required struct request) {
							return "creds-ok";
						}
					);
					expect(local.result).toBe("creds-ok");
				});

			});

		});

	}

}
