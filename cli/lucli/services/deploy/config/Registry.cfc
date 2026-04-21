/**
 * Registry — immutable accessor for the `registry:` block.
 *
 * Kamal allows `password:` as either a scalar ("REGISTRY_PASSWORD") or an
 * array ([REGISTRY_PASSWORD]) — both reference secret names, and the array
 * form is the canonical shape. This accessor always returns an array so
 * downstream code doesn't have to branch.
 */
component {

	public any function init(struct raw = {}) {
		variables.raw = arguments.raw;
		return this;
	}

	public string function server() {
		return variables.raw.server ?: "docker.io";
	}

	public string function username() {
		return variables.raw.username ?: "";
	}

	public array function password() {
		if (!structKeyExists(variables.raw, "password")) return [];
		var pw = variables.raw.password;
		return isArray(pw) ? pw : [pw];
	}

}
