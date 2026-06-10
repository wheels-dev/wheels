component extends="wheels.WheelsTest" {

	function run() {

		describe("TokenStrategy", function() {

			describe("getName()", function() {

				it("returns 'token'", function() {
					var strategy = new wheels.auth.TokenStrategy();
					expect(strategy.getName()).toBe("token");
				});

			});

			describe("supports()", function() {

				it("returns true when Authorization Bearer header is present", function() {
					var strategy = new wheels.auth.TokenStrategy();
					var req = {headers = {authorization = "Bearer abc-123"}};
					expect(strategy.supports(req)).toBeTrue();
				});

				it("does not read query param tokens by default", function() {
					var strategy = new wheels.auth.TokenStrategy();
					var req = {params = {api_key = "abc-123"}};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns true when query param is present and explicitly enabled", function() {
					var strategy = new wheels.auth.TokenStrategy(queryParam = "api_key");
					var req = {params = {api_key = "abc-123"}};
					expect(strategy.supports(req)).toBeTrue();
				});

				it("returns false when no token source is present", function() {
					var strategy = new wheels.auth.TokenStrategy();
					var req = {headers = {}, params = {}};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns false for Authorization header with wrong scheme", function() {
					var strategy = new wheels.auth.TokenStrategy();
					var req = {headers = {authorization = "Basic dXNlcjpwYXNz"}};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns true when custom query param is present", function() {
					var strategy = new wheels.auth.TokenStrategy(queryParam = "token");
					var req = {params = {token = "my-token"}};
					expect(strategy.supports(req)).toBeTrue();
				});

				it("returns false when query param check is disabled", function() {
					var strategy = new wheels.auth.TokenStrategy(queryParam = "");
					var req = {params = {api_key = "abc-123"}};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns false when header check is disabled and no query param", function() {
					var strategy = new wheels.auth.TokenStrategy(headerName = "");
					var req = {headers = {authorization = "Bearer abc-123"}};
					expect(strategy.supports(req)).toBeFalse();
				});

			});

			describe("authenticate() with static tokens", function() {

				beforeEach(function() {
					var tokenMap = {
						"valid-key-1" = {id = 1, role = "admin"},
						"valid-key-2" = {id = 2, role = "reader"}
					};
					strategy = new wheels.auth.TokenStrategy(tokens = tokenMap);
				});

				it("succeeds with a valid Bearer token from header", function() {
					var req = {headers = {authorization = "Bearer valid-key-1"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(1);
					expect(result.principal.role).toBe("admin");
					expect(result.strategy).toBe("token");
					expect(result.statusCode).toBe(200);
				});

				it("succeeds with a valid token from an explicitly enabled query param", function() {
					var qpStrategy = new wheels.auth.TokenStrategy(
						tokens = {"valid-key-2" = {id = 2, role = "reader"}},
						queryParam = "api_key"
					);
					var req = {params = {api_key = "valid-key-2"}};
					var result = qpStrategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(2);
					expect(result.principal.role).toBe("reader");
				});

				it("ignores query param tokens by default", function() {
					var req = {params = {api_key = "valid-key-2"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
					expect(result.error).toBe("No token provided");
				});

				it("fails with an invalid token", function() {
					var req = {headers = {authorization = "Bearer wrong-key"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
					expect(result.error).toBe("Invalid or expired token");
					expect(result.statusCode).toBe(401);
					expect(result.strategy).toBe("token");
				});

				it("fails with no token provided", function() {
					var req = {headers = {}, params = {}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
					expect(result.error).toBe("No token provided");
					expect(result.statusCode).toBe(401);
				});

				it("prefers header token over query param", function() {
					var qpStrategy = new wheels.auth.TokenStrategy(
						tokens = {
							"valid-key-1" = {id = 1, role = "admin"},
							"valid-key-2" = {id = 2, role = "reader"}
						},
						queryParam = "api_key"
					);
					var req = {
						headers = {authorization = "Bearer valid-key-1"},
						params = {api_key = "valid-key-2"}
					};
					var result = qpStrategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(1);
				});

			});

			describe("static token case sensitivity", function() {

				it("rejects a token that differs from the configured key only in case", function() {
					var caseStrategy = new wheels.auth.TokenStrategy(
						tokens = {"AbC-123" = {id = 1, role = "admin"}}
					);
					var req = {headers = {authorization = "Bearer abc-123"}};
					var result = caseStrategy.authenticate(req);

					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
				});

				it("accepts a token with the exact configured case", function() {
					var caseStrategy = new wheels.auth.TokenStrategy(
						tokens = {"AbC-123" = {id = 1, role = "admin"}}
					);
					var req = {headers = {authorization = "Bearer AbC-123"}};
					var result = caseStrategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(1);
				});

			});

			describe("authenticate() with validator callback", function() {

				it("succeeds when callback returns a principal struct", function() {
					// Adobe CF cannot parse inline function() inside new constructor calls
					var validatorFn = function(token) {
						if (arguments.token == "good-token") {
							return {id = 99, role = "api"};
						}
						return false;
					};
					var strategy = new wheels.auth.TokenStrategy(validator = validatorFn);

					var req = {headers = {authorization = "Bearer good-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(99);
					expect(result.principal.role).toBe("api");
				});

				it("fails when callback returns false", function() {
					var validatorFn = function(token) {
						return false;
					};
					var strategy = new wheels.auth.TokenStrategy(validator = validatorFn);

					var req = {headers = {authorization = "Bearer any-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
				});

				it("fails when callback returns struct with success=false", function() {
					var validatorFn = function(token) {
						return {success = false, reason = "expired"};
					};
					var strategy = new wheels.auth.TokenStrategy(validator = validatorFn);

					var req = {headers = {authorization = "Bearer expired-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
				});

				it("callback takes priority over static tokens", function() {
					var validatorFn = function(token) {
						return {id = 100, source = "callback"};
					};
					var strategy = new wheels.auth.TokenStrategy(
						validator = validatorFn,
						tokens = {"some-key" = {id = 1, source = "static"}}
					);

					var req = {headers = {authorization = "Bearer some-key"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(100);
					expect(result.principal.source).toBe("callback");
				});

			});

			describe("CGI header fallback", function() {

				it("extracts token from cgi.http_authorization", function() {
					var tokenMap = {"cgi-token" = {id = 5}};
					var strategy = new wheels.auth.TokenStrategy(tokens = tokenMap);

					var req = {cgi = {http_authorization = "Bearer cgi-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(5);
				});

				it("prefers headers struct over cgi fallback", function() {
					var tokenMap = {
						"header-token" = {id = 1, source = "header"},
						"cgi-token" = {id = 2, source = "cgi"}
					};
					var strategy = new wheels.auth.TokenStrategy(tokens = tokenMap);

					var req = {
						headers = {authorization = "Bearer header-token"},
						cgi = {http_authorization = "Bearer cgi-token"}
					};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.source).toBe("header");
				});

			});

			describe("custom configuration", function() {

				it("supports custom query parameter name", function() {
					var tokenMap = {"my-token" = {id = 1}};
					var strategy = new wheels.auth.TokenStrategy(
						tokens = tokenMap,
						queryParam = "access_token"
					);

					var req = {params = {access_token = "my-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
				});

				it("supports custom header name", function() {
					var tokenMap = {"my-token" = {id = 1}};
					var strategy = new wheels.auth.TokenStrategy(
						tokens = tokenMap,
						headerName = "x-api-key",
						scheme = ""
					);

					var req = {headers = {"x-api-key" = "my-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
				});

				it("supports no scheme (raw header value)", function() {
					var tokenMap = {"raw-key" = {id = 1}};
					var strategy = new wheels.auth.TokenStrategy(
						tokens = tokenMap,
						scheme = ""
					);

					var req = {headers = {authorization = "raw-key"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
				});

				it("handles case-insensitive scheme matching", function() {
					var tokenMap = {"my-token" = {id = 1}};
					var strategy = new wheels.auth.TokenStrategy(tokens = tokenMap);

					var req = {headers = {authorization = "bearer my-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
				});

			});

			describe("Authenticator integration", function() {

				it("works when registered with Authenticator", function() {
					var auth = new wheels.auth.Authenticator();
					var tokenMap = {"integration-key" = {id = 10, role = "tester"}};
					auth.registerStrategy(
						name = "token",
						strategy = new wheels.auth.TokenStrategy(tokens = tokenMap)
					);

					var req = {headers = {authorization = "Bearer integration-key"}};
					var result = auth.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(10);
					expect(result.strategy).toBe("token");
				});

				it("falls through to next strategy when no token present", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(
						name = "token",
						strategy = new wheels.auth.TokenStrategy(tokens = {"key" = {id = 1}})
					);
					auth.registerStrategy(
						name = "fallback",
						strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "fallback")
					);

					var req = {headers = {}, params = {}};
					var result = auth.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("fallback");
				});

			});

			describe("edge cases", function() {

				it("rejects empty token string in header", function() {
					var strategy = new wheels.auth.TokenStrategy(
						tokens = {"" = {id = 1}}
					);

					var req = {headers = {authorization = "Bearer "}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
				});

				it("rejects when no validator and no tokens configured", function() {
					var strategy = new wheels.auth.TokenStrategy();

					var req = {headers = {authorization = "Bearer some-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeFalse();
				});

				it("handles missing headers and params structs gracefully", function() {
					var strategy = new wheels.auth.TokenStrategy();
					var req = {};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("reads from urlParams as fallback for an enabled query param", function() {
					var tokenMap = {"url-token" = {id = 7}};
					var strategy = new wheels.auth.TokenStrategy(tokens = tokenMap, queryParam = "api_key");

					var req = {urlParams = {api_key = "url-token"}};
					var result = strategy.authenticate(req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(7);
				});

			});

		});

	}

}
