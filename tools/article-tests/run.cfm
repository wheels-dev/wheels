<cfscript>
// Test harness that exercises every claim made in the blog post
// "Skip the Plugin: Building a Rate-Limited API in Wheels 4.0".
// Runs against the live middleware code in vendor/wheels/middleware/.
//
// Run via tools/article-tests/run.sh (recommended). For a manual
// invocation from the repo root, use:
//   boxlang --bx-config tools/article-tests/boxlang.json tools/article-tests/run.cfm
// The --bx-config flag is required so the /wheels mapping resolves;
// without it dotted-path imports like wheels.middleware.RateLimiter fail.

results = {pass: 0, fail: 0, errors: []};

function test(name, body) {
    try {
        body();
        results.pass++;
        writeOutput("  PASS  " & arguments.name & chr(10));
    } catch (any e) {
        results.fail++;
        arrayAppend(results.errors, {name: arguments.name, msg: e.message});
        writeOutput("  FAIL  " & arguments.name & " :: " & e.message & chr(10));
    }
}

function describe(label, body) {
    writeOutput(chr(10) & "[" & arguments.label & "]" & chr(10));
    body();
}

function assertEquals(expected, actual, label="") {
    if (toString(arguments.expected) != toString(arguments.actual)) {
        throw(message="Expected [#arguments.expected#] got [#arguments.actual#] #arguments.label#");
    }
}
function assertContains(needle, haystack, label="") {
    if (!find(arguments.needle, arguments.haystack)) {
        throw(message="Expected to find [#arguments.needle#] in [#arguments.haystack#] #arguments.label#");
    }
}
function assertTrue(value, label="") {
    if (!arguments.value) { throw(message="Expected truthy: #arguments.label#"); }
}
function assertFalse(value, label="") {
    if (arguments.value) { throw(message="Expected falsy: #arguments.label#"); }
}

// Pass-through next() used by every test that doesn't need a custom handler.
function passthrough() { return function(req) { return "ok"; }; }

// Helpers live in a CFC because BoxLang 1.5 produces broken bytecode for
// top-level functions / closures that wrap `new wheels.X(...)` in try/catch.
probes = createObject("component", "Probes");

// ============================================================================
// Section 1: Fixed window — Section 3 of the article
// ============================================================================
describe("Fixed window strategy", function() {

    test("allows up to maxRequests then blocks", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 3, windowSeconds = 60);
        var n = passthrough();
        var req = {cgi: {remote_addr: "192.0.2.1"}};
        assertEquals("ok", rl.handle(request=req, next=n), "r1");
        assertEquals("ok", rl.handle(request=req, next=n), "r2");
        assertEquals("ok", rl.handle(request=req, next=n), "r3");
        assertContains("Rate limit exceeded", rl.handle(request=req, next=n), "r4 must block");
    });

    test("isolates different IPs into separate buckets", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);
        var n = passthrough();
        assertEquals("ok", rl.handle(request={cgi:{remote_addr:"10.0.0.1"}}, next=n), "ip1");
        assertEquals("ok", rl.handle(request={cgi:{remote_addr:"10.0.0.2"}}, next=n), "ip2");
        assertContains("Rate limit exceeded", rl.handle(request={cgi:{remote_addr:"10.0.0.1"}}, next=n), "ip1 again");
    });
});

// ============================================================================
// Section 2: Sliding window — Section 3 of the article
// ============================================================================
describe("Sliding window strategy", function() {
    test("blocks once the rolling count reaches maxRequests", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 2, windowSeconds = 60, strategy = "slidingWindow");
        var n = passthrough();
        var req = {cgi: {remote_addr: "203.0.113.5"}};
        assertEquals("ok", rl.handle(request=req, next=n));
        assertEquals("ok", rl.handle(request=req, next=n));
        assertContains("Rate limit exceeded", rl.handle(request=req, next=n));
    });
});

// ============================================================================
// Section 3: Token bucket — Section 3 of the article
// ============================================================================
describe("Token bucket strategy", function() {
    test("allows a full-bucket burst, then blocks until refill", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 3, windowSeconds = 60, strategy = "tokenBucket");
        var n = passthrough();
        var req = {cgi: {remote_addr: "198.51.100.4"}};
        // First request consumes one of three tokens.
        assertEquals("ok", rl.handle(request=req, next=n), "r1");
        assertEquals("ok", rl.handle(request=req, next=n), "r2");
        assertEquals("ok", rl.handle(request=req, next=n), "r3");
        // Bucket near-empty; fourth call within the same millisecond gets a tiny refill but still under 1 token.
        var r4 = rl.handle(request=req, next=n);
        assertContains("Rate limit exceeded", r4, "r4 should block until next refill");
    });
});

// ============================================================================
// Section 4: trustProxy & proxyStrategy — Section 4 of the article
// ============================================================================
describe("trustProxy default (off)", function() {
    test("ignores X-Forwarded-For when trustProxy is false (default)", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);
        var n = passthrough();
        // Same remote_addr from a load balancer — different XFF values must NOT split into separate buckets.
        var a = rl.handle(request = {cgi: {remote_addr: "10.0.0.50", http_x_forwarded_for: "1.1.1.1"}}, next = n);
        var b = rl.handle(request = {cgi: {remote_addr: "10.0.0.50", http_x_forwarded_for: "2.2.2.2"}}, next = n);
        assertEquals("ok", a, "first call ok");
        assertContains("Rate limit exceeded", b, "second call should block — both share the load balancer's IP");
    });
});

describe("trustProxy=true (behind a known proxy)", function() {
    test("with proxyStrategy=last, uses the rightmost XFF entry as the client IP", function() {
        var rl = new wheels.middleware.RateLimiter(
            maxRequests = 1, windowSeconds = 60,
            trustProxy = true, proxyStrategy = "last"
        );
        var n = passthrough();
        // Same load balancer IP, but a TRUSTED proxy has appended the real client IP as the rightmost entry.
        // proxyStrategy="last" picks the rightmost — so the two requests have DIFFERENT bucket keys.
        var a = rl.handle(request = {cgi: {remote_addr: "10.0.0.50", http_x_forwarded_for: "203.0.113.1, 10.0.0.50"}}, next = n);
        var b = rl.handle(request = {cgi: {remote_addr: "10.0.0.50", http_x_forwarded_for: "203.0.113.2, 10.0.0.50"}}, next = n);
        // Both should succeed because they came from different (trusted-proxy-reported) clients.
        // The rightmost entry in "203.0.113.1, 10.0.0.50" is "10.0.0.50" — meaning both requests share that same key.
        // The article will explain this nuance: proxyStrategy="last" pulls the LAST entry, which when a single
        // trusted proxy *appends* the client IP, that last entry IS the client. When a single trusted proxy
        // *prepends* it, the rightmost entry is the proxy itself and you've got the wrong key.
        // For nginx the canonical setup is to set XFF to just the client IP — see the article body.
        // For this test we just confirm the API behaves predictably.
        assertEquals("ok", a, "first call ok");
        // Both have remote_addr=10.0.0.50 and XFF ending in 10.0.0.50, so both resolve to the same key.
        assertContains("Rate limit exceeded", b, "second call hits same bucket");
    });

    test("with proxyStrategy=first, uses the leftmost XFF entry (compat mode)", function() {
        var rl = new wheels.middleware.RateLimiter(
            maxRequests = 1, windowSeconds = 60,
            trustProxy = true, proxyStrategy = "first"
        );
        var n = passthrough();
        // Different client IPs in the leftmost position → different buckets.
        var a = rl.handle(request = {cgi: {remote_addr: "10.0.0.50", http_x_forwarded_for: "203.0.113.1, 10.0.0.50"}}, next = n);
        var b = rl.handle(request = {cgi: {remote_addr: "10.0.0.50", http_x_forwarded_for: "203.0.113.2, 10.0.0.50"}}, next = n);
        assertEquals("ok", a, "client A first call ok");
        assertEquals("ok", b, "client B first call also ok — different leftmost key");
    });
});

// ============================================================================
// Section 5: custom keyFunction — per-API-key limiting — Section 5 of article
// ============================================================================
describe("keyFunction (the article's hero example)", function() {
    test("rate-limits authenticated callers per API key, not per IP", function() {
        var keyFn = function(req) {
            if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_api_key") && Len(req.cgi.http_x_api_key)) {
                return "apikey:" & req.cgi.http_x_api_key;
            }
            return "ip:" & req.cgi.remote_addr;
        };
        var rl = new wheels.middleware.RateLimiter(maxRequests = 2, windowSeconds = 60, keyFunction = keyFn);
        var n = passthrough();

        // Two callers from the same office IP but different API keys.
        // Each should get their own bucket of 2 requests.
        var aliceReq = {cgi: {remote_addr: "192.0.2.99", http_x_api_key: "alice-key"}};
        var bobReq   = {cgi: {remote_addr: "192.0.2.99", http_x_api_key: "bob-key"}};

        assertEquals("ok", rl.handle(request=aliceReq, next=n), "alice 1");
        assertEquals("ok", rl.handle(request=aliceReq, next=n), "alice 2");
        assertContains("Rate limit exceeded", rl.handle(request=aliceReq, next=n), "alice 3 — blocked");

        // Bob is untouched even though he shares Alice's IP.
        assertEquals("ok", rl.handle(request=bobReq, next=n), "bob 1");
        assertEquals("ok", rl.handle(request=bobReq, next=n), "bob 2");
        assertContains("Rate limit exceeded", rl.handle(request=bobReq, next=n), "bob 3 — blocked");
    });

    test("falls back to IP when no API key is present", function() {
        var keyFn = function(req) {
            if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_api_key") && Len(req.cgi.http_x_api_key)) {
                return "apikey:" & req.cgi.http_x_api_key;
            }
            return "ip:" & req.cgi.remote_addr;
        };
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60, keyFunction = keyFn);
        var n = passthrough();
        var anon = {cgi: {remote_addr: "192.0.2.200", http_x_api_key: ""}};
        assertEquals("ok", rl.handle(request=anon, next=n), "anon 1");
        assertContains("Rate limit exceeded", rl.handle(request=anon, next=n), "anon 2 — blocked");
    });

    test("hashes oversized keys so attackers cannot bloat the store", function() {
        var bigKey = repeatString("a", 200); // > default maxKeyLength=128
        var keyFn = function(req) { return req.cgi.http_x_api_key; };
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60, keyFunction = keyFn, maxKeyLength = 128);
        var n = passthrough();
        var req = {cgi: {remote_addr: "192.0.2.1", http_x_api_key: bigKey}};
        // First call OK, second must be blocked — same hashed bucket.
        assertEquals("ok", rl.handle(request=req, next=n), "big key 1");
        assertContains("Rate limit exceeded", rl.handle(request=req, next=n), "big key 2 — same hashed bucket");
    });
});

// ============================================================================
// Section 6: pipeline composition — order matters — Section 7 of the article
// ============================================================================
describe("Pipeline ordering (CORS + RateLimiter + SecurityHeaders)", function() {

    test("middleware fires in declaration order", function() {
        var trail = {seen: []};
        var probe1 = createObject("component", "Probe").init(label = "outer", trail = trail);
        var probe2 = createObject("component", "Probe").init(label = "inner", trail = trail);
        var pipeline = new wheels.middleware.Pipeline(middleware = [probe1, probe2]);
        var core = function(req) {
            ArrayAppend(trail.seen, "core");
            return "body";
        };
        var response = pipeline.run(request = {}, coreHandler = core);
        assertEquals("body", response, "core response returned");
        assertEquals("outer,inner,core", ArrayToList(trail.seen), "fire order");
    });

    test("blocking middleware short-circuits the rest", function() {
        var trail = {seen: []};
        var rl = new wheels.middleware.RateLimiter(maxRequests = 0, windowSeconds = 60);
        var afterLimiter = createObject("component", "Probe").init(label = "after", trail = trail);
        var pipeline = new wheels.middleware.Pipeline(middleware = [rl, afterLimiter]);
        var core = function(req) {
            ArrayAppend(trail.seen, "core");
            return "body";
        };
        var response = pipeline.run(request = {cgi:{remote_addr:"192.0.2.7"}}, coreHandler = core);
        assertContains("Rate limit exceeded", response, "limiter blocks");
        assertEquals("", ArrayToList(trail.seen), "core and downstream middleware did NOT fire");
    });
});

// ============================================================================
// Section 7: SecurityHeaders smoke check — Section 7 of the article
// ============================================================================
describe("SecurityHeaders middleware", function() {
    test("ships sensible OWASP defaults", function() {
        var sh = new wheels.middleware.SecurityHeaders();
        var headers = sh.$headers();
        assertEquals("SAMEORIGIN", headers["X-Frame-Options"], "X-Frame-Options");
        assertEquals("nosniff", headers["X-Content-Type-Options"], "X-Content-Type-Options");
        assertEquals("strict-origin-when-cross-origin", headers["Referrer-Policy"], "Referrer-Policy");
    });

    test("HSTS is auto-enabled in production", function() {
        var sh = new wheels.middleware.SecurityHeaders(environment = "production");
        var headers = sh.$headers();
        assertContains("max-age=31536000", headers["Strict-Transport-Security"], "HSTS default in production");
    });

    test("HSTS is suppressed when hsts=false (TLS-terminating proxy already emits it)", function() {
        var sh = new wheels.middleware.SecurityHeaders(environment = "production", hsts = false);
        var headers = sh.$headers();
        assertFalse(StructKeyExists(headers, "Strict-Transport-Security"), "HSTS suppressed");
    });
});

// ============================================================================
// Section 8: CORS — Section 7 of the article
// ============================================================================
describe("CORS middleware", function() {
    test("rejects allowOrigins=* + allowCredentials=true at init (browser-safe)", function() {
        var captured = probes.tryConstructCors();
        assertTrue(captured.threw, "Cors must refuse the spec-forbidden combo at construction time");
        assertEquals("Wheels.Cors.InvalidConfiguration", captured.type, "expected Wheels.Cors.InvalidConfiguration");
    });
});

// ============================================================================
// Section 9: input validation — Section 3 of the article
// ============================================================================
describe("Input validation", function() {
    test("rejects unknown strategy", function() {
        var captured = probes.tryRateLimiterStrategy("bogus");
        assertTrue(captured.threw, "must reject unknown strategy");
        assertEquals("Wheels.RateLimiter.InvalidStrategy", captured.type);
    });

    test("rejects unknown storage", function() {
        var captured = probes.tryRateLimiterStorage("bogus");
        assertTrue(captured.threw, "must reject unknown storage");
        assertEquals("Wheels.RateLimiter.InvalidStorage", captured.type);
    });
});

// ============================================================================
// Section 10: route-scope middleware merge logic — Section 6 of article
// ----------------------------------------------------------------------------
// The Mapper component itself depends on a live `application` scope from a
// running Wheels app, so we can't bootstrap it standalone here. The merge
// logic itself, however, is small and pure — it lives in mapper/scoping.cfc
// lines 66-79 and decides what ends up on each child route. We replicate
// that algorithm verbatim and assert the contract.
//
// End-to-end integration (mapper draws a route → dispatcher pulls the
// route's middleware → pipeline runs them in the right order) is covered
// by MiddlewarePipelineSpec.cfc and the integration runs in the regular
// engine-matrix CI.
// ============================================================================
describe("Scope middleware merge (replicates scoping.cfc:66-79)", function() {

    var mergeScopeMiddleware = function(parentMiddleware, currentMiddleware) {
        // Lifted verbatim from vendor/wheels/mapper/scoping.cfc lines 67-79.
        var parent = IsSimpleValue(arguments.parentMiddleware) ? ListToArray(arguments.parentMiddleware) : arguments.parentMiddleware;
        var current = IsSimpleValue(arguments.currentMiddleware) ? ListToArray(arguments.currentMiddleware) : arguments.currentMiddleware;
        var merged = [];
        ArrayAppend(merged, parent, true);
        ArrayAppend(merged, current, true);
        return merged;
    };

    test("a single scope's middleware is preserved on child routes", function() {
        var result = mergeScopeMiddleware([], ["app.middleware.ApiAuth"]);
        assertEquals(1, ArrayLen(result));
        assertEquals("app.middleware.ApiAuth", result[1]);
    });

    test("nested scopes inherit parent middleware in order, then append their own", function() {
        var result = mergeScopeMiddleware(["outer.Mw"], ["inner.Mw"]);
        assertEquals(2, ArrayLen(result), "merged outer+inner");
        assertEquals("outer.Mw", result[1], "outer fires first");
        assertEquals("inner.Mw", result[2], "inner fires second");
    });

    test("a string list converts to an array (so the article's snippet using a list works)", function() {
        var result = mergeScopeMiddleware("a.Mw,b.Mw", "c.Mw");
        assertEquals(3, ArrayLen(result));
        assertEquals("a.Mw", result[1]);
        assertEquals("b.Mw", result[2]);
        assertEquals("c.Mw", result[3]);
    });
});

// ============================================================================
// Section 11: validates the article's exact illustrative snippet
// ============================================================================
describe("Article's hero example (verbatim copy)", function() {
    test("the full snippet from the article runs end-to-end", function() {
        // This is the literal code block the article will publish.
        // Editing this test means editing the article too.
        var keyFunction = function(req) {
            if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_api_key") && Len(req.cgi.http_x_api_key)) {
                return "apikey:" & req.cgi.http_x_api_key;
            }
            return "ip:" & req.cgi.remote_addr;
        };

        var limiter = new wheels.middleware.RateLimiter(
            maxRequests = 2,
            windowSeconds = 60,
            strategy = "slidingWindow",
            keyFunction = keyFunction
        );

        // Two requests from two different API keys — both should pass.
        var req = function(ip, key) { return {cgi: {remote_addr: arguments.ip, http_x_api_key: arguments.key}}; };
        var n = passthrough();

        assertEquals("ok", limiter.handle(request = req("198.51.100.1", "key-A"), next = n));
        assertEquals("ok", limiter.handle(request = req("198.51.100.1", "key-A"), next = n));
        assertContains("Rate limit exceeded", limiter.handle(request = req("198.51.100.1", "key-A"), next = n), "third A blocked");

        // Different key from the same IP — still has its own bucket.
        assertEquals("ok", limiter.handle(request = req("198.51.100.1", "key-B"), next = n), "B not affected by A");
    });
});

// ============================================================================
writeOutput(chr(10) & "==============================================" & chr(10));
writeOutput("Total: " & (results.pass + results.fail) & " | Pass: " & results.pass & " | Fail: " & results.fail & chr(10));
if (results.fail > 0) {
    writeOutput(chr(10) & "Failures:" & chr(10));
    for (var err in results.errors) {
        writeOutput("  - " & err.name & ": " & err.msg & chr(10));
    }
}
</cfscript>
