/**
 * DI `currentUser` service used by Authorization S6. getInstance("currentUser")
 * returns this component; Policy stores it as the identity.
 */
component {

	public any function init() {
		this.id = 9001;
		this.name = "policy-di-user";
		return this;
	}

}
