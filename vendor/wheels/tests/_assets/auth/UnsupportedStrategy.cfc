/**
 * Test strategy that never supports any request.
 * Used to test the "no applicable strategy" code path.
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	public UnsupportedStrategy function init() {
		return this;
	}

	public string function getName() {
		return "unsupported";
	}

	public boolean function supports(required struct request) {
		return false;
	}

	public struct function authenticate(required struct request) {
		return {
			success = false,
			principal = {},
			strategy = getName(),
			error = "Should not be called",
			statusCode = 500
		};
	}

}
