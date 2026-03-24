/**
 * Factory for creating standardized authentication result structs.
 *
 * AuthResult is a plain struct with keys:
 * - success (boolean): whether authentication succeeded
 * - principal (struct): the authenticated identity (user id, roles, claims, etc.)
 * - strategy (string): name of the strategy that produced this result
 * - error (string): human-readable error message (empty on success)
 * - statusCode (numeric): HTTP status code (200, 401, 403)
 *
 * Strategies use the static-style factory methods to build consistent results.
 *
 * Usage:
 *   var ok = new wheels.auth.AuthResult().success(principal={id: 42, role: "admin"}, strategy="token");
 *   var fail = new wheels.auth.AuthResult().failure(error="Token expired", statusCode=401, strategy="jwt");
 *
 * [section: Authentication]
 * [category: Core]
 */
component output="false" {

	public AuthResult function init() {
		return this;
	}

	/**
	 * Create a successful authentication result.
	 *
	 * @principal Struct representing the authenticated identity.
	 * @strategy The name of the strategy that authenticated the request.
	 */
	public struct function success(required struct principal, string strategy = "") {
		return {
			success = true,
			principal = arguments.principal,
			strategy = arguments.strategy,
			error = "",
			statusCode = 200
		};
	}

	/**
	 * Create a failed authentication result.
	 *
	 * @error Human-readable error message.
	 * @statusCode HTTP status code (default 401).
	 * @strategy The name of the strategy that failed.
	 */
	public struct function failure(string error = "Authentication failed", numeric statusCode = 401, string strategy = "") {
		return {
			success = false,
			principal = {},
			strategy = arguments.strategy,
			error = arguments.error,
			statusCode = arguments.statusCode
		};
	}

}
