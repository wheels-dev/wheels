/**
 * Interface for pluggable authentication backends.
 *
 * Each strategy knows how to extract credentials from a request
 * and validate them. Strategies are registered with an Authenticator
 * and tried in order (or by name) during authentication.
 *
 * [section: Authentication]
 * [category: Core]
 */
interface {

	/**
	 * Return the unique name for this strategy (e.g. "token", "session", "jwt").
	 */
	public string function getName();

	/**
	 * Attempt to authenticate the request.
	 *
	 * Returns an AuthResult struct:
	 * - success (boolean): true if credentials were valid
	 * - principal (struct): the authenticated identity (user id, roles, etc.)
	 * - strategy (string): the name of this strategy
	 * - error (string): human-readable error message on failure
	 * - statusCode (numeric): HTTP status code (200 on success, 401/403 on failure)
	 *
	 * If this strategy does not apply to the request (e.g. no Authorization
	 * header for a token strategy), return a failure result with statusCode 401.
	 * The Authenticator will try the next registered strategy.
	 *
	 * @request Struct containing route params, CGI info, and middleware-added data.
	 * @return An AuthResult struct.
	 */
	public struct function authenticate(required struct request);

	/**
	 * Check whether this strategy can handle the given request.
	 *
	 * Called by the Authenticator before authenticate() to allow fast
	 * short-circuiting without full credential validation. For example,
	 * a token strategy returns true only if an Authorization header is present.
	 *
	 * @request Struct containing route params, CGI info, and middleware-added data.
	 * @return True if this strategy should attempt authentication.
	 */
	public boolean function supports(required struct request);

}
