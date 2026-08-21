component extends="Controller" {

	/**
	 * Overrides the authorization mixin's identity resolver — methods declared on
	 * the controller win over mixins in $integrateComponents(), which is also the
	 * documented app-side customization seam. Lets specs control the current user
	 * without touching the DI container or the session scope.
	 */
	public any function $currentUserForPolicy() {
		if (StructKeyExists(request, "$policyTestUser")) {
			return request.$policyTestUser;
		}
		return "";
	}

}
