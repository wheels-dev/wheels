/**
 * Validator — schema checks for a parsed deploy.yml struct.
 *
 * Mirrors the guardrails Kamal's Ruby configuration applies:
 *   - required top-level keys (service/image/servers)
 *   - top-level keys restricted to a known allowlist (catch typos early)
 *   - host strings can't have >1 colon unless they're IPv6-bracketed
 *
 * Violations raise DeployConfigError with the source filePath + message so the
 * CLI can report exactly which file had the problem.
 */
component {

	public any function init() {
		variables.allowedKeys = [
			"service", "image", "servers", "registry", "builder", "env",
			"ssh", "proxy", "boot", "healthcheck", "hooks", "accessories",
			"volumes", "labels", "logging", "retain_containers",
			"minimum_version", "asset_path", "require_destination",
			"allow_empty_roles", "run_directory", "readiness_delay"
		];
		// Pre-build a case-insensitive struct lookup so the hot path doesn't
		// depend on arrayContainsNoCase (not available on every engine).
		variables.allowedLookup = {};
		for (var k in variables.allowedKeys) {
			variables.allowedLookup[lCase(k)] = true;
		}
		return this;
	}

	public void function validate(required struct parsed, required string filePath) {
		$requireKey(arguments.parsed, "service", arguments.filePath);
		$requireKey(arguments.parsed, "image", arguments.filePath);
		$requireKey(arguments.parsed, "servers", arguments.filePath);
		for (var k in arguments.parsed) {
			if (!structKeyExists(variables.allowedLookup, lCase(k))) {
				$raise(arguments.filePath, "unknown top-level key: '#k#'");
			}
		}
		$validateServers(arguments.parsed.servers, arguments.filePath);
	}

	public void function $validateServers(required any servers, required string filePath) {
		if (isArray(arguments.servers)) {
			for (var host in arguments.servers) $validateHost(host, arguments.filePath);
		} else if (isStruct(arguments.servers)) {
			for (var role in arguments.servers) {
				var entry = arguments.servers[role];
				if (isArray(entry)) {
					for (var host in entry) $validateHost(host, arguments.filePath);
				} else if (isStruct(entry) && structKeyExists(entry, "hosts") && isArray(entry.hosts)) {
					for (var host in entry.hosts) $validateHost(host, arguments.filePath);
				}
			}
		}
	}

	public void function $validateHost(required string host, required string filePath) {
		// A bare host or user@host is fine; user@host:port has 1 colon; IPv6
		// literals must be bracketed ([::1]:22) — anything else is ambiguous.
		var colonCount = arrayLen(listToArray(arguments.host, ":", false, true)) - 1;
		if (colonCount > 1 && left(arguments.host, 1) != "[") {
			$raise(arguments.filePath, "invalid host: '#arguments.host#'");
		}
	}

	public void function $requireKey(required struct parsed, required string key, required string filePath) {
		if (!structKeyExists(arguments.parsed, arguments.key)) {
			$raise(arguments.filePath, "missing required key: '#arguments.key#'");
		}
	}

	public void function $raise(required string filePath, required string message) {
		throw(
			type = "DeployConfigError",
			message = "#arguments.filePath#: #arguments.message#"
		);
	}

}
