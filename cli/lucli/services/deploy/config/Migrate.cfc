/**
 * Migrate — immutable accessor for the `migrate:` block (#4063).
 *
 *   migrate: true
 *
 *   migrate:
 *     host: 10.0.0.1   # optional; default: the first host of the first role
 *     timeout: 300     # optional; seconds the health check waits on that host
 *
 * When enabled, `wheels deploy` boots the migrate host first with
 * WHEELS_MIGRATE_ON_BOOT=true (the application migrates strictly at start, so a
 * failed migration fails its health check and stops the deploy before any
 * cutover) and every other app container with WHEELS_MIGRATE_ON_BOOT=false.
 * Without the block (or with `migrate: false`) nothing changes.
 */
component {

	public any function init(any raw = false) {
		variables.raw = arguments.raw;
		return this;
	}

	public boolean function enabled() {
		if (isStruct(variables.raw)) return true;
		return isBoolean(variables.raw) && variables.raw;
	}

	/** The configured migrate host, or "" for the default (first host of the first role). */
	public string function host() {
		if (isStruct(variables.raw) && structKeyExists(variables.raw, "host") && isSimpleValue(variables.raw.host)) {
			return trim(variables.raw.host);
		}
		return "";
	}

	/** Seconds kamal-proxy's health check waits on the migrate host (default 300). */
	public numeric function timeout() {
		if (
			isStruct(variables.raw)
			&& structKeyExists(variables.raw, "timeout")
			&& isNumeric(variables.raw.timeout)
			&& variables.raw.timeout > 0
		) {
			return variables.raw.timeout;
		}
		return 300;
	}

}
