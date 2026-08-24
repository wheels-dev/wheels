/**
 * SessionStrategy test double whose $rotateSession always throws.
 * Used by AuthHardenerShouldSpec S1 to prove login/logout do not
 * swallow rotation failures.
 */
component extends="wheels.auth.SessionStrategy" output="false" {

	public void function $rotateSession() {
		throw(
			type = "Wheels.Auth.SessionRotateFailed",
			message = "forced rotate failure for hardener S1"
		);
	}

}
