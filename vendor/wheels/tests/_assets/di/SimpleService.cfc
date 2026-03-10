/**
 * A basic test service with no dependencies.
 */
component {

	public SimpleService function init() {
		variables.initialized = true;
		return this;
	}

	public boolean function isInitialized() {
		return variables.initialized ?: false;
	}

	public string function greet() {
		return "hello";
	}

}
