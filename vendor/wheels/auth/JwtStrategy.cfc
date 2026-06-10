/**
 * JWT authentication strategy for the Wheels auth framework.
 *
 * Extracts a JWT bearer token from the Authorization header (or optional
 * query parameter), validates it via JwtService, and returns the decoded
 * claims as the authentication principal.
 *
 * Registration:
 *   var jwtService = new wheels.auth.JwtService(secretKey="a-random-secret-of-at-least-32-bytes");
 *   var jwtStrategy = new wheels.auth.JwtStrategy(jwtService=jwtService);
 *   authenticator.registerStrategy(name="jwt", strategy=jwtStrategy);
 *
 * [section: Authentication]
 * [category: Core]
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	/**
	 * Creates a new JwtStrategy instance.
	 *
	 * @jwtService A configured JwtService instance for token operations.
	 * @queryParam Optional query parameter name to read tokens from (e.g. "token"). Empty = disabled.
	 */
	public JwtStrategy function init(
		required any jwtService,
		string queryParam = ""
	) {
		variables.jwtService = arguments.jwtService;
		variables.queryParam = arguments.queryParam;
		variables.authResult = new wheels.auth.AuthResult();

		return this;
	}

	/**
	 * Return the strategy name.
	 */
	public string function getName() {
		return "jwt";
	}

	/**
	 * Check whether this request carries a JWT token.
	 *
	 * Returns true if an Authorization: Bearer header is present,
	 * or if the configured query parameter exists in the request params.
	 */
	public boolean function supports(required struct request) {
		return Len($extractToken(arguments.request)) > 0;
	}

	/**
	 * Authenticate the request by validating the JWT token.
	 *
	 * On success, returns an AuthResult with decoded claims as the principal.
	 * On failure, returns appropriate error and status code.
	 */
	public struct function authenticate(required struct request) {
		local.token = $extractToken(arguments.request);

		if (!Len(local.token)) {
			return variables.authResult.failure(
				error = "No JWT token found in request",
				statusCode = 401,
				strategy = getName()
			);
		}

		try {
			local.claims = variables.jwtService.decode(local.token);

			return variables.authResult.success(
				principal = local.claims,
				strategy = getName()
			);

		} catch ("Wheels.Auth.JWT.TokenExpired" e) {
			return variables.authResult.failure(
				error = "JWT token has expired",
				statusCode = 401,
				strategy = getName()
			);
		} catch ("Wheels.Auth.JWT.TokenNotYetValid" e) {
			return variables.authResult.failure(
				error = "JWT token is not yet valid",
				statusCode = 401,
				strategy = getName()
			);
		} catch ("Wheels.Auth.JWT.InvalidSignature" e) {
			return variables.authResult.failure(
				error = "JWT signature verification failed",
				statusCode = 401,
				strategy = getName()
			);
		} catch ("Wheels.Auth.JWT.InvalidToken" e) {
			return variables.authResult.failure(
				error = "Invalid JWT token format",
				statusCode = 401,
				strategy = getName()
			);
		} catch (any e) {
			return variables.authResult.failure(
				error = "JWT authentication error: " & e.message,
				statusCode = 401,
				strategy = getName()
			);
		}
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Extract the JWT token from the request.
	 * Checks Authorization header first, then optional query param.
	 */
	private string function $extractToken(required struct request) {
		// Check Authorization header
		if (StructKeyExists(arguments.request, "headers")
			&& StructKeyExists(arguments.request.headers, "authorization")) {
			local.authHeader = arguments.request.headers.authorization;
			if (Left(local.authHeader, 7) == "Bearer ") {
				return Mid(local.authHeader, 8, Len(local.authHeader) - 7);
			}
		}

		// Check query parameter if configured
		if (Len(variables.queryParam)
			&& StructKeyExists(arguments.request, "params")
			&& StructKeyExists(arguments.request.params, variables.queryParam)) {
			return arguments.request.params[variables.queryParam];
		}

		return "";
	}

}
