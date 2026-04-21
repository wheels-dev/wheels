/**
 * Proxy — immutable accessor for the `proxy:` block.
 *
 * Mirrors Kamal's lib/kamal/configuration/proxy.rb. Kamal-proxy runs on each
 * host and terminates TLS / routes traffic to the app container:
 *   host:         public hostname the proxy binds to
 *   ssl:          whether to terminate TLS at the proxy
 *   app_port:     port the app listens on inside the container (default 80)
 *   healthcheck:  {path, interval_sec, timeout_sec} — readiness probe
 */
component {

	public any function init(struct raw = {}) {
		variables.raw = arguments.raw;
		return this;
	}

	public string function host() {
		return variables.raw.host ?: "";
	}

	public boolean function ssl() {
		if (!structKeyExists(variables.raw, "ssl")) return false;
		return isBoolean(variables.raw.ssl) ? variables.raw.ssl : false;
	}

	public numeric function appPort() {
		// Support both snake_case (YAML) and camelCase, mirroring Kamal's
		// preference for snake_case but tolerating the CFML convention.
		if (structKeyExists(variables.raw, "app_port")) return variables.raw.app_port;
		if (structKeyExists(variables.raw, "appPort")) return variables.raw.appPort;
		return 80;
	}

	public struct function healthcheck() {
		var defaults = {path: "/up", interval: 1, timeout: 30};
		if (!structKeyExists(variables.raw, "healthcheck") || !isStruct(variables.raw.healthcheck)) {
			return defaults;
		}
		var merged = duplicate(defaults);
		for (var k in variables.raw.healthcheck) {
			merged[k] = variables.raw.healthcheck[k];
		}
		return merged;
	}

}
