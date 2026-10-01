/**
 * Runs a scaffold config file (config/environment.cfm, config/settings.cfm) with
 * stand-ins for env() and set(): env() answers from the struct passed to init(),
 * set() records its arguments, and includeConfig() returns what was set.
 */
component {

	public any function init(struct envValues = {}) {
		variables.envValues = arguments.envValues;
		variables.settings = {};
		return this;
	}

	public any function env(required string name, any defaultValue = "") {
		return StructKeyExists(variables.envValues, arguments.name) ? variables.envValues[arguments.name] : arguments.defaultValue;
	}

	public void function set() {
		StructAppend(variables.settings, arguments, true);
	}

	public struct function includeConfig(required string template) {
		include "#arguments.template#";
		return variables.settings;
	}

}
