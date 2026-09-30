<cfscript>
/*
 * Shared dev-tools guard for the public migrator endpoints. The
 * migrator command and template-create endpoints are dispatched via the
 * public component, outside the middleware pipeline and the controller CSRF
 * layer, and degrade to GET when URL rewriting is off. Both must enforce:
 * localhost only, no non-loopback forwarded clients, and a custom anti-CSRF
 * request header so a page the developer merely visits cannot auto-submit.
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

if (!StructKeyExists(variables, "$migratorApplyDevToolGuards")) {
	variables.$migratorApplyDevToolGuards = function() {
		$migratorEnforceLocalhost();
		$migratorEnforceNoForwardedClients();
		$migratorVerifyCsrfToken();
	};
}
</cfscript>
