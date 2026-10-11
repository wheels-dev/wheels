/**
 * Test-asset controller for F23 (TestClient client address). Reports the client address as the
 * MIDDLEWARE see it — i.e. the `remoteAddr` field on the middleware request context that RateLimiter
 * and IP rules read (exposed to the controller as request.wheels.middlewareContext.remoteAddr). When
 * no test override is in effect the field is absent, and the probe reports "none", which is what a
 * non-isolated request must see. Driven by wheels.tests.specs.testclient.testClientRemoteAddrSpec.
 */
component extends="Controller" {

	function show() {
		var addr = "none";
		if (
			StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "middlewareContext")
			&& StructKeyExists(request.wheels.middlewareContext, "remoteAddr")
			&& Len(request.wheels.middlewareContext.remoteAddr)
		) {
			addr = request.wheels.middlewareContext.remoteAddr;
		}
		renderText(addr);
	}

}
