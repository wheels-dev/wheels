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
		// Only keys the runtime actually reads (Config.cfc accessors + the
		// commands/ consumers behind them). Keys Kamal supports but this port
		// doesn't implement yet (logging, retain_containers, hooks, …) are
		// deliberately ABSENT so they fail loudly instead of being
		// accepted-and-ignored (##3088).
		variables.allowedKeys = [
			"service", "image", "servers", "registry", "builder", "env",
			"ssh", "proxy", "boot", "accessories"
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
				$raise(
					arguments.filePath,
					"unknown top-level key: '#k#' (allowed keys: #arrayToList(variables.allowedKeys, ', ')#)"
				);
			}
		}
		// Service / role / accessory names are interpolated raw into lock
		// paths, container names, and `--filter label=service=...` pipelines
		// (some piped to `xargs docker rm -f`), so they must be format-
		// validated rather than quoted (##2956).
		$validateName(arguments.parsed.service, "service", arguments.filePath);
		$validateServers(arguments.parsed.servers, arguments.filePath);
		$validateBoot(arguments.parsed, arguments.filePath);
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

	/**
	 * Validate the `boot:` block. `limit` accepts a non-negative number or a
	 * Kamal percentage string ("25%"); `wait` is a non-negative number of
	 * seconds. A non-struct `boot` value is left to the Config accessor's
	 * default-{} handling rather than rejected here.
	 */
	public void function $validateBoot(required struct parsed, required string filePath) {
		if (!structKeyExists(arguments.parsed, "boot")) return;
		var boot = arguments.parsed.boot;
		if (!isStruct(boot)) return;
		if (structKeyExists(boot, "limit")) $validateBootNumber(boot.limit, "boot.limit", arguments.filePath);
		if (structKeyExists(boot, "wait")) $validateBootNumber(boot.wait, "boot.wait", arguments.filePath);
	}

	public void function $validateBootNumber(required any value, required string key, required string filePath) {
		var ok = false;
		if (isNumeric(arguments.value)) {
			ok = arguments.value >= 0;
		} else if (isSimpleValue(arguments.value)) {
			var s = trim(arguments.value);
			if (len(s) && right(s, 1) == "%") s = left(s, len(s) - 1);
			ok = len(s) && isNumeric(s) && val(s) >= 0;
		}
		if (!ok) {
			$raise(
				arguments.filePath,
				"invalid #arguments.key#: '#arguments.value#' (must be a non-negative number or percentage)"
			);
		}
	}

	public void function $validateHost(required string host, required string filePath) {
		// A bare host or user@host is fine; user@host:port has 1 colon; IPv6
		// literals must be bracketed ([::1]:22) — anything else is ambiguous.
		// Count colons directly: listToArray(includeEmptyFields=false)
		// collapses adjacent/leading delimiters, so '::1:22' under-counted to
		// 1 colon and slipped through (##3086).
		var colonCount = len(arguments.host) - len(replace(arguments.host, ":", "", "all"));
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
