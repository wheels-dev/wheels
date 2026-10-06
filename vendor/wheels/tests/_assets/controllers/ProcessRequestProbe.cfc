/**
 * Test-asset controller for the processRequest() state-restore spec
 * (wheels.tests.specs.global.processRequestStateRestoreSpec). `boom()` throws during the action so
 * the spec can confirm processRequest() restores the global/request state it changed on the way in,
 * even when the action throws and the spec catches it.
 */
component extends="Controller" {

	function boom() {
		Throw(type = "Wheels.ProcessRequestProbe.Boom", message = "boom on purpose");
	}

	function goHome() {
		redirectTo(url = "/");
	}

}
