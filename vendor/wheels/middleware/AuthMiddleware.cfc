/**
 * Authentication middleware that integrates with the Authenticator strategy registry.
 * Authenticates incoming requests before they reach the controller, attaching the
 * authenticated principal to the request context on success or short-circuiting
 * with an error response on failure.
 *
 * Can be applied globally or per-route via the scope middleware DSL:
 *
 *   // Global — authenticate all requests
 *   set(middleware = [new wheels.middleware.AuthMiddleware(authenticator)])
 *
 *   // Route-scoped — restrict to specific strategies
 *   .scope(path="/api", middleware=[
 *       new wheels.middleware.AuthMiddleware(strategies="token,jwt")
 *   ])
 *       .resources("users")
 *   .end()
 *
 * On success, `request.auth` is populated with:
 *   - success (boolean): true
 *   - principal (struct): the authenticated identity
 *   - strategy (string): the strategy name that authenticated
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	/**
	 * Creates the AuthMiddleware with configurable options.
	 *
	 * @authenticator An Authenticator instance. If not provided, resolves from
	 *                application.$wheels.authenticator or application.wheels.authenticator at request time.
	 * @strategies Comma-delimited list or array of strategy names to restrict authentication to.
	 *             If empty, all registered strategies are tried. Useful for per-route strategy selection.
	 * @onFailure Optional callback invoked on authentication failure. Receives (request, authResult)
	 *            and must return a response string. If not provided, returns a JSON error with the
	 *            appropriate HTTP status code.
	 * @allowAnonymous When true, failed authentication does not short-circuit the pipeline.
	 *                 Instead, request.auth is set to the failure result and the next middleware runs.
	 *                 Useful for routes that behave differently for authenticated vs anonymous users.
	 */
	public AuthMiddleware function init(
		any authenticator = "",
		any strategies = "",
		any onFailure = "",
		boolean allowAnonymous = false
	) {
		variables.authenticator = arguments.authenticator;
		variables.allowAnonymous = arguments.allowAnonymous;
		variables.onFailure = arguments.onFailure;

		// Normalize strategies to an array
		if (IsArray(arguments.strategies)) {
			variables.strategies = arguments.strategies;
		} else if (IsSimpleValue(arguments.strategies) && Len(arguments.strategies)) {
			variables.strategies = ListToArray(arguments.strategies);
		} else {
			variables.strategies = [];
		}

		return this;
	}

	/**
	 * Authenticate the request. On success, attach auth context and proceed.
	 * On failure, short-circuit with an error response (or proceed if allowAnonymous).
	 */
	public string function handle(required struct request, required any next) {
		local.auth = $resolveAuthenticator();

		// Authenticate — restricted to specific strategies or all
		if (ArrayLen(variables.strategies)) {
			local.result = $authenticateWithStrategies(local.auth, arguments.request);
		} else {
			local.result = local.auth.authenticate(arguments.request);
		}

		// Attach auth result to the request context
		arguments.request.auth = local.result;

		if (local.result.success) {
			return arguments.next(arguments.request);
		}

		// Authentication failed
		if (variables.allowAnonymous) {
			return arguments.next(arguments.request);
		}

		// Custom failure handler
		if (IsCustomFunction(variables.onFailure) || IsClosure(variables.onFailure)) {
			return variables.onFailure(arguments.request, local.result);
		}

		// Default: set HTTP status and return JSON error
		return $defaultFailureResponse(local.result);
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Resolve the Authenticator instance. Checks (in order):
	 * 1. Instance passed to init()
	 * 2. application.$wheels.authenticator
	 * 3. application.wheels.authenticator
	 */
	private any function $resolveAuthenticator() {
		// Passed directly at construction
		if (IsObject(variables.authenticator)) {
			return variables.authenticator;
		}

		// Resolve from application scope ($wheels takes precedence)
		if (StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "authenticator")) {
			return application.$wheels.authenticator;
		}

		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "authenticator")) {
			return application.wheels.authenticator;
		}

		throw(
			type = "Wheels.Auth.NoAuthenticator",
			message = "AuthMiddleware could not resolve an Authenticator. Pass one to init() or register one in application.$wheels.authenticator."
		);
	}

	/**
	 * Authenticate using only the specified strategies from the registry.
	 * Strategies are tried in the order listed in the strategies array.
	 */
	private struct function $authenticateWithStrategies(required any auth, required struct request) {
		local.lastError = "";
		local.lastStatusCode = 401;

		for (local.strategyName in variables.strategies) {
			if (!arguments.auth.hasStrategy(local.strategyName)) {
				continue;
			}

			local.strategy = arguments.auth.getStrategy(local.strategyName);

			if (!local.strategy.supports(arguments.request)) {
				continue;
			}

			local.result = local.strategy.authenticate(arguments.request);

			if (local.result.success) {
				// Stamp strategy name if not already set
				if (!Len(local.result.strategy)) {
					local.result.strategy = local.strategyName;
				}
				return local.result;
			}

			local.lastError = local.result.error;
			local.lastStatusCode = local.result.statusCode;
		}

		// All specified strategies failed or were not found
		if (!Len(local.lastError)) {
			local.lastError = "No authentication strategy supports this request";
		}

		return {
			success = false,
			principal = {},
			strategy = "",
			error = local.lastError,
			statusCode = local.lastStatusCode
		};
	}

	/**
	 * Produce the default JSON error response and set the HTTP status code.
	 */
	private string function $defaultFailureResponse(required struct authResult) {
		try {
			cfheader(statuscode = arguments.authResult.statusCode, statustext = $statusText(arguments.authResult.statusCode));
			cfheader(name = "Content-Type", value = "application/json");
		} catch (any e) {
			// cfheader may not be available in test context
		}

		return SerializeJSON({
			error = arguments.authResult.error,
			status = arguments.authResult.statusCode
		});
	}

	/**
	 * Map status codes to text for the cfheader call.
	 */
	private string function $statusText(required numeric code) {
		switch (arguments.code) {
			case 401: return "Unauthorized";
			case 403: return "Forbidden";
			default: return "Error";
		}
	}

}
