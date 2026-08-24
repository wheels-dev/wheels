/**
 * Hardener SHOULDs S1–S7 (middleware pipeline).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * Escalations (no silent public default/API flips):
 *   S2 AuthMiddleware default 401 body still emits authResult.error.
 *      genericErrors=true is opt-in.
 *   S5 TenantResolver unmatched still proceeds on the default datasource.
 *      failClosed=true is opt-in.
 *
 * CoS lock: Cors allowOrigins="" / allowCredentials=false,
 * RateLimiter failOpen=false / trustProxy=false,
 * AuthMiddleware allowAnonymous=false,
 * SecurityHeaders SAMEORIGIN + nosniff.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CoS lock: middleware public defaults stay conservative", function() {

			it("keeps Cors allowOrigins empty and allowCredentials false", function() {
				var src = FileRead(ExpandPath("/wheels/middleware/Cors.cfc"));
				expect(FindNoCase("string allowOrigins = """"", src)).toBeGT(0);
				expect(FindNoCase("boolean allowCredentials = false", src)).toBeGT(0);

				var cors = new wheels.middleware.Cors();
				expect(cors.$resolveAllowOrigin("https://evil.example")).toBe("");
			});

			it("keeps RateLimiter failOpen and trustProxy false", function() {
				var src = FileRead(ExpandPath("/wheels/middleware/RateLimiter.cfc"));
				expect(FindNoCase("boolean trustProxy = false", src)).toBeGT(0);
				expect(FindNoCase("boolean failOpen = false", src)).toBeGT(0);
			});

			it("keeps AuthMiddleware allowAnonymous false", function() {
				var src = FileRead(ExpandPath("/wheels/middleware/AuthMiddleware.cfc"));
				expect(FindNoCase("boolean allowAnonymous = false", src)).toBeGT(0);
			});

			it("keeps SecurityHeaders SAMEORIGIN and nosniff", function() {
				var mw = new wheels.middleware.SecurityHeaders();
				var headers = mw.$headers();
				expect(headers["X-Frame-Options"]).toBe("SAMEORIGIN");
				expect(headers["X-Content-Type-Options"]).toBe("nosniff");
			});

		});

		describe("S1 TenantResolver docs use 2-arg where", function() {

			it("TenantResolver.cfc usage sample does not interpolate subdomain into SQL", function() {
				var src = FileRead(ExpandPath("/wheels/middleware/TenantResolver.cfc"));
				// Build the forbidden interpolation without putting a raw ## pair
				// that CFML would treat as an empty expression in this spec.
				var interpolatedWhere = "subdomain=" & Chr(39) & "##subdomain##" & Chr(39);
				expect(FindNoCase(interpolatedWhere, src)).toBe(
					0,
					"TenantResolver docs must not show where=""subdomain='##subdomain##'"""
				);
			});

			it("TenantResolver.cfc usage sample binds subdomain through 2-arg where", function() {
				var src = FileRead(ExpandPath("/wheels/middleware/TenantResolver.cfc"));
				expect(FindNoCase("where(""subdomain""", src)).toBeGT(
					0,
					"TenantResolver docs must show the 2-arg query builder where(""subdomain"", ...)"
				);
			});

		});

		describe("S2 AuthMiddleware JSON error is opt-in generic", function() {

			it("default 401 body still emits authResult.error (no silent contract flip)", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
				var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
					return "should-not-reach";
				});
				var parsed = DeserializeJSON(result);
				expect(parsed.error).toBe("Invalid credentials");
				expect(parsed.status).toBe(401);
			});

			it("genericErrors=true emits a generic Unauthorized body", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
				var mw = new wheels.middleware.AuthMiddleware(
					authenticator = auth,
					genericErrors = true
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
					return "should-not-reach";
				});
				var parsed = DeserializeJSON(result);
				expect(parsed.error).toBe("Unauthorized");
				expect(parsed.status).toBe(401);
				expect(FindNoCase("Invalid credentials", result)).toBe(0);
			});

			it("genericErrors=true does not leak unregistered-strategy diagnostics", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());
				var mw = new wheels.middleware.AuthMiddleware(
					authenticator = auth,
					strategies = "ghost,pass",
					genericErrors = true
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
					return "should-not-reach";
				});
				var parsed = DeserializeJSON(result);
				expect(parsed.error).toBe("Unauthorized");
				expect(FindNoCase("ghost", result)).toBe(0);
				expect(FindNoCase("unregistered strategy", result)).toBe(0);
			});

		});

		describe("S3 Pipeline.getMiddleware() returns a copy", function() {

			it("mutating the returned array does not change the live stack", function() {
				var shared = {order = []};
				var mwA = new wheels.tests.specs.middleware._helpers.TrackingMiddleware(id = "A", tracker = shared);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mwA]);
				var exposed = pipeline.getMiddleware();
				var leak = new wheels.tests.specs.middleware._helpers.TrackingMiddleware(id = "LEAK", tracker = shared);
				ArrayAppend(exposed, leak);

				var handler = function(required struct request) {
					ArrayAppend(shared.order, "core");
					return "ok";
				};
				pipeline.run(request = {}, coreHandler = handler);

				expect(ArrayLen(pipeline.getMiddleware())).toBe(1);
				expect(ArrayToList(shared.order)).toBe("before:A,core,after:A");
			});

			it("deleting from the returned array does not empty the live stack", function() {
				var mw = new wheels.middleware.RequestId();
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var exposed = pipeline.getMiddleware();
				ArrayDeleteAt(exposed, 1);
				expect(ArrayLen(pipeline.getMiddleware())).toBe(1);
			});

		});

		describe("S4 RateLimiter $getClientIp honors trustProxy before remoteAddr", function() {

			it("does not let request.remoteAddr override X-Forwarded-For when trustProxy is true", function() {
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 60,
					trustProxy = true
				);
				var nextFn = function(req) {
					return "ok";
				};
				var req1 = {
					remoteAddr: "spoof-1",
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "203.0.113.10"
					}
				};
				var req2 = {
					remoteAddr: "spoof-2",
					cgi: {
						remote_addr: "10.0.0.1",
						http_x_forwarded_for: "203.0.113.10"
					}
				};
				expect(limiter.handle(request = req1, next = nextFn)).toBe("ok");
				expect(limiter.handle(request = req2, next = nextFn)).toInclude("Rate limit exceeded");
			});

			it("still uses request.remoteAddr when trustProxy is false", function() {
				var limiter = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);
				var nextFn = function(req) {
					return "ok";
				};
				var req1 = {
					remoteAddr: "test-a",
					cgi: {remote_addr: "10.0.0.1", http_x_forwarded_for: "1.1.1.1"}
				};
				var req2 = {
					remoteAddr: "test-b",
					cgi: {remote_addr: "10.0.0.1", http_x_forwarded_for: "1.1.1.1"}
				};
				expect(limiter.handle(request = req1, next = nextFn)).toBe("ok");
				expect(limiter.handle(request = req2, next = nextFn)).toBe("ok");
			});

		});

		describe("S5 TenantResolver unmatched fail-closed is opt-in", function() {

			afterEach(function() {
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}
			});

			it("default unmatched still proceeds on the default datasource", function() {
				var emptyResolver = function(req) {
					return {};
				};
				var mw = new wheels.middleware.TenantResolver(resolver = emptyResolver);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = {called = false, hasTenant = false};
				var handler = function(required struct request) {
					result.called = true;
					result.hasTenant = IsDefined("request.wheels.tenant");
					return "proceeded";
				};
				var body = pipeline.run(request = {cgi = {}}, coreHandler = handler);
				expect(body).toBe("proceeded");
				expect(result.called).toBeTrue();
				expect(result.hasTenant).toBeFalse();
			});

			it("failClosed=true short-circuits unmatched tenants with 403", function() {
				var emptyResolver = function(req) {
					return {};
				};
				var mw = new wheels.middleware.TenantResolver(
					resolver = emptyResolver,
					failClosed = true
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = {called = false};
				var handler = function(required struct request) {
					result.called = true;
					return "should-not-reach";
				};
				var body = pipeline.run(request = {cgi = {}}, coreHandler = handler);
				expect(result.called).toBeFalse();
				expect(body).toBe("Forbidden");
			});

			it("failClosed=true still proceeds when a tenant resolves", function() {
				var matchedResolver = function(req) {
					return {id = "t1", dataSource = "tenant_one_ds"};
				};
				var mw = new wheels.middleware.TenantResolver(
					resolver = matchedResolver,
					failClosed = true
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = {called = false, tenantId = ""};
				var handler = function(required struct request) {
					result.called = true;
					if (IsDefined("request.wheels.tenant")) {
						result.tenantId = request.wheels.tenant.id;
					}
					return "ok";
				};
				var body = pipeline.run(request = {cgi = {}}, coreHandler = handler);
				expect(body).toBe("ok");
				expect(result.called).toBeTrue();
				expect(result.tenantId).toBe("t1");
			});

		});

		describe("S6 MiddlewareOrderResolver cycle fails closed", function() {

			it("throws instead of falling back to priority-only order", function() {
				var resolver = new wheels.middleware.MiddlewareOrderResolver();
				var entries = [
					{
						middleware = "test.middleware.A",
						options = {name = "A", priority = 1, before = "B"},
						pluginName = "pluginA"
					},
					{
						middleware = "test.middleware.B",
						options = {name = "B", priority = 2, before = "A"},
						pluginName = "pluginB"
					}
				];
				var state = {threw = false, type = ""};
				try {
					resolver.resolve(entries);
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Middleware.CircularDependency");
			});

		});

		describe("S7 Cors OPTIONS without ACAO is not a cached success", function() {

			it("default allowOrigins does not short-circuit OPTIONS as empty success", function() {
				var cors = new wheels.middleware.Cors();
				var reqCtx = {cgi = {request_method = "OPTIONS", http_origin = "https://evil.example"}};
				var result = cors.handle(
					request = reqCtx,
					next = function(required struct request) {
						return "passthrough";
					}
				);
				expect(result).toBe("passthrough");
			});

			it("unmatched origin does not short-circuit OPTIONS as empty success", function() {
				var cors = new wheels.middleware.Cors(allowOrigins = "https://myapp.example");
				var reqCtx = {cgi = {request_method = "OPTIONS", http_origin = "https://evil.example"}};
				var result = cors.handle(
					request = reqCtx,
					next = function(required struct request) {
						return "passthrough";
					}
				);
				expect(result).toBe("passthrough");
			});

			it("matched origin still short-circuits OPTIONS with an empty body", function() {
				var cors = new wheels.middleware.Cors(allowOrigins = "https://myapp.example");
				var reqCtx = {cgi = {request_method = "OPTIONS", http_origin = "https://myapp.example"}};
				var result = cors.handle(
					request = reqCtx,
					next = function(required struct request) {
						return "should-not-reach";
					}
				);
				expect(result).toBe("");
			});

			it("emits Max-Age on OPTIONS only when ACAO is present", function() {
				var cors = new wheels.middleware.Cors(allowOrigins = "https://myapp.example");
				var allowed = cors.$headersFor(
					request = {cgi = {request_method = "OPTIONS", http_origin = "https://myapp.example"}}
				);
				expect(allowed).toHaveKey("Access-Control-Allow-Origin");
				expect(allowed).toHaveKey("Access-Control-Max-Age");
				expect(allowed["Access-Control-Max-Age"]).toBe(86400);

				var denied = cors.$headersFor(
					request = {cgi = {request_method = "OPTIONS", http_origin = "https://evil.example"}}
				);
				expect(denied).notToHaveKey("Access-Control-Allow-Origin");
				expect(denied).notToHaveKey("Access-Control-Max-Age");
			});

			it("does not emit Max-Age on a non-OPTIONS request", function() {
				var cors = new wheels.middleware.Cors(allowOrigins = "https://myapp.example");
				var headers = cors.$headersFor(
					request = {cgi = {request_method = "GET", http_origin = "https://myapp.example"}}
				);
				expect(headers).toHaveKey("Access-Control-Allow-Origin");
				expect(headers).notToHaveKey("Access-Control-Max-Age");
			});

		});

	}

}
