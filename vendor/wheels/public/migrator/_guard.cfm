<cfscript>
/*
 * Shared dev-tools guard for the public migrator endpoints. The
 * migrator command and template-create endpoints are dispatched via the
 * public component, outside the middleware pipeline and the controller CSRF
 * layer, and degrade to GET when URL rewriting is off. Both must enforce:
 * localhost only, no non-loopback forwarded clients, a local Host header, and a
 * custom anti-CSRF request header so a page the developer merely visits cannot
 * auto-submit. The GUI views that issue the CSRF token share the network-origin
 * gates via $migratorEnforceLocalAccess() (everything except the token check).
 * Each helper is defined once (StructKeyExists guard) so re-including is safe.
 */
if (!StructKeyExists(variables, "$migratorEnforceLocalhost")) {
	variables.$migratorEnforceLocalhost = function() {
		// ── Security: localhost only ────────────────────
		local.remoteAddr = cgi.REMOTE_ADDR;
		local.isLocalhost = false;
		try {
			local.remoteInet = createObject("java", "java.net.InetAddress").getByName(local.remoteAddr);
			local.isLocalhost = local.remoteInet.isLoopbackAddress();
		} catch (any e) {
			local.isLocalhost = false;
		}
		if (!local.isLocalhost) {
			cfheader(statuscode=403);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Migrator commands are restricted to localhost");
			abort;
		}
	};
}

if (!StructKeyExists(variables, "$migratorEnforceNoForwardedClients")) {
	variables.$migratorEnforceNoForwardedClients = function() {
		// ── Security: X-Forwarded-For proxy bypass prevention ──
		if (len(trim(cgi.HTTP_X_FORWARDED_FOR))) {
			local.forwardedIps = listToArray(cgi.HTTP_X_FORWARDED_FOR);
			for (local.ip in local.forwardedIps) {
				try {
					local.fwdInet = createObject("java", "java.net.InetAddress").getByName(trim(local.ip));
					if (!local.fwdInet.isLoopbackAddress()) {
						cfheader(statuscode=403);
						cfcontent(type="text/plain", reset=true);
						writeOutput("Migrator commands are restricted to localhost");
						abort;
					}
				} catch (any e) {
					cfheader(statuscode=403);
					cfcontent(type="text/plain", reset=true);
					writeOutput("Migrator commands are restricted to localhost");
					abort;
				}
			}
		}
	};
}

if (!StructKeyExists(variables, "$migratorVerifyCsrfToken")) {
	variables.$migratorVerifyCsrfToken = function() {
		// ── Security: anti-CSRF token via custom request header ──
		// The token is generated when the migrator GUI renders (../views/migrator.cfm)
		// and must round-trip in the X-Wheels-Csrf-Token header. Cross-site pages
		// cannot set custom headers without a CORS preflight (which this endpoint
		// never approves), so auto-submitted GET/form requests are blocked. Fails
		// closed when no token has been issued yet.
		local.suppliedCsrfToken = "";
		local.requestHeaders = GetHTTPRequestData().headers;
		if (structKeyExists(local.requestHeaders, "X-Wheels-Csrf-Token") && isSimpleValue(local.requestHeaders["X-Wheels-Csrf-Token"])) {
			local.suppliedCsrfToken = local.requestHeaders["X-Wheels-Csrf-Token"];
		}
		local.csrfTokenValid = false;
		if (
			len(local.suppliedCsrfToken)
			&& structKeyExists(application, "wheels")
			&& structKeyExists(application.wheels, "$migratorCsrfToken")
			&& len(application.wheels.$migratorCsrfToken)
		) {
			// Constant-time comparison to prevent timing attacks
			local.inputBytes = Hash(local.suppliedCsrfToken, "SHA-256").getBytes("UTF-8");
			local.expectedBytes = Hash(application.wheels.$migratorCsrfToken, "SHA-256").getBytes("UTF-8");
			local.csrfTokenValid = CreateObject("java", "java.security.MessageDigest").isEqual(local.inputBytes, local.expectedBytes);
		}
		if (!local.csrfTokenValid) {
			cfheader(statuscode=403);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Missing or invalid migrator CSRF token. Open /wheels/migrator and use the GUI buttons.");
			abort;
		}
	};
}

if (!StructKeyExists(variables, "$migratorHostIsLocal")) {
	variables.$migratorHostIsLocal = function(required string hostHeader) {
		// Returns whether a Host-header value names the local machine. Uses plain
		// string checks — no DNS lookup — so the decision is about the NAME the
		// request was addressed to, not where that name happens to resolve.
		local.host = Trim(arguments.hostHeader);
		if (!Len(local.host)) {
			return false;
		}
		// Strip the optional port, handling a bracketed IPv6 literal first.
		if (Left(local.host, 1) == "[") {
			local.close = Find("]", local.host);
			if (local.close <= 2) {
				return false;
			}
			local.host = Mid(local.host, 2, local.close - 2);
		} else if (Find(":", local.host)) {
			local.host = ListFirst(local.host, ":");
		}
		local.host = LCase(Trim(local.host));
		// Built-in local names / loopback literals.
		if (ListFindNoCase("localhost,127.0.0.1,::1,0:0:0:0:0:0:0:1", local.host)) {
			return true;
		}
		// Any address in the 127.0.0.0/8 loopback block.
		if (ReFind("^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", local.host)) {
			return true;
		}
		// Extra host names the developer allowed via set(migratorAllowedHosts="...").
		local.extra = "";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "migratorAllowedHosts")) {
			local.extra = application.wheels.migratorAllowedHosts;
		}
		if (Len(local.extra) && ListFindNoCase(local.extra, local.host)) {
			return true;
		}
		return false;
	};
}

if (!StructKeyExists(variables, "$migratorEnforceLocalHostname")) {
	variables.$migratorEnforceLocalHostname = function() {
		// ── Security: request must be addressed to a local host name ──
		// cgi.HTTP_HOST is the Host header the browser sent. Requiring it to be a
		// local name means the dev tools only answer requests addressed to the
		// local machine, even though the socket itself is already loopback.
		local.hostHeader = StructKeyExists(cgi, "HTTP_HOST") ? cgi.HTTP_HOST : "";
		if (!$migratorHostIsLocal(hostHeader = local.hostHeader)) {
			cfheader(statuscode=403);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Migrator dev tools only accept requests addressed to a local host name (localhost, 127.0.0.1, or [::1]). Allow another local name with set(migratorAllowedHosts=""your.host"").");
			abort;
		}
	};
}

if (!StructKeyExists(variables, "$migratorEnforceLocalAccess")) {
	variables.$migratorEnforceLocalAccess = function() {
		// The network-origin gates shared by the dev-tool endpoints and by the
		// token-issuing GUI views: localhost socket, no non-loopback forwarded
		// clients, and a local Host header. Deliberately excludes the CSRF-token
		// check, which the GUI views cannot satisfy — they issue the token.
		$migratorEnforceLocalhost();
		$migratorEnforceNoForwardedClients();
		$migratorEnforceLocalHostname();
	};
}

if (!StructKeyExists(variables, "$migratorApplyDevToolGuards")) {
	variables.$migratorApplyDevToolGuards = function() {
		$migratorEnforceLocalAccess();
		$migratorVerifyCsrfToken();
	};
}
</cfscript>
