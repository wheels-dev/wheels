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

	// Marker accessors so specs can verify instance identity (shared vs
	// distinct instances) without relying on engine-specific object-equality
	// semantics or external property assignment.
	public void function setMarker(required string value) {
		variables.marker = arguments.value;
	}

	public string function getMarker() {
		return structKeyExists(variables, "marker") ? variables.marker : "";
	}

}
