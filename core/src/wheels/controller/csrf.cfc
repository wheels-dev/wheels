component {
	/**
	 * Tells CFWheels to protect `POST`ed requests from CSRF vulnerabilities.
	 * Instructs the controller to verify that `params.authenticityToken` or `X-CSRF-Token` HTTP header is provided along with the request containing a valid authenticity token.
	 * Call this method within a controller's `config` method, preferably the base `Controller.cfc` file, to protect the entire application.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @with How to handle invalid authenticity token checks. Valid values are `error` (throws a `Wheels.InvalidAuthenticityToken` error), `abort` (aborts the request silently and sends a blank response to the client), and `ignore` (ignores the check and lets the request proceed).
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
		if (StructKeyExists(variables.$class, "csrf")) {
			local.csrf = variables.$class.csrf;
			if (
				(!Len(local.csrf.only) && !Len(local.csrf.except))
				|| (Len(local.csrf.only) && ListFindNoCase(local.csrf.only, arguments.action))
				|| (Len(local.csrf.except) && !ListFindNoCase(local.csrf.except, arguments.action))
			) {
				$storeAuthenticityToken();
				$flagRequestAsProtected();
				$setAuthenticityToken();
				$verifyAuthenticityToken();
			}
		}
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
	public function $verifyAuthenticityToken() {
		if (!$isVerifiedRequest()) {
			switch (variables.$class.csrf.type) {
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
		if (!$isVerifiedRequest() && isAjax()) {
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
				local.isValid = CsrfVerifyToken(params.authenticityToken);
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
		return Len(local.authenticityToken) && local.authenticityToken == params.authenticityToken;
	}

	/**
	 * Internal function.
	 */
	public string function $generateCookieAuthenticityToken() {
		local.authenticityToken = $readAuthenticityTokenFromCookie();

		// If cookie doesn't yet exist, create it.
		if (!Len(local.authenticityToken)) {
			local.authenticityToken = GenerateSecretKey(application.wheels.csrfCookieEncryptionAlgorithm);
			local.value = SerializeJSON({sessionId = CreateUUID(), authenticityToken = local.authenticityToken});
			local.value = Encrypt(
				local.value,
				application.wheels.csrfCookieEncryptionSecretKey,
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
	 */
	public string function $readAuthenticityTokenFromCookie() {
		local.cookieName = application.wheels.csrfCookieName;

		// If no cookie, return empty string.
		if (!StructKeyExists(cookie, local.cookieName)) {
			return "";
		}

		// Cookie is there. Read it in.
		local.cookie = cookie[local.cookieName];

		try {
			local.cookieAttrs = Decrypt(
				local.cookie,
				application.wheels.csrfCookieEncryptionSecretKey,
				application.wheels.csrfCookieEncryptionAlgorithm,
				application.wheels.csrfCookieEncryptionEncoding
			);
		} catch (any e) {
			// When cookie is corrupted, return empty string.
			return "";
		}

		// If we don't have cookie attr from above for some strange reason, fail.
		if (!StructKeyExists(local, "cookieAttrs")) {
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
	 */
	public struct function $csrfCookieAttributeCollection(required string value) {
		local.cookieStruct = {
			value = arguments.value,
			encodeValue = application.wheels.csrfCookieEncodeValue,
			httpOnly = application.wheels.csrfCookieHttpOnly,
			preserveCase = application.wheels.csrfCookiePreserveCase,
			secure = application.wheels.csrfCookieSecure
		};
		if (Len(application.wheels.csrfCookieDomain)) {
			local.cookieStruct.domain = application.wheels.csrfCookieDomain;
		}
		if (Len(application.wheels.csrfCookiePath)) {
			local.cookieStruct.path = application.wheels.csrfCookiePath;
		}
		return local.cookieStruct;
	}
}
