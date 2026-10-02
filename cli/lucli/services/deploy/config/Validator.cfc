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
			"ssh", "proxy", "boot", "accessories", "volumes"
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
		$validateImage(arguments.parsed.image, "image", arguments.filePath);
		// kamal-proxy's --tls needs a host to request a certificate for.
		if (
			structKeyExists(arguments.parsed, "proxy") && isStruct(arguments.parsed.proxy)
			&& isBoolean(arguments.parsed.proxy.ssl ?: false) && (arguments.parsed.proxy.ssl ?: false)
			&& !len(trim(arguments.parsed.proxy.host ?: ""))
		) {
			$raise(arguments.filePath, "proxy.ssl requires proxy.host (the host name TLS is issued for)");
		}
		$validateServers(arguments.parsed.servers, arguments.filePath);
		$validateVolumes(arguments.parsed, arguments.filePath);
		$validateBoot(arguments.parsed, arguments.filePath);
		if (structKeyExists(arguments.parsed, "accessories") && isStruct(arguments.parsed.accessories)) {
			for (var accName in arguments.parsed.accessories) {
				$validateName(accName, "accessory", arguments.filePath);
				var acc = arguments.parsed.accessories[accName];
				if (isStruct(acc)) {
					if (structKeyExists(acc, "image")) {
						$validateImage(acc.image, "accessory #accName# image", arguments.filePath);
					}
					for (var hostKey in ["host", "hosts"]) {
						if (structKeyExists(acc, hostKey)) {
							for (var accHost in (isArray(acc[hostKey]) ? acc[hostKey] : [acc[hostKey]])) {
								$validateHost(accHost, arguments.filePath);
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Top-level `volumes:` (Kamal): a list of `host:container` or
	 * `host:container:ro|rw` mounts for every app container, where host is a
	 * path or a named volume and container is an absolute path (#4018).
	 */
	public void function $validateVolumes(required struct parsed, required string filePath) {
		if (!structKeyExists(arguments.parsed, "volumes")) return;
		if (!isArray(arguments.parsed.volumes)) {
			$raise(arguments.filePath, "volumes must be a list of host:container mounts, e.g. - /var/lib/myapp/db:/var/www/db");
		}
		var i = 0;
		for (var entry in arguments.parsed.volumes) {
			i++;
			var parts = isSimpleValue(entry) ? listToArray(entry, ":", true) : [];
			var shapeOk = (arrayLen(parts) == 2 || (arrayLen(parts) == 3 && listFind("ro,rw", lCase(parts[3]))))
				&& len(trim(parts[1])) && left(parts[2], 1) == "/";
			if (!shapeOk) {
				$raise(
					arguments.filePath,
					"volumes[#i#] must be host:container or host:container:ro|rw with an absolute container path (got '#isSimpleValue(entry) ? entry : "a non-string value"#')"
				);
			}
		}
	}

	public void function $validateServers(required any servers, required string filePath) {
		// No hosts means nothing to deploy to: a dry run "succeeded" with no
		// output and a real deploy did nothing, both with exit 0.
		if ($serverHostCount(arguments.servers) == 0) {
			$raise(arguments.filePath, "servers lists no hosts; add at least one host to deploy to");
		}
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

	/** Hosts listed under servers:, as a list or by role (role: [hosts] or role: {hosts: [...]}). */
	public numeric function $serverHostCount(required any servers) {
		var count = 0;
		if (isArray(arguments.servers)) {
			return arrayLen(arguments.servers);
		}
		if (isStruct(arguments.servers)) {
			for (var role in arguments.servers) {
				var entry = arguments.servers[role];
				if (isArray(entry)) {
					count += arrayLen(entry);
				} else if (isStruct(entry) && structKeyExists(entry, "hosts") && isArray(entry.hosts)) {
					count += arrayLen(entry.hosts);
				}
			}
		}
		return count;
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

	/**
	 * Image references go into local `bash -c` build commands and remote
	 * `docker pull`/`run`. Allow the reference grammar's characters only
	 * (registry host, port, path, tag, digest), checked as a negated class
	 * plus explicit bounds so a trailing line feed can't pass (`$` matches
	 * before one in the CFML regex dialect).
	 */
	public void function $validateImage(required any image, required string kind, required string filePath) {
		if (
			!isSimpleValue(arguments.image)
			|| len(arguments.image) < 1 || len(arguments.image) > 255
			|| reFind("[^A-Za-z0-9._/:@-]", arguments.image)
			|| !reFind("^[A-Za-z0-9]", arguments.image)
		) {
			$raise(arguments.filePath, "invalid #arguments.kind#: '#arguments.image#' (letters, digits and . _ / : @ - only)");
		}
	}

	public void function $validateHost(required string host, required string filePath) {
		// Hosts reach ssh and remote shell commands: allow host-name, IP,
		// user@host:port and [IPv6] characters only, starting with an
		// alphanumeric or '[' (a leading '-' would read as an ssh option).
		if (
			len(arguments.host) < 1 || len(arguments.host) > 255
			|| reFind("[^A-Za-z0-9._:@\[\]-]", arguments.host)
			|| !reFind("^[A-Za-z0-9\[]", arguments.host)
		) {
			$raise(arguments.filePath, "invalid host: '#arguments.host#'");
		}
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
		// Negated class plus first-character check, not ^...$: `$` also matches
		// before a trailing line feed in the CFML regex dialect.
		if (!len(arguments.name) || reFind("[^a-zA-Z0-9_.-]", arguments.name) || !reFind("^[a-zA-Z0-9]", arguments.name)) {
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
