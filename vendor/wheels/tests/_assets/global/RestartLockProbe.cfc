/**
 * Stand-in for the Application.cfc methods $simpleLock runs on the reload
 * path (issue 3770): $handleRestartAppRequest under the exclusive reload
 * lock, and $runOnSessionEnd under the read lock. $invoke creates a fresh
 * instance per call, so observations go to request.$restartLockProbe.
 */
component {

	public void function $handleRestartAppRequest(boolean shouldThrow = false) {
		request.$restartLockProbe.sawMarker = StructKeyExists(application, "$wheelsRestartLock");
		if (request.$restartLockProbe.sawMarker) {
			request.$restartLockProbe.marker = Duplicate(application["$wheelsRestartLock"]);
		}
		if (arguments.shouldThrow) {
			Throw(type = "Wheels.RestartLockProbe", message = "restart failed before applicationStop()");
		}
	}

	public void function $runOnSessionEnd(required sessionScope, required applicationScope) {
		request.$restartLockProbe.sessionEndRan = true;
	}

}
