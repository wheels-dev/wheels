/**
 * Config — root of the deploy config tree.
 *
 * Holds the fully-merged, interpolated, and validated raw struct and exposes
 * typed accessors that wrap sub-blocks in their respective CFCs. All methods
 * are pure — no I/O, no shell-out — so they're safe to call repeatedly.
 *
 * `servers:` can appear in three shapes in YAML:
 *   1. Flat array:     servers: [1.2.3.4]             → single "web" role
 *   2. Role → array:   servers: {web: [...], job: [...]}
 *   3. Role → struct:  servers: {web: {hosts: [...], env: {...}, cmd: "..."}}
 * `roles()` normalizes all three into an array of Role instances.
 */
component {

	public any function init(required struct raw, struct opts = {destination: ""}) {
		variables.raw = arguments.raw;
		variables.destination = arguments.opts.destination ?: "";
		return this;
	}

	public string function service() {
		return variables.raw.service;
	}

	public string function image() {
		return variables.raw.image;
	}

	public string function destination() {
		return variables.destination;
	}

	public struct function raw() {
		return variables.raw;
	}

	public any function env() {
		var e = (structKeyExists(variables.raw, "env") && isStruct(variables.raw.env))
			? variables.raw.env
			: {};
		return new Env(e);
	}

	public any function builder() {
		var b = (structKeyExists(variables.raw, "builder") && isStruct(variables.raw.builder))
			? variables.raw.builder
			: {};
		return new Builder(b);
	}

	public any function registry() {
		var r = (structKeyExists(variables.raw, "registry") && isStruct(variables.raw.registry))
			? variables.raw.registry
			: {};
		return new Registry(r);
	}

	public any function proxy() {
		var p = (structKeyExists(variables.raw, "proxy") && isStruct(variables.raw.proxy))
			? variables.raw.proxy
			: {};
		return new Proxy(p);
	}

	public any function ssh() {
		var s = (structKeyExists(variables.raw, "ssh") && isStruct(variables.raw.ssh))
			? variables.raw.ssh
			: {};
		return new Ssh(s);
	}

	public array function roles() {
		var servers = variables.raw.servers;

		// Shape 1: flat array — single "web" role.
		if (isArray(servers)) {
			return [new Role({name: "web", hosts: servers})];
		}

		var out = [];
		if (isStruct(servers)) {
			for (var roleName in servers) {
				var entry = servers[roleName];
				if (isArray(entry)) {
					// Shape 2: role → [host, host]
					arrayAppend(out, new Role({name: roleName, hosts: entry}));
				} else if (isStruct(entry)) {
					// Shape 3: role → {hosts: [...], env: {...}, cmd: "..."}
					var hosts = (structKeyExists(entry, "hosts") && isArray(entry.hosts))
						? entry.hosts
						: [];
					var roleRaw = {name: roleName, hosts: hosts};
					if (structKeyExists(entry, "env")) roleRaw.env = entry.env;
					if (structKeyExists(entry, "cmd")) roleRaw.cmd = entry.cmd;
					if (structKeyExists(entry, "proxy")) roleRaw.proxy = entry.proxy;
					arrayAppend(out, new Role(roleRaw));
				}
			}
		}
		return out;
	}

	public string function absoluteImage(required string version) {
		var reg = registry().server();
		var prefix = (reg == "docker.io") ? "" : reg & "/";
		return prefix & image() & ":" & arguments.version;
	}

	public array function accessories() {
		var out = [];
		var raw = (structKeyExists(variables.raw, "accessories") && isStruct(variables.raw.accessories))
			? variables.raw.accessories
			: {};
		for (var name in raw) {
			arrayAppend(out, new Accessory(name, raw[name], variables.raw.service));
		}
		return out;
	}

	public any function accessory(required string name) {
		for (var acc in accessories()) {
			if (acc.name() == arguments.name) return acc;
		}
		throw(
			type = "DeployConfigError",
			message = "Unknown accessory: " & arguments.name & " (check deploy.yml accessories block)"
		);
	}

}
