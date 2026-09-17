/**
 * DI `currentUser` whose init() throws. S3: getInstance("currentUser") must
 * not fall through to the authenticator.
 */
component {

	public any function init() {
		Throw(type = "Wheels.Policy.CurrentUserBoom", message = "forced currentUser failure for S3");
	}

}
