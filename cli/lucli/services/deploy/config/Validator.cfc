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
		// Service / role / accessory names are interpolated raw into lock
		// paths, container names, and `--filter label=service=...` pipelines
		// (some piped to `xargs docker rm -f`), so they must be format-
		// validated rather than quoted (##2956).
		$validateName(arguments.parsed.service, "service", arguments.filePath);
		$validateServers(arguments.parsed.servers, arguments.filePath);
		if (structKeyExists(arguments.parsed, "accessories") && isStruct(arguments.parsed.accessories)) {
			for (var accName in arguments.parsed.accessories) {
				$validateName(accName, "accessory", arguments.filePath);
			}
		}
	}

	public void function $validateServers(required any servers, required string filePath) {
		if (isArray(arguments.servers)) {
			for (var host in arguments.servers) $validateHost(host, arguments.filePath);
		} else if (isStruct(arguments.servers)) {
			for (var role in arguments.servers) {
				$validateName(role, "role", arguments.filePath);
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

	/**
	 * Docker-compliant name check (same shape Docker enforces for container
	 * names): leading alphanumeric, then alphanumerics, underscores, dots,
	 * and hyphens only. Anything else could inject into the remote shell
	 * via the unquoted interpolation sites listed in validate().
	 */
	public void function $validateName(required string name, required string kind, required string filePath) {
		if (!reFind("^[a-zA-Z0-9][a-zA-Z0-9_.-]*$", arguments.name)) {
			$raise(
				arguments.filePath,
				"invalid #arguments.kind# name: '#arguments.name#' (must match [a-zA-Z0-9][a-zA-Z0-9_.-]*)"
			);
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
