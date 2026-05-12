/**
 * Default Authenticator implementation with a pluggable strategy registry.
 *
 * Strategies are tried in registration order. The first strategy whose
 * `supports()` returns true gets a chance to authenticate. If it fails,
 * the next supporting strategy is tried. Authentication stops at the
 * first success or when all supporting strategies have been exhausted.
 *
 * Usage in config/services.cfm:
 *   var auth = injector().map("authenticator").to("wheels.auth.Authenticator").asSingleton();
 *
 * Usage from middleware or controllers:
 *   var result = service("authenticator").authenticate(request);
 *   if (!result.success) { ... }
 *
 * [section: Authentication]
 * [category: Core]
 */
component implements="wheels.auth.AuthenticatorInterface" output="false" {

	/**
	 * Creates a new Authenticator instance.
	 *
	 * @strategies Optional array of strategy instances to register on init.
	 * @defaultStrategy Name of the default strategy to try first (empty = try all in order).
	 */
	public Authenticator function init(
		array strategies = [],
		string defaultStrategy = ""
	) {
		// Ordered array of {name, strategy} structs preserves insertion order
		variables.strategies = [];
		// Lookup map for O(1) name-based access
		variables.strategyMap = {};
		variables.defaultStrategy = arguments.defaultStrategy;

		// Register any strategies passed at construction
		for (local.s in arguments.strategies) {
			registerStrategy(name = local.s.getName(), strategy = local.s);
		}

		return this;
	}

	/**
	 * Authenticate the incoming request using registered strategies.
	 *
	 * If `defaultStrategy` is set and registered, that strategy is tried first.
	 * Otherwise, strategies are tried in registration order. Only strategies
	 * whose `supports()` returns true are attempted.
	 *
	 * @request Struct containing route params, CGI info, and middleware-added data.
	 * @return An AuthResult struct.
	 */
	public struct function authenticate(required struct request) {
		// Diagnostic check: zero registered strategies is almost always a wiring bug.
		// Distinguish it from "strategies registered but none claim this request"
		// so a misconfigured services.cfm or a missing onApplicationStart hook
		// fails loudly instead of looking like an expired session.
		if (ArrayLen(variables.strategies) == 0) {
			return $authResult(
				success = false,
				error = "No authentication strategies registered. Check that config/services.cfm registers an Authenticator and a strategy as singletons, and that registerStrategy() is being called on the same Authenticator instance returned by service('authenticator'). See the auth chapter in the Wheels guides for the wiring.",
				statusCode = 401
			);
		}

		// Determine which strategies to try and in what order
		local.toTry = $buildStrategyOrder(arguments.request);

		if (ArrayLen(local.toTry) == 0) {
			return $authResult(
				success = false,
				error = "No authentication strategy supports this request",
				statusCode = 401
			);
		}

		// Try each supporting strategy in order
		local.lastError = "";
		local.lastStatusCode = 401;

		for (local.entry in local.toTry) {
			local.result = local.entry.strategy.authenticate(arguments.request);

			if (local.result.success) {
				// Stamp the strategy name if not already set
				if (!Len(local.result.strategy)) {
					local.result.strategy = local.entry.name;
				}
				return local.result;
			}

			// Track last failure for reporting
			local.lastError = local.result.error;
			local.lastStatusCode = local.result.statusCode;
		}

		// All strategies failed
		return $authResult(
			success = false,
			error = local.lastError,
			statusCode = local.lastStatusCode
		);
	}

	/**
	 * Register an authentication strategy under the given name.
	 * If a strategy with this name already exists, it is replaced.
	 *
	 * @name Unique identifier for this strategy.
	 * @strategy Component that implements AuthStrategy.
	 */
	public any function registerStrategy(required string name, required any strategy) {
		// Remove existing entry if re-registering
		if (hasStrategy(arguments.name)) {
			removeStrategy(arguments.name);
		}

		ArrayAppend(variables.strategies, {
			name = arguments.name,
			strategy = arguments.strategy
		});
		variables.strategyMap[arguments.name] = arguments.strategy;

		return this;
	}

	/**
	 * Remove a previously registered strategy.
	 *
	 * @name The strategy name to remove.
	 */
	public any function removeStrategy(required string name) {
		StructDelete(variables.strategyMap, arguments.name);

		// Remove from ordered array
		for (local.i = ArrayLen(variables.strategies); local.i >= 1; local.i--) {
			if (variables.strategies[local.i].name == arguments.name) {
				ArrayDeleteAt(variables.strategies, local.i);
				break;
			}
		}

		return this;
	}

	/**
	 * Check if a strategy is registered under the given name.
	 *
	 * @name The strategy name to check.
	 */
	public boolean function hasStrategy(required string name) {
		return StructKeyExists(variables.strategyMap, arguments.name);
	}

	/**
	 * Return an array of registered strategy names in registration order.
	 */
	public array function getStrategyNames() {
		local.names = [];
		for (local.entry in variables.strategies) {
			ArrayAppend(local.names, local.entry.name);
		}
		return local.names;
	}

	/**
	 * Return a registered strategy by name.
	 *
	 * @name The strategy name to retrieve.
	 */
	public any function getStrategy(required string name) {
		if (!hasStrategy(arguments.name)) {
			throw(
				type = "Wheels.Auth.StrategyNotFound",
				message = "No authentication strategy registered with name '#arguments.name#'"
			);
		}
		return variables.strategyMap[arguments.name];
	}

	/**
	 * Set the default strategy name. This strategy is tried first during authentication.
	 *
	 * @name Strategy name, or empty string to clear the default.
	 */
	public any function setDefaultStrategy(required string name) {
		variables.defaultStrategy = arguments.name;
		return this;
	}

	/**
	 * Return the current default strategy name.
	 */
	public string function getDefaultStrategy() {
		return variables.defaultStrategy;
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Build the ordered list of strategies to try for this request.
	 * Filters to only those whose supports() returns true.
	 * If a defaultStrategy is set, it is tried first.
	 */
	private array function $buildStrategyOrder(required struct request) {
		local.result = [];

		// If a default strategy is set, try it first
		if (Len(variables.defaultStrategy) && hasStrategy(variables.defaultStrategy)) {
			local.defaultEntry = {
				name = variables.defaultStrategy,
				strategy = variables.strategyMap[variables.defaultStrategy]
			};
			if (local.defaultEntry.strategy.supports(arguments.request)) {
				ArrayAppend(local.result, local.defaultEntry);
			}
		}

		// Then try remaining strategies in registration order
		for (local.entry in variables.strategies) {
			// Skip the default (already tried)
			if (Len(variables.defaultStrategy) && local.entry.name == variables.defaultStrategy) {
				continue;
			}
			if (local.entry.strategy.supports(arguments.request)) {
				ArrayAppend(local.result, local.entry);
			}
		}

		return local.result;
	}

	/**
	 * Build a standard AuthResult struct.
	 *
	 * @success Whether authentication succeeded.
	 * @principal The authenticated identity (empty struct on failure).
	 * @strategy The name of the strategy that authenticated (empty on failure).
	 * @error Human-readable error message (empty on success).
	 * @statusCode HTTP status code: 200 success, 401 unauthenticated, 403 forbidden.
	 */
	private struct function $authResult(
		boolean success = false,
		struct principal = {},
		string strategy = "",
		string error = "",
		numeric statusCode = 401
	) {
		return {
			success = arguments.success,
			principal = arguments.principal,
			strategy = arguments.strategy,
			error = arguments.error,
			statusCode = arguments.statusCode
		};
	}

}
