/**
 * Test strategy that always fails authentication.
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	public AlwaysFailStrategy function init(string name = "alwaysFail", string error = "Invalid credentials", numeric statusCode = 401) {
		variables.name = arguments.name;
		variables.error = arguments.error;
		variables.statusCode = arguments.statusCode;
		return this;
	}

	public string function getName() {
		return variables.name;
	}

	public boolean function supports(required struct request) {
		return true;
	}

	public struct function authenticate(required struct request) {
		return {
			success = false,
			principal = {},
			strategy = getName(),
			error = variables.error,
			statusCode = variables.statusCode
		};
	}

}
