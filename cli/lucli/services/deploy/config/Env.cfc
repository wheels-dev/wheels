/**
 * Env — immutable accessor for the `env:` block.
 *
 * Mirrors Kamal's lib/kamal/configuration/env.rb. Three sub-keys:
 *   clear:  { KEY: value, ... }      — plain envs rendered into the env-file
 *   secret: [NAME, NAME, ...]        — names of secrets to fetch from host env
 *   tags:   { tagname: { ... }, ... } — role/host-scoped overrides
 */
component {

	public any function init(struct raw = {}) {
		variables.raw = arguments.raw;
		return this;
	}

	public struct function clear() {
		return (structKeyExists(variables.raw, "clear") && isStruct(variables.raw.clear))
			? variables.raw.clear
			: {};
	}

	public array function secret() {
		return (structKeyExists(variables.raw, "secret") && isArray(variables.raw.secret))
			? variables.raw.secret
			: [];
	}

	public struct function tags() {
		return (structKeyExists(variables.raw, "tags") && isStruct(variables.raw.tags))
			? variables.raw.tags
			: {};
	}

	public struct function raw() {
		return variables.raw;
	}

}
