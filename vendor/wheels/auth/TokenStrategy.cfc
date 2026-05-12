/**
 * Token-based authentication strategy for API keys and bearer tokens.
 *
 * Extracts a token from the `Authorization: Bearer <token>` header or
 * a configurable query parameter (default `api_key`). Validates the
 * token using either a validator callback or a static lookup struct.
 *
 * Validator callback signature:
 *   function(required string token) returns struct or false
 *   - On success: return a principal struct (e.g. {id: 42, role: "admin"})
 *   - On failure: return false (or a struct with success=false)
 *
 * Static lookup struct:
 *   {"my-api-key": {id: 1, role: "admin"}, "other-key": {id: 2, role: "reader"}}
 *
 * Usage:
 *   // With a validator callback
 *   var strategy = new wheels.auth.TokenStrategy(validator=function(token) {
 *       var key = model("ApiKey").findOne(where="token='#token#' AND active=1");
 *       if (isObject(key)) return {id: key.userId, role: key.role};
 *       return false;
 *   });
 *
 *   // With a static token map
 *   var strategy = new wheels.auth.TokenStrategy(tokens={"abc-123": {id: 1, role: "admin"}});
 *
 *   // Register with authenticator
 *   authenticator.registerStrategy(name="token", strategy=strategy);
 *
 * [section: Authentication]
 * [category: Strategies]
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	/**
	 * Creates a new TokenStrategy instance.
	 *
	 * @validator Callback function that receives a token string and returns a principal struct on success or false on failure.
	 * @tokens Static struct mapping token strings to principal structs. Used when no validator is provided.
	 * @queryParam Name of the query parameter to check for a token (default "api_key"). Set to empty string to disable.
	 * @headerName Name of the HTTP header to check (default "authorization"). Set to empty string to disable.
	 * @scheme Expected scheme prefix in the header value (default "Bearer"). Case-insensitive.
	 */
	public TokenStrategy function init(
		any validator = "",
		struct tokens = {},
		string queryParam = "api_key",
		string headerName = "authorization",
		string scheme = "Bearer"
	) {
		variables.validator = arguments.validator;
		variables.tokens = arguments.tokens;
		variables.queryParam = arguments.queryParam;
		variables.headerName = LCase(arguments.headerName);
		variables.scheme = arguments.scheme;
		variables.authResult = new wheels.auth.AuthResult();
		return this;
	}

	/**
	 * Return the unique name for this strategy.
	 */
	public string function getName() {
		return "token";
	}

	/**
	 * Check whether this request carries a token we can attempt to validate.
	 *
	 * Returns true if the request has an Authorization header with the
	 * expected scheme, or if the configured query parameter is present.
	 *
	 * @request Struct containing headers, params, cgi, etc.
	 */
	public boolean function supports(required struct request) {
		return Len($extractToken(arguments.request));
	}

	/**
	 * Attempt to authenticate the request by extracting and validating the token.
	 *
	 * @request Struct containing headers, params, cgi, etc.
	 * @return An AuthResult struct.
	 */
	public struct function authenticate(required struct request) {
		local.token = $extractToken(arguments.request);

		if (!Len(local.token)) {
			return variables.authResult.failure(
				error = "No token provided",
				statusCode = 401,
				strategy = getName()
			);
		}

		// Validate via callback or static lookup
		local.principal = $validateToken(local.token);

		if (IsStruct(local.principal) && !StructIsEmpty(local.principal)) {
			return variables.authResult.success(
				principal = local.principal,
				strategy = getName()
			);
		}

		return variables.authResult.failure(
			error = "Invalid or expired token",
			statusCode = 401,
			strategy = getName()
		);
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Extract the token from the request, checking the Authorization header
	 * first, then the query parameter.
	 *
	 * @request The request struct.
	 * @return The extracted token string, or empty string if none found.
	 */
	private string function $extractToken(required struct request) {
		local.token = "";

		// 1. Check Authorization header
		if (Len(variables.headerName)) {
			local.token = $extractFromHeader(arguments.request);
		}

		// 2. Fall back to query parameter
		if (!Len(local.token) && Len(variables.queryParam)) {
			local.token = $extractFromParam(arguments.request);
		}

		return local.token;
	}

	/**
	 * Extract token from the Authorization header.
	 * Expects format: "<scheme> <token>" (e.g. "Bearer abc-123").
	 */
	private string function $extractFromHeader(required struct request) {
		local.headerValue = "";

		// Check request.headers struct (middleware-normalized)
		if (StructKeyExists(arguments.request, "headers") && IsStruct(arguments.request.headers)) {
			if (StructKeyExists(arguments.request.headers, variables.headerName)) {
				local.headerValue = arguments.request.headers[variables.headerName];
			}
		}

		// Fall back to CGI scope (raw HTTP headers)
		if (!Len(local.headerValue) && StructKeyExists(arguments.request, "cgi") && IsStruct(arguments.request.cgi)) {
			local.cgiKey = "http_" & Replace(variables.headerName, "-", "_", "ALL");
			if (StructKeyExists(arguments.request.cgi, local.cgiKey)) {
				local.headerValue = arguments.request.cgi[local.cgiKey];
			}
		}

		if (!Len(local.headerValue)) {
			return "";
		}

		// If a scheme is configured, strip it (case-insensitive)
		if (Len(variables.scheme)) {
			local.prefix = variables.scheme & " ";
			if (Left(local.headerValue, Len(local.prefix)) == local.prefix
				|| LCase(Left(local.headerValue, Len(local.prefix))) == LCase(local.prefix)) {
				return Mid(local.headerValue, Len(local.prefix) + 1, Len(local.headerValue));
			}
			// Header present but wrong scheme — not our token
			return "";
		}

		// No scheme required — return the raw header value
		return local.headerValue;
	}

	/**
	 * Extract token from the query parameter.
	 */
	private string function $extractFromParam(required struct request) {
		// Check request.params (Wheels-parsed URL/form params)
		if (StructKeyExists(arguments.request, "params") && IsStruct(arguments.request.params)) {
			if (StructKeyExists(arguments.request.params, variables.queryParam)) {
				return arguments.request.params[variables.queryParam];
			}
		}

		// Check request.urlParams or request.url for raw query string params
		if (StructKeyExists(arguments.request, "urlParams") && IsStruct(arguments.request.urlParams)) {
			if (StructKeyExists(arguments.request.urlParams, variables.queryParam)) {
				return arguments.request.urlParams[variables.queryParam];
			}
		}

		return "";
	}

	/**
	 * Validate the token using the configured validator callback or static token map.
	 *
	 * @token The token string to validate.
	 * @return A principal struct on success, or an empty struct on failure.
	 */
	private struct function $validateToken(required string token) {
		// Callback validator takes priority
		if (IsClosure(variables.validator) || IsCustomFunction(variables.validator)) {
			local.result = variables.validator(arguments.token);

			// Callback returned a principal struct
			if (IsStruct(local.result)) {
				// Check for explicit success=false
				if (StructKeyExists(local.result, "success") && !local.result.success) {
					return {};
				}
				return local.result;
			}

			// Callback returned false or non-struct → failure
			return {};
		}

		// Static token lookup
		if (!StructIsEmpty(variables.tokens)) {
			if (StructKeyExists(variables.tokens, arguments.token)) {
				local.principal = variables.tokens[arguments.token];
				if (IsStruct(local.principal)) {
					return local.principal;
				}
			}
			return {};
		}

		// No validator and no tokens configured — reject
		return {};
	}

}
