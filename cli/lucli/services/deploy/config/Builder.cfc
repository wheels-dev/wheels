/**
 * Builder — immutable accessor for the `builder:` block.
 *
 * Mirrors Kamal's lib/kamal/configuration/builder.rb defaults:
 *   context: "."          — docker build context
 *   dockerfile: Dockerfile
 *   args: {}              — --build-arg key=value pairs
 *   arch: [amd64]         — target platform(s) for multi-arch build
 *   remote: ""            — builder endpoint (empty = local docker)
 */
component {

	public any function init(struct raw = {}) {
		variables.raw = arguments.raw;
		return this;
	}

	public string function context() {
		return variables.raw.context ?: ".";
	}

	public string function dockerfile() {
		return variables.raw.dockerfile ?: "Dockerfile";
	}

	public struct function args() {
		return (structKeyExists(variables.raw, "args") && isStruct(variables.raw.args))
			? variables.raw.args
			: {};
	}

	public array function arch() {
		if (!structKeyExists(variables.raw, "arch")) return ["amd64"];
		// Kamal accepts either a scalar "amd64" or an array — normalize.
		if (isArray(variables.raw.arch)) return variables.raw.arch;
		return [variables.raw.arch];
	}

	public string function remote() {
		return variables.raw.remote ?: "";
	}

}
