/**
 * Regression tests for #3074: the dispatch middleware request context carried
 * no `cgi` member, so the documented patterns reading `req.cgi.*` silently
 * missed — most damagingly a RateLimiter keyFunction reading
 * `req.cgi.http_x_api_key`, which collapsed every client into one shared
 * "anonymous" budget.
 *
 * The context now carries `cgi`: the sanitized `request.cgi` copy (standard
 * keys with the IIS/encoding fixes from $cgiScope) overlaid on the full
 * inbound HTTP header set mapped to CGI-style `http_*` names, so arbitrary
 * headers like `X-Api-Key` resolve per client. These specs drive a real
 * Dispatch through $request so the context-shape regression class is pinned
 * at the dispatch level, not against hand-built request structs.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Middleware request context cgi member (issue 3074)", () => {

			beforeEach(() => {
				// Shallow-copy the middleware array so the restore preserves the
				// original CFC instance references (Adobe CF's Duplicate() deep-clones
				// CFCs inside arrays — CLAUDE.md cross-engine invariant 6).
				_savedMiddleware = (StructKeyExists(application.wheels, "middleware") && ArrayLen(application.wheels.middleware))
					? ArraySlice(application.wheels.middleware, 1) : [];
				_savedRoutes = Duplicate(application.wheels.routes);
				_savedStaticRoutes = StructKeyExists(application.wheels, "staticRoutes")
					? Duplicate(application.wheels.staticRoutes) : {};
				_savedCurrentRoute = StructKeyExists(request.wheels, "currentRoute")
					? request.wheels.currentRoute : "";
				_savedCgiMethod = request.cgi.request_method;
				_hadApiKeyHeader = StructKeyExists(request.cgi, "http_x_api_key");
				application.wheels.routes = [];
				application.wheels.staticRoutes = {};
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
				application.wheels.routes = _savedRoutes;
				application.wheels.staticRoutes = _savedStaticRoutes;
				request.cgi["request_method"] = _savedCgiMethod;
				if (IsStruct(_savedCurrentRoute)) {
					request.wheels.currentRoute = _savedCurrentRoute;
				} else if (StructKeyExists(request.wheels, "currentRoute")) {
					StructDelete(request.wheels, "currentRoute");
				}
				if (!_hadApiKeyHeader && StructKeyExists(request.cgi, "http_x_api_key")) {
					StructDelete(request.cgi, "http_x_api_key");
				}
			});

			it("carries a cgi struct with the sanitized request.cgi keys on the dispatch context", () => {
				var sink = {};
				var capture = new wheels.tests._assets.middleware.ContextCaptureMiddleware(sink = sink);
				application.wheels.middleware = [capture];
				application.wo.mapper().$match(pattern = "mwcgicontext", controller = "test", action = "index").end();

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);
				var result = d.$request(
					pathInfo = "/mwcgicontext", scriptName = "", formScope = {}, urlScope = {}
				);

				expect(result).toBe("ok");
				expect(sink).toHaveKey("context");
				expect(sink.context).toHaveKey("cgi");
				expect(IsStruct(sink.context.cgi)).toBeTrue();
				expect(sink.context.cgi).toHaveKey("request_method");
				expect(sink.context.cgi).toHaveKey("remote_addr");
				expect(sink.context.cgi).toHaveKey("path_info");
				expect(sink.context.cgi.request_method).toBe(request.cgi.request_method);
			});

			it("keys RateLimiter buckets per client when keyFunction reads req.cgi through real dispatch", () => {
				var sink = {};
				var capture = new wheels.tests._assets.middleware.ContextCaptureMiddleware(sink = sink);
				// The documented keyFunction form: read the API key off the context's
				// cgi member, Len-guarded so an empty header value still falls back.
				// Hoisted closure — an inline function literal as a constructor named
				// arg crashes Adobe CF (CLAUDE.md cross-engine invariant 5).
				var apiKeyFn = function(required struct req) {
					var apiKey = arguments.req.cgi.http_x_api_key ?: "";
					return Len(apiKey) ? apiKey : "anonymous";
				};
				var limiter = new wheels.middleware.RateLimiter(
					maxRequests = 1,
					windowSeconds = 600,
					keyFunction = apiKeyFn
				);
				application.wheels.middleware = [limiter, capture];
				application.wo.mapper().$match(pattern = "mwcgilimit", controller = "test", action = "index").end();

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				request.cgi["http_x_api_key"] = "client-a";
				var first = d.$request(pathInfo = "/mwcgilimit", scriptName = "", formScope = {}, urlScope = {});
				var second = d.$request(pathInfo = "/mwcgilimit", scriptName = "", formScope = {}, urlScope = {});

				request.cgi["http_x_api_key"] = "client-b";
				var third = d.$request(pathInfo = "/mwcgilimit", scriptName = "", formScope = {}, urlScope = {});

				expect(first).toBe("ok");
				expect(second).toInclude("Rate limit exceeded");
				// Before #3074 the context had no cgi member, the keyFunction returned
				// "anonymous" for every caller, and client-b's first request was
				// already blocked by client-a's traffic.
				expect(third).toBe("ok");
				expect(sink.context.cgi.http_x_api_key).toBe("client-b");
			});

			it("supplies the cgi member to the CORS preflight short-circuit context", () => {
				var sink = {};
				var capture = new wheels.tests._assets.middleware.ContextCaptureMiddleware(
					sink = sink,
					passThrough = true
				);
				application.wheels.middleware = [capture, new wheels.middleware.Cors(allowOrigins = "*")];
				request.cgi["request_method"] = "OPTIONS";

				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);
				var result = d.$request(
					pathInfo = "/unmatched/preflight", scriptName = "", formScope = {}, urlScope = {}
				);

				expect(result).toBe("");
				expect(sink).toHaveKey("context");
				expect(sink.context).toHaveKey("cgi");
				// Cors.handle reads the verb from the context's cgi member, so the
				// preflight short-circuit now works without engine-scope fallback.
				expect(sink.context.cgi.request_method).toBe("OPTIONS");
			});

			it("maps arbitrary inbound HTTP headers to CGI-style http_ keys with request.cgi winning", () => {
				var d = application.wo.$createObjectFromRoot(
					path = "wheels", fileName = "Dispatch", method = "$init"
				);

				var built = d.$buildMiddlewareCgiScope(headers = {"X-Api-Key": "secret-123", "X-Custom-Trace": "abc"});
				expect(built).toHaveKey("http_x_api_key");
				expect(built.http_x_api_key).toBe("secret-123");
				expect(built).toHaveKey("http_x_custom_trace");
				expect(built.http_x_custom_trace).toBe("abc");
				// The sanitized request.cgi copy keeps the IIS/encoding fixes applied
				// by $cgiScope, so its standard keys win over the raw header snapshot.
				expect(built.path_info).toBe(request.cgi.path_info);

				var spoofed = d.$buildMiddlewareCgiScope(headers = {"X-Forwarded-For": "203.0.113.9"});
				expect(spoofed.http_x_forwarded_for).toBe(request.cgi.http_x_forwarded_for);
			});

		});

	}

}
