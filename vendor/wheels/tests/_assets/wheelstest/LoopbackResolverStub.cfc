/**
 * Test double for the #4195 resolver-level specs. Stubs the servlet local port and the HTTP probe so
 * a spec can drive the COMPLETE resolvers — WheelsTest.$getTestBaseUrl (via the public wrapper below)
 * and BrowserTest.$resolveBaseUrl — through the mapped-selection, probe-answers, and cgi-fallback
 * paths without a live server. Extends BrowserTest so both resolvers and the shared probe helpers
 * are exercised through real virtual dispatch.
 */
component extends="wheels.wheelstest.BrowserTest" {

	variables.stubLocalPort = 0;
	variables.stubProbeAnswer = false;
	variables.probeCallCount = 0;

	/** Configure the stub and reset the shared probe cache so each scenario probes fresh. */
	public void function $setLoopbackStub(required numeric localPort, required boolean probeAnswer) {
		variables.stubLocalPort = arguments.localPort;
		variables.stubProbeAnswer = arguments.probeAnswer;
		variables.probeCallCount = 0;
		try {
			StructDelete(application[$appKey()], "$testClientLoopbackProbe");
		} catch (any e) {
		}
	}

	/** How many times the stubbed probe actually ran (to prove per-candidate caching). */
	public numeric function $probeCalls() {
		return variables.probeCallCount;
	}

	/** Public wrapper so a spec can drive the otherwise-private WheelsTest resolver end to end. */
	public string function $resolveTestClientBaseUrl() {
		return $getTestBaseUrl();
	}

	// --- stubbed seams: override the real ones; the inherited resolvers dispatch to these ---
	public numeric function $servletLocalPort() {
		return variables.stubLocalPort;
	}

	public boolean function $probeHttpEndpoint(required string candidate) {
		variables.probeCallCount = variables.probeCallCount + 1;
		return variables.stubProbeAnswer;
	}
}
