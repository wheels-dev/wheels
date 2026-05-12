/**
 * Role — immutable accessor for a single role entry.
 *
 * Kamal allows three `servers:` shapes and the Config root normalizes all
 * three into a list of Role instances, each holding the raw struct
 *   { name, hosts, env?, cmd? }
 */
component {

	public any function init(required struct raw) {
		variables.raw = arguments.raw;
		return this;
	}

	public string function name() {
		return variables.raw.name ?: "";
	}

	public array function hosts() {
		return (structKeyExists(variables.raw, "hosts") && isArray(variables.raw.hosts))
			? variables.raw.hosts
			: [];
	}

	public any function env() {
		var e = (structKeyExists(variables.raw, "env") && isStruct(variables.raw.env))
			? variables.raw.env
			: {};
		return new Env(e);
	}

	public string function cmd() {
		return variables.raw.cmd ?: "";
	}

}
