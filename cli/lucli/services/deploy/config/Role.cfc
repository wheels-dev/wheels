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

	/**
	 * Whether this role's containers are fronted by kamal-proxy.
	 *
	 * Mirrors Kamal's Role#running_proxy? (lib/kamal/configuration/role.rb):
	 * an explicit role-level `proxy:` boolean wins; a `proxy:` hash (proxy
	 * options) opts the role in; otherwise only the default "web" role runs
	 * behind the proxy. Job/worker roles must not receive proxy boot or
	 * `kamal-proxy deploy` commands (#2957).
	 */
	public boolean function runningProxy() {
		if (structKeyExists(variables.raw, "proxy")) {
			if (isBoolean(variables.raw.proxy)) return variables.raw.proxy;
			if (isStruct(variables.raw.proxy)) return true;
		}
		return lCase(name()) == "web";
	}

}
