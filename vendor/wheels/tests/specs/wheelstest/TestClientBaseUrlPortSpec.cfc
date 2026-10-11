/**
 * #4195: the auto-detected TestClient/BrowserTest base URL should target the server's actual local
 * listener, but a local/Host port mismatch alone does NOT prove a usable HTTP loopback endpoint
 * (AJP front ends expose the AJP port; getScheme() is the logical scheme, not the listener
 * transport). So the resolver builds loopback candidates (http first, then https) and probes them,
 * selecting the first that answers as HTTP and otherwise falling back to the existing cgi step.
 *
 * The pure pieces ($servletLoopbackCandidates, $selectAnsweringCandidate) are tested directly with
 * an injected probe, so the mapped/AJP/TLS cases are covered without a live server. Explicit
 * overrides are checked at the resolver level for both WheelsTest and BrowserTest.
 *
 * cgi-shaped structs are hoisted to variables before each call: an inline struct literal passed as a
 * positional argument (`func({server_port = 443}, 8080)`) is a compile error on Adobe CF, which
 * mis-reads the struct key as a named argument (invariant 16 family).
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("TestClient/BrowserTest base URL probes the local listener (4195)", () => {

			// --- candidate generation (pure) ---
			it("builds http-first then https candidates when a port mapping is present", () => {
				var cgiScope = {server_port = 443};
				var expected = ["http://127.0.0.1:8080", "https://127.0.0.1:8080"];
				expect($servletLoopbackCandidates(cgiScope, 8080)).toBe(expected);
			});

			it("returns no candidates when unmapped (localPort == server_port)", () => {
				var cgiScope = {server_port = 60007};
				expect($servletLoopbackCandidates(cgiScope, 60007)).toBe([]);
			});

			it("returns no candidates when there is no servlet port", () => {
				var cgiScope = {server_port = 8080};
				expect($servletLoopbackCandidates(cgiScope, 0)).toBe([]);
			});

			it("returns no candidates when server_port is missing", () => {
				var cgiScope = {};
				expect($servletLoopbackCandidates(cgiScope, 60007)).toBe([]);
			});

			// --- selection with an injected probe (no live server) ---
			it("TLS-terminated external 443 / internal HTTP 8080: http answers first -> http loopback", () => {
				var cgiScope = {server_port = 443};
				var httpAnswers = function(candidate) { return Find("https://", candidate) == 0; };
				var candidates = $servletLoopbackCandidates(cgiScope, 8080);
				expect($selectAnsweringCandidate(candidates, httpAnswers)).toBe("http://127.0.0.1:8080");
			});

			it("genuine internal TLS: only https answers -> https loopback", () => {
				var cgiScope = {server_port = 80};
				var httpsOnly = function(candidate) { return Find("https://", candidate) > 0; };
				var candidates = $servletLoopbackCandidates(cgiScope, 8443);
				expect($selectAnsweringCandidate(candidates, httpsOnly)).toBe("https://127.0.0.1:8443");
			});

			it("AJP / nothing answers -> empty, so resolution falls back to cgi", () => {
				var cgiScope = {server_port = 80};
				var noneAnswer = function(candidate) { return false; };
				var candidates = $servletLoopbackCandidates(cgiScope, 8009);
				expect($selectAnsweringCandidate(candidates, noneAnswer)).toBe("");
			});

			it("no candidates -> empty regardless of probe", () => {
				var always = function(candidate) { return true; };
				var empty = [];
				expect($selectAnsweringCandidate(empty, always)).toBe("");
			});

			// --- real probe falls back (no server on the candidate) ---
			it("$probeHttpEndpoint returns false for a dead endpoint (never blocks)", () => {
				expect($probeHttpEndpoint("http://127.0.0.1:1")).toBeFalse();
			});

			// The AJP shape: a listener ACCEPTS the TCP handshake (kernel backlog) but never sends an
			// HTTP status line, so the probe must end on the READ timeout and still return false within
			// bound (not hang ~30s). Distinct from a dead port, which fails at connect. Skipped by
			// CAPABILITY (CreateObject("java") unavailable) rather than engine name, so a future
			// non-JVM Java shim doesn't silently drop this coverage.
			it("$probeHttpEndpoint returns false within its timeout for a socket that accepts but never answers HTTP", () => {
				var serverSocket = "";
				try {
					var inet = CreateObject("java", "java.net.InetAddress").getByName("127.0.0.1");
					serverSocket = CreateObject("java", "java.net.ServerSocket").init(JavaCast("int", 0), JavaCast("int", 1), inet);
				} catch (any e) {
					skip("java.net unavailable on this engine — the AJP socket shape only runs where CreateObject(java) works");
					return;
				}
				var state = {result = true, elapsed = 0};
				try {
					var port = serverSocket.getLocalPort();
					var started = GetTickCount();
					state.result = $probeHttpEndpoint("http://127.0.0.1:" & port);
					state.elapsed = GetTickCount() - started;
				} finally {
					serverSocket.close();
				}
				expect(state.result).toBeFalse("a socket that accepts but never sends an HTTP status must not be selected");
				expect(state.elapsed).toBeLT(15000, "probe must honour its short timeout (~1-2s), not hang on the read");
			});

			// --- resolver-level: explicit overrides still win (both resolvers) ---
			it("WheelsTest: an explicit testClientBaseUrl wins over the probe step", () => {
				var saved = this.testClientBaseUrl ?: "";
				this.testClientBaseUrl = "http://override.example:9999";
				try {
					expect($getTestBaseUrl()).toBe("http://override.example:9999");
				} finally {
					this.testClientBaseUrl = saved;
				}
			});

			it("BrowserTest: an explicit baseUrl wins, and it inherits the probe seams", () => {
				var bt = new wheels.wheelstest.BrowserTest();
				bt.baseUrl = "http://bt.override:9999";
				expect(bt.$resolveBaseUrl()).toBe("http://bt.override:9999");
				// inherited seam works on BrowserTest too
				var cgiScope = {server_port = 443};
				var expected = ["http://127.0.0.1:8080", "https://127.0.0.1:8080"];
				expect(bt.$servletLoopbackCandidates(cgiScope, 8080)).toBe(expected);
			});
		});

		// Drive the COMPLETE resolvers (WheelsTest.$getTestBaseUrl + BrowserTest.$resolveBaseUrl)
		// through the mapped-success, cgi-fallback, and cache paths, using a double that stubs the
		// servlet local port and the HTTP probe (no live server). 9001 is a port the runner never
		// listens on, so the local/Host mismatch always registers as a mapping.
		describe("complete resolver paths via a stubbed probe (4195)", () => {

			var stub = new wheels.tests._assets.wheelstest.LoopbackResolverStub();

			it("WheelsTest resolver: mapped + probe answers -> loopback on the local port", () => {
				stub.$setLoopbackStub(9001, true);
				expect(stub.$resolveTestClientBaseUrl()).toBe("http://127.0.0.1:9001");
			});

			it("WheelsTest resolver: mapped + probe fails -> falls back to cgi (not the loopback)", () => {
				stub.$setLoopbackStub(9001, false);
				var expectedFallback = stub.$detectTestBaseUrlFromCgi(cgi);
				if (!len(expectedFallback)) {
					expectedFallback = "http://localhost:8080";
				}
				var resolved = stub.$resolveTestClientBaseUrl();
				expect(resolved).notToBe("http://127.0.0.1:9001", "must not use a loopback the probe rejected");
				expect(resolved).toBe(expectedFallback, "must fall back to the existing cgi resolution");
			});

			it("WheelsTest resolver: the probe result is cached (probed once across two resolves)", () => {
				stub.$setLoopbackStub(9001, true);
				stub.$resolveTestClientBaseUrl();
				stub.$resolveTestClientBaseUrl();
				expect(stub.$probeCalls()).toBe(1, "a positive probe must be cached, not repeated per resolve");
			});

			it("BrowserTest resolver: mapped + probe answers -> loopback on the local port", () => {
				stub.$setLoopbackStub(9001, true);
				expect(stub.$resolveBaseUrl()).toBe("http://127.0.0.1:9001");
			});

			it("BrowserTest resolver: mapped + probe fails -> falls back to cgi (not the loopback)", () => {
				stub.$setLoopbackStub(9001, false);
				var expectedFallback = stub.$detectBaseUrlFromCgi(cgi);
				if (!len(expectedFallback)) {
					expectedFallback = "http://localhost:8080";
				}
				var resolved = stub.$resolveBaseUrl();
				expect(resolved).notToBe("http://127.0.0.1:9001", "must not use a loopback the probe rejected");
				expect(resolved).toBe(expectedFallback, "must fall back to the existing cgi resolution");
			});
		});
	}
}
