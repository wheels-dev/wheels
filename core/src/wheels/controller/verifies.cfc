component {
	/**
	 * Instructs CFWheels to verify that some specific criteria are met before running an action.
	 * Note that all undeclared arguments will be passed to `redirectTo()` call if a `handler` is not specified.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @only List of action names to limit this verification to.
	 * @except List of action names to exclude this verification from.
	 * @post Set to true to verify that this is a `POST` request.
	 * @get Set to true to verify that this is a `GET` request.
	 * @ajax Set to true to verify that this is an `AJAX` request.
	 * @cookie Verify that the passed in variable name exists in the cookie scope.
	 * @session Verify that the passed in variable name exists in the session scope.
	 * @params Verify that the passed in variable name exists in the params struct.
	 * @handler Pass in the name of a function that should handle failed verifications. The default is to just abort the request when a verification fails.
	 * @cookieTypes List of types to check each listed cookie value against (will be passed through to your CFML engine's `IsValid` function).
	 * @sessionTypes List of types to check each list session value against (will be passed through to your CFML engine's `IsValid` function).
	 * @paramsTypes List of types to check each params value against (will be passed through to your CFML engine's `IsValid` function).
	 */
	public void function verifies(
		string only = "",
		string except = "",
		any post = "",
		any get = "",
		any ajax = "",
		string cookie = "",
		string session = "",
		string params = "",
		string handler,
		string cookieTypes = "",
		string sessionTypes = "",
		string paramsTypes = ""
	) {
		$args(name = "verifies", args = arguments);
		ArrayAppend(variables.$class.verifications, Duplicate(arguments));
	}

	/**
	 * Returns an array of all the verifications set on this controller in the order in which they will be executed.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 */
	public array function verificationChain() {
		return variables.$class.verifications;
	}

	/**
	 * Use this function if you need a more low level way of setting the entire verification chain for a controller.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @chain An array of structs, each of which represent an `argumentCollection` that get passed to the `verifies` function. This should represent the entire verification chain that you want to use for this controller.
	 */
	public void function setVerificationChain(required array chain) {
		// Clear current verification chain and then re-add from the passed in chain.
		variables.$class.verifications = [];
		local.iEnd = ArrayLen(arguments.chain);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			verifies(argumentCollection = arguments.chain[local.i]);
		}
	}

	/**
	 * Internal function.
	 */
	public void function $runVerifications(
		required string action,
		required struct params,
		struct cgiScope = request.cgi,
		struct sessionScope = {},
		struct cookieScope = cookie
	) {
		// Only access the session scope when session management is enabled in the app.
		// Default to the Wheels setting but get it on a per request basis if possible (from Application.cfc).
		local.sessionManagement = $get("sessionManagement");
		try {
			local.sessionManagement = GetApplicationMetadata().sessionManagement;
		} catch (any e) {
		}
		if (StructIsEmpty(arguments.sessionScope) && local.sessionManagement) {
			arguments.sessionScope = session;
		}

		local.verifications = verificationChain();
		local.$args = "only,except,post,get,ajax,cookie,session,params,cookieTypes,sessionTypes,paramsTypes,handler";
		local.abort = false;
		local.iEnd = ArrayLen(local.verifications);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.element = local.verifications[local.i];
			if (
				(!Len(local.element.only) && !Len(local.element.except)) || (
					Len(local.element.only) && ListFindNoCase(local.element.only, arguments.action)
				) || (Len(local.element.except) && !ListFindNoCase(local.element.except, arguments.action))
			) {
				if (IsBoolean(local.element.post) && ((local.element.post && !isPost()) || (!local.element.post && isPost()))) {
					local.abort = true;
				}
				if (IsBoolean(local.element.get) && ((local.element.get && !isGet()) || (!local.element.get && isGet()))) {
					local.abort = true;
				}
				if (IsBoolean(local.element.ajax) && ((local.element.ajax && !isAjax()) || (!local.element.ajax && isAjax()))) {
					local.abort = true;
				}
				if (!$checkVerificationsVars(arguments.params, local.element.params, local.element.paramsTypes)) {
					local.abort = true;
				}
				if (!$checkVerificationsVars(arguments.sessionScope, local.element.session, local.element.sessionTypes)) {
					local.abort = true;
				}
				if (!$checkVerificationsVars(arguments.cookieScope, local.element.cookie, local.element.cookieTypes)) {
					local.abort = true;
				}
			}
			if (local.abort) {
				if (Len(local.element.handler)) {
					// Invoke the specified handler function.
					// The assumption is that the developer aborts or redirects from within the handler function.
					// Processing will return if the developer forgot that or if they made a delayed redirect (e.g. when testing).
					// If a delayed redirect was not made we redirect to the previous page as a last resort to end processing.
					$invoke(method = local.element.handler);
					if (!$performedRedirect()) {
						redirectTo(back = "true");
					}
				} else {
					// Check to see if we should perform a redirect or abort completely.
					local.redirectArgs = {};
					for (local.key in local.element) {
						if (!ListFindNoCase(local.$args, local.key) && StructKeyExists(local.element, local.key)) {
							local.redirectArgs[local.key] = local.element[local.key];
						}
					}
					if (!StructIsEmpty(local.redirectArgs)) {
						redirectTo(argumentCollection = local.redirectArgs);
					} else {
						variables.$instance.abort = true;
					}
				}

				// An abort was issued, no need to process further in the chain.
				break;
			}
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $checkVerificationsVars(required struct scope, required string vars, required string types) {
		local.rv = true;
		local.iEnd = ListLen(arguments.vars);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.vars, local.i);
			if (!StructKeyExists(arguments.scope, local.item)) {
				local.rv = false;
				break;
			}
			if (Len(arguments.types)) {
				local.value = arguments.scope[local.item];
				local.typeCheck = ListGetAt(arguments.types, local.i);

				// By default string aren't allowed to be blank.
				local.typeAllowedBlank = false;
				if (local.typeCheck == "blank") {
					local.typeAllowedBlank = true;
					local.typeCheck = "string";
				}

				if (
					!IsValid(local.typeCheck, local.value) || (
						local.typeCheck == "string" && !local.typeAllowedBlank && !Len(Trim(local.value))
					)
				) {
					local.rv = false;
					break;
				}
			}
		}
		return local.rv;
	}
}
