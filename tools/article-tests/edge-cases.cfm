<cfscript>
// Edge case probes. These check for framework bugs that the article wouldn't
// directly demonstrate but should not exist quietly.

results = {pass: 0, fail: 0, bugs: []};

function test(name, body) {
    try {
        body();
        results.pass++;
        writeOutput("  PASS  " & arguments.name & chr(10));
    } catch (any e) {
        results.fail++;
        arrayAppend(results.bugs, {name: arguments.name, msg: e.message, type: e.type ?: ""});
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

function passthrough() { return function(req) { return "ok"; }; }

describe("Edge cases the article should be aware of", function() {

    test("windowSeconds=0 does not crash (or throws cleanly)", function() {
        // A user might fat-finger windowSeconds and expect a clear error rather than div-by-zero.
        var crashed = false;
        var threwClean = false;
        var output = "";
        try {
            var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 0);
            output = rl.handle(request = {cgi:{remote_addr:"192.0.2.1"}}, next = passthrough());
        } catch (any e) {
            // If the constructor / handler throws cleanly, that's fine.
            if (Find("windowSeconds", e.message) || Find("zero", e.message)) {
                threwClean = true;
            } else {
                crashed = true;
            }
        }
        // Either the handler returns a sensible response or the framework throws a clear error.
        // We just check it doesn't bubble up an opaque div-by-zero or JVM stack.
        if (crashed) {
            throw(message = "windowSeconds=0 produced an unclear failure — framework should validate this input");
        }
    });

    test("request struct without cgi key resolves to 'unknown' rather than crashing", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60);
        var n = passthrough();
        // The article never demonstrates this, but plain request structs without cgi do show up
        // in test harnesses and unit tests — the middleware should handle them gracefully.
        var out = rl.handle(request = {}, next = n);
        assertEquals("ok", out, "empty request handled");
    });

    test("keyFunction returning empty string still buckets correctly", function() {
        var emptyKeyFn = function(req) { return ""; };
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60, keyFunction = emptyKeyFn);
        var n = passthrough();
        var a = rl.handle(request = {}, next = n);
        var b = rl.handle(request = {}, next = n);
        assertEquals("ok", a, "first call ok");
        assertContains("Rate limit exceeded", b, "second call blocked (shared empty-key bucket)");
    });

    test("trustProxy=true + missing X-Forwarded-For falls back to remote_addr", function() {
        var rl = new wheels.middleware.RateLimiter(maxRequests = 1, windowSeconds = 60, trustProxy = true);
        var n = passthrough();
        var a = rl.handle(request = {cgi:{remote_addr:"192.0.2.42"}}, next = n);
        var b = rl.handle(request = {cgi:{remote_addr:"192.0.2.42"}}, next = n);
        assertEquals("ok", a);
        assertContains("Rate limit exceeded", b);
    });

    test("invalid proxyStrategy at init throws Wheels.RateLimiter.InvalidProxyStrategy", function() {
        var probes = createObject("component", "Probes");
        var captured = probes.tryRateLimiterProxyStrategy("bogus");
        if (!captured.threw) {
            throw(message = "RateLimiter accepted bogus proxyStrategy without complaint");
        }
        assertEquals("Wheels.RateLimiter.InvalidProxyStrategy", captured.type);
    });
});

writeOutput(chr(10) & "==============================================" & chr(10));
writeOutput("Edge cases — Pass: " & results.pass & " | Fail: " & results.fail & chr(10));
if (results.fail > 0) {
    writeOutput(chr(10) & "Potential framework issues to investigate:" & chr(10));
    for (var b in results.bugs) {
        writeOutput("  - " & b.name & ": " & b.msg & chr(10));
    }
}
</cfscript>
