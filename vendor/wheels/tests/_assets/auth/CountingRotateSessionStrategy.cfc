/**
 * SessionStrategy test double that counts $rotateSession invocations.
 * Used by AuthHardenerShouldSpec S1/S2 to prove login and logout
 * go through the rotation helper rather than a silent no-op.
 */
component extends="wheels.auth.SessionStrategy" output="false" {

	public CountingRotateSessionStrategy function init(
		string sessionKey = "wheels.auth",
		any onLogin = "",
		any onLogout = ""
	) {
		super.init(argumentCollection = arguments);
		variables.rotateCalls = 0;
		return this;
	}

	public numeric function $rotateCount() {
		return variables.rotateCalls;
	}

	public void function $rotateSession() {
		variables.rotateCalls = variables.rotateCalls + 1;
	}

}
