/**
 * Test double for CorsGlobalArbitrationSpec (issue 3114).
 *
 * Extends the real EventMethods so `$runOnRequestStart` executes the genuine
 * CORS arbitration wiring, while:
 * - `$setCORSHeaders` records the invocation instead of emitting real
 *   `Access-Control-Allow-*` headers into the live test response, and
 * - the side-effecting collaborators that `$runOnRequestStart` calls on the
 *   way to the CORS block (`$include` of the app's onrequeststart template,
 *   plugin/package reloads, debug points) are no-op'd so the spec only
 *   exercises the arbitration logic.
 */
component extends="wheels.events.EventMethods" {

	public any function init() {
		this.corsHeaderCalls = 0;
		return this;
	}

	public void function $setCORSHeaders() {
		this.corsHeaderCalls = this.corsHeaderCalls + 1;
	}

	public void function $include(required string template) {
	}

	public void function $loadPlugins() {
	}

	public void function $loadPackages() {
	}

	public void function $debugPoint(required string name) {
	}

}
