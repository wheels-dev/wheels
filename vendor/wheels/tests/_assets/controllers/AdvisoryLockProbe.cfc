/**
 * Test-asset controller for the #4219 release-on-abort regression spec
 * (advisoryLockAbortReleaseSpec). Each action takes a withAdvisoryLock() lock and then ends the
 * request from INSIDE the callback — with a real `abort` or a real `redirectTo()` (which ends in a
 * cflocation) — for both the default (session-scoped) and the transaction = true path.
 *
 * Positive control: while inside the lock, and before ending the request, each callback records a
 * held-check taken from a SECOND connection into server["wheelsAdvisoryProbe_<name>"]. The spec
 * reads that marker and asserts it is true, so a scenario cannot pass vacuously if the request never
 * reached withAdvisoryLock (a 404, a load failure, the wrong datasource, an early throw) — in those
 * cases the marker is simply absent. $isAdvisoryLockHeld is a server-wide query, so the separate
 * connection proves the lock was genuinely held at the moment of the abort / redirect.
 *
 * The lock's release runs in a `finally`, which executes on abort / cflocation, so the lock must be
 * free once the request ends — which the spec then asserts.
 */
component extends="Controller" {

	function abortDefault() {
		$probe(name = "probe_abort_default", tx = false, ending = "abort");
	}

	function redirectDefault() {
		$probe(name = "probe_redirect_default", tx = false, ending = "redirect");
	}

	function abortTransaction() {
		$probe(name = "probe_abort_tx", tx = true, ending = "abort");
	}

	function redirectTransaction() {
		$probe(name = "probe_redirect_tx", tx = true, ending = "redirect");
	}

	private function $probe(required string name, required boolean tx, required string ending) {
		var probeName = arguments.name;
		var probeEnding = arguments.ending;
		// A second-connection adapter on the model's own datasource, built BEFORE the lock so the
		// callback closure only references captured locals (invariant 3). $isAdvisoryLockHeld() is a
		// server-wide query, so from this separate connection a true result proves the lock really is
		// held during the callback.
		var classData = model("author").$classData();
		var folder = Left(get("adapterName"), Len(get("adapterName")) - 5);
		var checker = CreateObject("component", "wheels.databaseAdapters." & folder & "." & get("adapterName")).$init(
			dataSource = classData.dataSource,
			username = classData.username,
			password = classData.password
		);

		model("author").withAdvisoryLock(name = probeName, transaction = arguments.tx, callback = function() {
			server["wheelsAdvisoryProbe_" & probeName] = checker.$isAdvisoryLockHeld(name = probeName);
			if (probeEnding == "redirect") {
				redirectTo(url = "/");
			} else {
				abort;
			}
		});
	}
}
