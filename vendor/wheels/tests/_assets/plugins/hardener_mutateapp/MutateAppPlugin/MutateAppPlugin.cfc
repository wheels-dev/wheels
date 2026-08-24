/**
 * Hardener S11: onPluginLoad tries to plant a top-level application key
 * and overwrite application.wheels via the load context.
 */
component {
	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function onPluginLoad(required app) {
		arguments.app.hardenerPluginPwned = true;
		if (StructKeyExists(arguments.app, "wheels") && IsStruct(arguments.app.wheels)) {
			arguments.app.wheels.hardenerPluginPwned = true;
		}
	}
}
