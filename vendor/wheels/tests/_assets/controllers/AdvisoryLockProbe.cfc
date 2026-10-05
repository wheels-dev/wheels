/**
 * Test-asset controller for the #4219 release-on-abort regression spec
 * (advisoryLockAbortReleaseSpec). Each action takes a withAdvisoryLock() lock
 * and then ends the request from INSIDE the callback — with a real `abort` or a
 * real `redirectTo()` (which ends in a cflocation) — for both the default
 * (session-scoped) and the transaction = true path.
 *
 * The lock's release runs in a `finally`, which executes on abort / cflocation
 * (measured on Lucee, Adobe and BoxLang), so the lock must be free once the
 * request ends. The spec drives these actions over HTTP via $testClient and
 * then, from its own (separate) connection, asserts the named lock is no longer
 * held anywhere — a release skipped on abort would leave it held and red the spec.
 *
 * Lock names are fixed per action so the spec can check and clean up each one.
 */
component extends="Controller" {

	function abortDefault() {
		model("author").withAdvisoryLock(name = "probe_abort_default", callback = function() {
			abort;
		});
	}

	function redirectDefault() {
		model("author").withAdvisoryLock(name = "probe_redirect_default", callback = function() {
			redirectTo(url = "/");
		});
	}

	function abortTransaction() {
		model("author").withAdvisoryLock(name = "probe_abort_tx", transaction = true, callback = function() {
			abort;
		});
	}

	function redirectTransaction() {
		model("author").withAdvisoryLock(name = "probe_redirect_tx", transaction = true, callback = function() {
			redirectTo(url = "/");
		});
	}
}
