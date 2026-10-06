component {
	/**
	 * Tells Wheels to protect `POST`ed requests from CSRF vulnerabilities.
	 * Instructs the controller to verify that `params.authenticityToken` or `X-CSRF-Token` HTTP header is provided along with the request containing a valid authenticity token.
	 * Call this method within a controller's `config` method, preferably the base `Controller.cfc` file, to protect the entire application.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @with How to handle invalid authenticity token checks. Valid values are `exception` (the default — throws a `Wheels.InvalidAuthenticityToken` error), `abort` (aborts the request silently and sends a blank response to the client), and `ignore` (ignores the check and lets the request proceed).
	 * @only List of actions that this check should only run on. Leave blank for all.
	 * @except List of actions that this check should be omitted from running on. Leave blank for no exceptions.
	 */
	public function protectsFromForgery(string with = "exception", string only = "", string except = "") {
		$args(args = arguments, name = "protectsFromForgery");

		// Store settings for this controller in `$class` for later use.
		variables.$class.csrf.type = arguments.with;
		variables.$class.csrf.only = arguments.only;
		variables.$class.csrf.except = arguments.except;
	}

	/**
	 * Returns the raw CSRF authenticity token
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 */
	public string function authenticityToken() {
		return $generateAuthenticityToken();
	}

	/**
	 * Internal function.
	 */
	public function $runCsrfProtection(string action) {
		// An instance-level override (set by processRequest()) wins over the class settings.
		// It lives on this controller instance only, so the cached class is never changed (#3843).
		if (StructKeyExists(variables, "$csrfOverride")) {
			local.csrf = variables.$csrfOverride;
		} else if (StructKeyExists(variables.$class, "csrf")) {
			local.csrf = variables.$class.csrf;
		} else {
			return;
		}
		if ($appliesToAction(action = arguments.action, only = local.csrf.only, except = local.csrf.except)) {
			$storeAuthenticityToken();
			$flagRequestAsProtected();
			$setAuthenticityToken();
			$verifyAuthenticityToken(type = local.csrf.type);
		}
	}

	/**
	 * Internal function.
	 *
	 * Applies CSRF handling (`exception`, `abort` or `ignore`) to every action of this controller
	 * instance, without touching the controller's class settings. Used by processRequest().
	 */
	public void function $setCsrfOverride(required string type) {
		variables.$csrfOverride = {type = arguments.type, only = "", except = ""};
	}

	/**
	 * Internal function.
	 */
	public function $flagRequestAsProtected() {
		request.$wheelsProtectedFromForgery = true;
	}

	/**
	 * Internal function.
	 */
	public function $verifyAuthenticityToken(string type = variables.$class.csrf.type) {
		if (!$isVerifiedRequest()) {
			switch (arguments.type) {
				case "abort":
					abort;
				case "ignore":
					return;
				default:
					Throw(
						type = "Wheels.InvalidAuthenticityToken",
						message = "This POSTed request was attempted without a valid authenticity token."
					);
			}
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $isVerifiedRequest() {
		return isGet() || isHead() || isOptions() || $isAnyAuthenticityTokenValid();
	}

	/**
	 * Internal function.
	 */
	public boolean function $isRequestProtectedFromForgery() {
		return StructKeyExists(request, "$wheelsProtectedFromForgery")
		&& IsBoolean(request.$wheelsProtectedFromForgery)
		&& request.$wheelsProtectedFromForgery;
	}

	/**
	 * Internal function.
	 */
	public function $setAuthenticityToken() {
		// The X-CSRF-Token header counts on any non-GET request, not only with
		// X-Requested-With (#3959). The token value is the protection: a cross-site
		// page can't read it, and X-Requested-With is itself a custom header with the
		// same CORS preflight. Clients that send the page's current token in this
		// header (Turbo, or a fetch() that sets it) don't send X-Requested-With. With
		// startFormTag/buttonTo(authenticityToken = false), this is how a form in
		// shared cached markup (which must not carry a token) takes the token at
		// request time.
		//
		// Rule when both are present: the request passes if EITHER the form field or
		// the header holds a valid token (Rails' behaviour). The header is consulted
		// only when the field didn't verify.
		if (!$isVerifiedRequest()) {
			if (StructKeyExists(request.$wheelsHeaders, "X-CSRF-Token")) {
				params.authenticityToken = request.$wheelsHeaders["X-CSRF-Token"];
			}
		}
	}

	/**
	 * Internal function.
	 */
	public function $storeAuthenticityToken() {
		$generateAuthenticityToken();
	}

	/**
	 * Internal function.
	 */
	public boolean function $isAnyAuthenticityTokenValid() {
		if ($isRequestProtectedFromForgery() && StructKeyExists(params, "authenticityToken")) {
			if (application.wheels.csrfStore == "session") {
				// Exact, case-sensitive and constant-time on every engine, the same way the
				// cookie store compares: the value must equal the session token
				// (CsrfGenerateToken() returns the current one; the form field uses it too).
				local.sessionToken = CsrfGenerateToken();
				local.isValid = Len(local.sessionToken)
					&& IsSimpleValue(params.authenticityToken)
					&& $secureCompare(local.sessionToken, params.authenticityToken);
			} else {
				local.isValid = $isCookieAuthenticityTokenValid();
			}
		} else {
			local.isValid = false;
		}
		return local.isValid;
	}

	/**
	 * Internal function.
	 */
	public string function $generateAuthenticityToken() {
		if (application.wheels.csrfStore == "session") {
			return CsrfGenerateToken();
		} else {
			return $generateCookieAuthenticityToken();
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $isCookieAuthenticityTokenValid() {
		local.authenticityToken = $generateCookieAuthenticityToken();
		// Exact and constant-time: CFML == ignores case and stops at the first difference.
		return Len(local.authenticityToken)
			&& IsSimpleValue(params.authenticityToken)
			&& $secureCompare(local.authenticityToken, params.authenticityToken);
	}

	/**
	 * Internal function.
	 * Ensures a valid CSRF cookie encryption key exists when csrfStore is "cookie".
	 */
	public string function $ensureCsrfCookieEncryptionKey() {
		if (!Len(application.wheels.csrfCookieEncryptionSecretKey)) {
			// In production, require explicit configuration
			if (application.wheels.environment == "production") {
				Throw(
					type = "Wheels.Security.MissingCsrfKey",
					message = "csrfCookieEncryptionSecretKey must be configured in production.",
					extendedInfo = "Set csrfCookieEncryptionSecretKey in your .env file or config/settings.cfm. Auto-generation is not allowed in production because the key is lost on application restart, invalidating all CSRF tokens."
				);
			}
			// In non-production, auto-generate with warning
			application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES");
			try {
				writeLog(
					text = "Wheels WARNING: csrfCookieEncryptionSecretKey was empty — auto-generated a temporary AES key. Set this in config/settings.cfm for persistence across restarts.",
					type = "warning",
					file = "wheels_security"
				);
			} catch (any e) {}
		}
		return application.wheels.csrfCookieEncryptionSecretKey;
	}

	/**
	 * Internal function.
	 */
	public string function $generateCookieAuthenticityToken() {
		local.authenticityToken = $readAuthenticityTokenFromCookie();

		// If cookie doesn't yet exist, create it.
		if (!Len(local.authenticityToken)) {
			local.encryptionKey = $ensureCsrfCookieEncryptionKey();
			// GenerateSecretKey() expects a bare cipher name ("AES"), not a full
			// transformation string ("AES/GCM/NoPadding"), so strip mode/padding.
			local.authenticityToken = GenerateSecretKey(ListFirst(application.wheels.csrfCookieEncryptionAlgorithm, "/"));
			local.value = SerializeJSON({sessionId = CreateUUID(), authenticityToken = local.authenticityToken});
			local.value = Encrypt(
				local.value,
				local.encryptionKey,
				application.wheels.csrfCookieEncryptionAlgorithm,
				application.wheels.csrfCookieEncryptionEncoding
			);

			if (application.wheels.csrfStore == "cookie") {
				cookie[application.wheels.csrfCookieName] = $csrfCookieAttributeCollection(local.value);
			} else {
				// Tests will mock the cookie in the request scope.
				request[application.wheels.csrfCookieName] = $csrfCookieAttributeCollection(local.value);
				request[application.wheels.csrfCookieName].authenticityToken = local.authenticityToken;
			}
		}

		return local.authenticityToken;
	}

	/**
	 * Internal function.
	 * The CSRF cookie's value as read from the cookie scope. When this request set the
	 * cookie (cookie[name] = {value, httpOnly, ...}), Lucee, Adobe and BoxLang read it
	 * back as its value, but RustCFML returns the struct that was assigned, so take its
	 * value. Anything else that isn't a string reads as no cookie ("").
	 */
	public string function $csrfCookieScopeValue(required any raw) {
		local.rv = arguments.raw;
		if (IsStruct(local.rv) && StructKeyExists(local.rv, "value")) {
			local.rv = local.rv.value;
		}
		return IsSimpleValue(local.rv) ? local.rv : "";
	}

	/**
	 * Internal function.
	 */
	public string function $readAuthenticityTokenFromCookie() {
		local.cookieName = application.wheels.csrfCookieName;

		// If no cookie, return empty string.
		if (!StructKeyExists(cookie, local.cookieName)) {
			return "";
		}

		// Cookie is there. Read it in.
		local.cookieValue = $csrfCookieScopeValue(cookie[local.cookieName]);
		if (!Len(local.cookieValue)) {
			return "";
		}

		try {
			local.encryptionKey = $ensureCsrfCookieEncryptionKey();
		} catch (any e) {
			// When no usable encryption key is available, treat the cookie as unreadable.
			return "";
		}

		local.cookieAttrs = $decryptCsrfCookieValue(local.cookieValue, local.encryptionKey);

		// When cookie is corrupted (or encrypted with an unknown key/algorithm), fail.
		if (!Len(local.cookieAttrs)) {
			return "";
		}

		// If we don't have JSON in cookie attrs, fail.
		if (!IsSimpleValue(local.cookieAttrs) || !IsJSON(local.cookieAttrs)) {
			return "";
		}

		// Now we have everything we need, deserialize.
		local.cookieAttrs = DeserializeJSON(local.cookieAttrs);

		// Check to make sure the JSON we decoded has the authenticity token in it.
		if (!StructKeyExists(local.cookieAttrs, "authenticityToken")) {
			return "";
		}

		return local.cookieAttrs.authenticityToken;
	}

	/**
	 * Internal function.
	 * Decrypts an encrypted CSRF cookie value using the configured algorithm, falling
	 * back to the legacy bare "AES" (ECB) algorithm so cookies issued before the
	 * engine-aware IV-based default (AES/GCM/NoPadding or AES/CBC/PKCS5Padding, see
	 * events/init/security.cfm) remain readable across the upgrade. Returns an empty
	 * string when the value cannot be decrypted with either algorithm.
	 */
	public string function $decryptCsrfCookieValue(required string encryptedValue, required string encryptionKey) {
		// State lives in a struct because local assignments made inside catch blocks
		// do not persist after the catch on BoxLang.
		local.state = {decrypted = ""};
		local.legacyAvailable = application.wheels.csrfCookieEncryptionAlgorithm != "AES";

		try {
			local.state.decrypted = Decrypt(
				arguments.encryptedValue,
				arguments.encryptionKey,
				application.wheels.csrfCookieEncryptionAlgorithm,
				application.wheels.csrfCookieEncryptionEncoding
			);
		} catch (any e) {
			// fall through to the legacy attempt below
		}

		// "Did not throw" is not the same as "decrypted correctly". Decrypting a
		// bare-AES (ECB) ciphertext under AES/CBC/PKCS5Padding throws only when the
		// trailing plaintext bytes fail padding validation, and they pass by chance
		// roughly 1 time in 256 — so Decrypt() returns garbage, the legacy fallback
		// never runs, and a perfectly good legacy cookie reads as corrupted (issue
		// #3361). AES/GCM/NoPadding is authenticated and does reliably throw, so this
		// only ever bit the engines that fall back to CBC.
		//
		// Checking the RESULT closes that window. This cookie's plaintext is always the
		// JSON written by $generateCookieAuthenticityToken(), so anything else means we
		// decrypted it with the wrong algorithm — which is exactly when the legacy
		// attempt should still run.
		if (local.legacyAvailable && !$isCsrfCookiePayload(local.state.decrypted)) {
			try {
				local.legacyDecrypted = Decrypt(
					arguments.encryptedValue,
					arguments.encryptionKey,
					"AES",
					application.wheels.csrfCookieEncryptionEncoding
				);
				// Only prefer the legacy result if it actually looks like the payload;
				// otherwise keep whatever the configured algorithm produced so a
				// genuinely corrupt cookie is not reported differently than before.
				if ($isCsrfCookiePayload(local.legacyDecrypted)) {
					local.state.decrypted = local.legacyDecrypted;
				}
			} catch (any legacyDecryptError) {
				// Undecryptable with either algorithm — treat as a corrupted cookie.
			}
		}

		return local.state.decrypted;
	}

	/**
	 * Internal function.
	 * Whether a decrypted string looks like the CSRF cookie payload rather than the
	 * garbage a wrong-algorithm decrypt can return without throwing.
	 *
	 * `$generateCookieAuthenticityToken()` always writes `SerializeJSON({sessionId,
	 * authenticityToken})`, so JSON-ness is an invariant of this cookie, not an
	 * assumption about it. The caller re-checks the same thing before deserializing.
	 */
	public boolean function $isCsrfCookiePayload(required string value) {
		return Len(arguments.value) > 0 && IsJSON(arguments.value);
	}

	/**
	 * Internal function.
	 */
	public struct function $csrfCookieAttributeCollection(required string value) {
		local.cookieStruct = {
			value = arguments.value,
			httpOnly = application.wheels.csrfCookieHttpOnly,
			secure = application.wheels.csrfCookieSecure
		};
		// encodeValue and preserveCase default to "" (the engine's own default).
		// Only set them when configured: Adobe CF rejects "" for these boolean
		// cookie attributes, so the first cookie-store token was an HTTP 500.
		if (Len(application.wheels.csrfCookieEncodeValue)) {
			local.cookieStruct.encodeValue = application.wheels.csrfCookieEncodeValue;
		}
		if (Len(application.wheels.csrfCookiePreserveCase)) {
			local.cookieStruct.preserveCase = application.wheels.csrfCookiePreserveCase;
		}
		if (Len(application.wheels.csrfCookieSameSite)) {
			local.cookieStruct.sameSite = application.wheels.csrfCookieSameSite;
		}
		if (Len(application.wheels.csrfCookieDomain)) {
			local.cookieStruct.domain = application.wheels.csrfCookieDomain;
		}
		if (Len(application.wheels.csrfCookiePath)) {
			local.cookieStruct.path = application.wheels.csrfCookiePath;
		}
		return local.cookieStruct;
	}
}
