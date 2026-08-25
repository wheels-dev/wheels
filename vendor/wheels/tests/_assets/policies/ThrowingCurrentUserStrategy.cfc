/**
 * Authenticator strategy whose currentUser() throws. S3: a broken strategy
 * must not become guest "".
 */
component {

	public any function currentUser() {
		Throw(type = "Wheels.Policy.AuthenticatorBoom", message = "forced authenticator failure for S3");
	}

}
