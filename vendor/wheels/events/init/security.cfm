<cfscript>
		// CSRF protection settings.
		application.$wheels.csrfStore = "session";
		// Prefer AES/GCM/NoPadding (authenticated encryption) — bare "AES" resolves to
		// insecure ECB mode. Not every engine supports GCM through Encrypt()/Decrypt()
		// (Lucee builds an IvParameterSpec internally, which the JDK GCM cipher rejects
		// with "AlgorithmParameterSpec not of GCMParameterSpec"), so probe at startup
		// and fall back to AES/CBC/PKCS5Padding (random-IV CBC), then to legacy bare
		// "AES" as a last resort. Cookies written under the legacy bare "AES" default
		// remain readable via the decrypt fallback in csrf.cfc's $decryptCsrfCookieValue().
		application.$wheels.csrfCookieEncryptionAlgorithm = "AES";
		local.csrfCipherProbeKey = GenerateSecretKey("AES");
		for (local.csrfCipherCandidate in ["AES/GCM/NoPadding", "AES/CBC/PKCS5Padding"]) {
			try {
				if (
					Decrypt(
						Encrypt("wheels", local.csrfCipherProbeKey, local.csrfCipherCandidate, "Base64"),
						local.csrfCipherProbeKey,
						local.csrfCipherCandidate,
						"Base64"
					) == "wheels"
				) {
					application.$wheels.csrfCookieEncryptionAlgorithm = local.csrfCipherCandidate;
					break;
				}
			} catch (any e) {
				// Engine can't run this transformation through Encrypt()/Decrypt(); try the next one.
			}
		}
		application.$wheels.csrfCookieEncryptionSecretKey = "";
		application.$wheels.csrfCookieEncryptionEncoding = "Base64";
		application.$wheels.csrfCookieName = "_wheels_authenticity";
		application.$wheels.csrfCookieDomain = "";
		application.$wheels.csrfCookieEncodeValue = "";
		application.$wheels.csrfCookieHttpOnly = true;
		application.$wheels.csrfCookiePath = "/";
		application.$wheels.csrfCookiePreserveCase = "";
		application.$wheels.csrfCookieSecure = true;
		application.$wheels.csrfCookieSameSite = "Lax";

		// CORS (Cross-Origin Resource Sharing) settings.
		application.$wheels.allowCorsRequests = false;
		application.$wheels.accessControlAllowOrigin = "";
		application.$wheels.accessControlAllowMethods = "GET, POST, PATCH, PUT, DELETE, OPTIONS";
		application.$wheels.accessControlAllowMethodsByRoute = false;
		application.$wheels.accessControlAllowCredentials = false;
		application.$wheels.accessControlAllowHeaders = "Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With";

		// Redirect security settings.
		application.$wheels.allowExternalRedirects = false;

		// IP based restriction settings
		application.$wheels.debugAccessIPs = [];
		application.$wheels.allowIPBasedDebugAccess = false;
		// Only when true is X-Forwarded-For consulted when resolving the client IP for
		// debug access. Leave false unless the app sits behind a trusted reverse proxy.
		application.$wheels.debugAccessTrustProxy = false;

		// Trusted proxy settings.
		// Only when true are X-Forwarded-* headers honored framework-wide: X-Forwarded-Proto in
		// isSecure(), and X-Forwarded-For (rightmost hop) for maintenance-mode IP exceptions and
		// reload rate-limit keying. Leave false unless the app sits behind a trusted reverse proxy
		// that overwrites — never appends to — these headers.
		application.$wheels.trustProxyHeaders = false;
</cfscript>
