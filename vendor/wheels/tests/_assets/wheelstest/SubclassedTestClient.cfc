/**
 * An app-style TestClient subclass with its own init() that calls super.init(),
 * for TestClientContextSpec.
 */
component extends="wheels.wheelstest.TestClient" {

	public any function init(string baseUrl = "http://localhost:8080") {
		super.init(baseUrl = arguments.baseUrl);
		variables.subclassed = true;
		return this;
	}

}
