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

	/**
	 * The target platforms. Kamal accepts a scalar ("amd64", or "amd64,arm64") or a list. Each entry
	 * goes into `docker buildx build --platform`, a shell command, so anything but a plain platform
	 * name (letters, digits, `.`, `_`, `/`, `-`) is refused here rather than quoted there (#4423).
	 */
	public array function arch() {
		if (!structKeyExists(variables.raw, "arch")) return ["amd64"];
		var entries = isArray(variables.raw.arch) ? variables.raw.arch : listToArray(toString(variables.raw.arch), ",");
		var rv = [];
		for (var entry in entries) {
			var value = trim(toString(entry));
			if (!len(value)) continue;
			if (!reFind("^[A-Za-z0-9._/-]+$", value)) {
				throw(
					type = "Wheels.Deploy.InvalidInput",
					message = "Invalid builder.arch '#value#' in deploy.yml: use platform names such as amd64, arm64 or linux/arm/v7 (letters, digits, '.', '_', '/' and '-')."
				);
			}
			arrayAppend(rv, value);
		}
		return arrayLen(rv) ? rv : ["amd64"];
	}

	public string function remote() {
		return variables.raw.remote ?: "";
	}

}
