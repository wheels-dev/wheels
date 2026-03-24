/**
 * Interface for authenticating incoming requests.
 *
 * Implementations coordinate one or more AuthStrategy instances
 * to determine whether a request carries valid credentials.
 *
 * [section: Authentication]
 * [category: Core]
 */
interface {

	/**
	 * Authenticate the incoming request using registered strategies.
	 *
	 * @request Struct containing route params, CGI info, and any data added by prior middleware.
	 * @return An AuthResult struct: {success, principal, strategy, error, statusCode}.
	 */
	public struct function authenticate(required struct request);

	/**
	 * Register an authentication strategy under the given name.
	 *
	 * @name Unique identifier for this strategy (e.g. "token", "session", "jwt").
	 * @strategy Component that implements AuthStrategy.
	 */
	public any function registerStrategy(required string name, required any strategy);

	/**
	 * Remove a previously registered strategy.
	 *
	 * @name The strategy name to remove.
	 */
	public any function removeStrategy(required string name);

	/**
	 * Check if a strategy is registered under the given name.
	 *
	 * @name The strategy name to check.
	 */
	public boolean function hasStrategy(required string name);

	/**
	 * Return an array of registered strategy names.
	 */
	public array function getStrategyNames();

}
