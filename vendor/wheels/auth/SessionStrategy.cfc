/**
 * Session-based authentication strategy for Wheels.
 *
 * Authenticates requests by checking for a user identity stored in the
 * CFML session scope. This strategy handles the classic login/logout
 * lifecycle: call `login()` after credential verification to establish
 * the session, and `logout()` to tear it down.
 *
 * The session key is configurable (default: `wheels.auth`). The value
 * stored at that key is returned as the AuthResult `principal` struct.
 *
 * Usage:
 *   // Register during app init
 *   var sessionAuth = new wheels.auth.SessionStrategy();
 *   authenticator.registerStrategy(name="session", strategy=sessionAuth);
 *
 *   // After verifying credentials in a login action:
 *   sessionAuth.login(principal={id=user.id, role=user.role});
 *
 *   // In a logout action:
 *   sessionAuth.logout();
 *
 * [section: Authentication]
 * [category: Strategies]
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	/**
	 * Creates a new SessionStrategy.
	 *
	 * @sessionKey Dot-delimited key path in the session scope (default: "wheels.auth").
	 * @onLogin    Optional callback invoked after login with the principal struct.
	 * @onLogout   Optional callback invoked after logout.
	 */
	public SessionStrategy function init(
		string sessionKey = "wheels.auth",
		any onLogin = "",
		any onLogout = ""
	) {
		variables.sessionKey = arguments.sessionKey;
		variables.onLogin = arguments.onLogin;
		variables.onLogout = arguments.onLogout;
		variables.resultFactory = new wheels.auth.AuthResult();
		return this;
	}

	/**
	 * Return the strategy name.
	 */
	public string function getName() {
		return "session";
	}

	/**
	 * Check whether a session-based identity exists.
	 *
	 * Returns true if the configured session key is populated.
	 * Does NOT require an Authorization header — session auth uses cookies.
	 *
	 * @request Struct containing route params, CGI info, and middleware-added data.
	 */
	public boolean function supports(required struct request) {
		return $hasSessionPrincipal();
	}

	/**
	 * Authenticate the request using the session.
	 *
	 * Returns a success result with the stored principal, or a failure
	 * result if the session key is empty or missing.
	 *
	 * @request Struct containing route params, CGI info, and middleware-added data.
	 */
	public struct function authenticate(required struct request) {
		local.principal = $getSessionPrincipal();

		if (IsStruct(local.principal) && !StructIsEmpty(local.principal)) {
			return variables.resultFactory.success(
				principal = local.principal,
				strategy = getName()
			);
		}

		return variables.resultFactory.failure(
			error = "No active session",
			statusCode = 401,
			strategy = getName()
		);
	}

	/**
	 * Establish an authenticated session.
	 *
	 * Stores the principal in the session scope at the configured key
	 * and optionally invokes the onLogin callback.
	 *
	 * @principal Struct representing the authenticated identity (user id, roles, etc.).
	 */
	public void function login(required struct principal) {
		$setSessionPrincipal(arguments.principal);

		if (IsCustomFunction(variables.onLogin) || IsClosure(variables.onLogin)) {
			variables.onLogin(arguments.principal);
		}
	}

	/**
	 * Destroy the authenticated session.
	 *
	 * Clears the principal from the session scope and optionally
	 * invokes the onLogout callback.
	 */
	public void function logout() {
		$clearSessionPrincipal();

		if (IsCustomFunction(variables.onLogout) || IsClosure(variables.onLogout)) {
			variables.onLogout();
		}
	}

	/**
	 * Return the current session principal, or an empty struct if not logged in.
	 */
	public struct function currentUser() {
		local.principal = $getSessionPrincipal();
		if (IsStruct(local.principal)) {
			return local.principal;
		}
		return {};
	}

	/**
	 * Check whether there is an active authenticated session.
	 */
	public boolean function isLoggedIn() {
		return $hasSessionPrincipal();
	}

	/**
	 * Return the configured session key.
	 */
	public string function getSessionKey() {
		return variables.sessionKey;
	}

	// ---------------------------------------------------------------------------
	// Private session scope helpers
	// ---------------------------------------------------------------------------

	/**
	 * Check if the session principal exists and is non-empty.
	 */
	private boolean function $hasSessionPrincipal() {
		local.val = $getSessionPrincipal();
		return IsStruct(local.val) && !StructIsEmpty(local.val);
	}

	/**
	 * Read the principal from the session scope using the configured dot-path key.
	 *
	 * Supports nested keys like "wheels.auth" by traversing the session struct.
	 * Returns an empty struct if any segment is missing.
	 */
	private any function $getSessionPrincipal() {
		local.segments = ListToArray(variables.sessionKey, ".");
		local.current = session;

		for (local.seg in local.segments) {
			if (IsStruct(local.current) && StructKeyExists(local.current, local.seg)) {
				local.current = local.current[local.seg];
			} else {
				return {};
			}
		}

		return local.current;
	}

	/**
	 * Write the principal into the session scope at the configured dot-path key.
	 *
	 * Creates intermediate structs as needed for nested keys.
	 */
	private void function $setSessionPrincipal(required struct principal) {
		local.segments = ListToArray(variables.sessionKey, ".");
		local.current = session;

		// Navigate/create intermediate segments
		for (local.i = 1; local.i < ArrayLen(local.segments); local.i++) {
			local.seg = local.segments[local.i];
			if (!StructKeyExists(local.current, local.seg) || !IsStruct(local.current[local.seg])) {
				local.current[local.seg] = {};
			}
			local.current = local.current[local.seg];
		}

		// Set the value at the final segment
		local.current[local.segments[ArrayLen(local.segments)]] = arguments.principal;
	}

	/**
	 * Clear the principal from the session scope.
	 */
	private void function $clearSessionPrincipal() {
		local.segments = ListToArray(variables.sessionKey, ".");
		local.current = session;

		// Navigate to the parent of the final segment
		for (local.i = 1; local.i < ArrayLen(local.segments); local.i++) {
			local.seg = local.segments[local.i];
			if (IsStruct(local.current) && StructKeyExists(local.current, local.seg)) {
				local.current = local.current[local.seg];
			} else {
				return; // Path doesn't exist, nothing to clear
			}
		}

		// Delete the final segment
		StructDelete(local.current, local.segments[ArrayLen(local.segments)]);
	}

}
