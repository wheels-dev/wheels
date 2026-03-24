/**
 * Test strategy that always authenticates successfully.
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	public AlwaysPassStrategy function init(string name = "alwaysPass") {
		variables.name = arguments.name;
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
			success = true,
			principal = {id = 1, role = "admin"},
			strategy = getName(),
			error = "",
			statusCode = 200
		};
	}

}
