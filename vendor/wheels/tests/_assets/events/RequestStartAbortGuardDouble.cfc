/**
 * S5 abort containment for EventsHardenerSpec.
 *
 * CorsArbitrationEventDouble runs the live `$runOnRequestStart` but does
 * not trap `abort`. If `$corsMiddlewareActive()` is false while
 * request.CGI.request_method is OPTIONS and allowCorsRequests is true,
 * the production `abort;` kills the TestBox HTTP request (LuCLI core
 * suite HTTP 500). This double refuses to enter that branch: it throws a
 * contained UnitTest exception instead of invoking the aborting path.
 *
 * Cors-active skip still executes the live `$runOnRequestStart`. The
 * production `abort;` stays pinned in EventMethods source — do not flip it.
 */
component extends="wheels.tests._assets.events.CorsArbitrationEventDouble" {

	public any function init() {
		super.init();
		this.abortContained = false;
		return this;
	}

	/**
	 * cflocation / $location also abort the request. No-op so a leftover
	 * redirectAfterReloadUrl cannot kill the suite either.
	 */
	public void function $location() {
	}

	/**
	 * Invoke live `$runOnRequestStart` only when the OPTIONS abort branch
	 * cannot fire. Mirrors EventMethods.cfc ~329-337 without executing abort.
	 */
	public void function $runOnRequestStartContained(required string targetPage) {
		this.abortContained = false;
		if ($wouldHitOptionsAbort()) {
			this.abortContained = true;
			throw(
				type = "UnitTest.OptionsAbortContained",
				message = "contained $runOnRequestStart OPTIONS abort — Cors-active skip was not live"
			);
		}
		$runOnRequestStart(targetPage = arguments.targetPage);
	}

	public boolean function $wouldHitOptionsAbort() {
		return application.wheels.allowCorsRequests
			&& !$corsMiddlewareActive()
			&& StructKeyExists(request, "CGI")
			&& StructKeyExists(request.CGI, "request_method")
			&& request.CGI.request_method eq "OPTIONS";
	}

}
