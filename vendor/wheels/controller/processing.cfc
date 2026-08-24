component {
	/**
	 * Process the specified action of the controller.
	 * This is exposed in the API primarily for testing purposes; you would not usually call it directly unless in the test suite.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 * @includeFilters Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. This argument is generally inherited from the `processRequest` function during unit test execution.
	 */
	public boolean function processAction(string includeFilters = true) {
		$runCsrfProtection(action = variables.params.action);

		// Check if action should be cached, and if so, cache statically or set the time to use later when caching just the action.
		local.cache = 0;
		if ($get("cacheActions") && $hasCachableActions() && flashIsEmpty() && StructIsEmpty(form)) {
			local.cachableActions = $cachableActions();
			for (local.action in local.cachableActions) {
				if (local.action.action == variables.params.action || local.action.action == "*") {
					if (local.action.static) {
						local.timeSpan = $timeSpanForCache(local.action.time);
						$cache(action = "serverCache", timeSpan = local.timeSpan, useQueryString = true);
						if (!$reCacheRequired()) {
							abort;
						}
					} else {
						local.cache = local.action.time;
						local.appendToKey = local.action.appendToKey;
					}
					break;
				}
			}
		}

		if ($get("showDebugInformation")) {
			$debugPoint("beforeFilters");
		}

		// Run verifications if they exist on the controller.
		$runVerifications(action = variables.params.action, params = variables.params);

		// Continue unless an abort is issued from a verification.
		if (!$abortIssued()) {
			// Run before filters if they exist on the controller.
			local.runAction = true;
			if (ListFindNoCase("true,before", arguments.includeFilters)) {
				local.runAction = $runFilters(type = "before", action = variables.params.action);
			}

			if ($get("showDebugInformation")) {
				$debugPoint("beforeFilters,action");
			}

			// Only proceed to call the action if a before filter has not
			// returned false and has not already rendered content.
			if (local.runAction && !$performedRenderOrRedirect()) {
				// Get content from the cache if it exists there and set it to the request scope. If not, the $callActionAndAddToCache function will run, calling the controller action (which in turn sets the content to the request scope).
				if (local.cache) {
					local.category = "action";

					// Create the key for the cache.
					local.key = $hashedKey(variables.$class.name, variables.params);

					// Evaluate variables and append to the cache key when specified.
					// Missing or unresolvable items throw; they are never omitted,
					// because a silent skip collapses distinct keys into one shared key.
					if (Len(local.appendToKey)) {
						local.scopeMap = {
							"request": request,
							"arguments": arguments,
							"application": application,
							"session": session,
							"variables": variables
						};
						local.key = $appendToCacheKey(
							key = local.key,
							appendToKey = local.appendToKey,
							scopeMap = local.scopeMap
						);
					}

					local.conditionArgs = {};
					local.conditionArgs.key = local.key;
					local.conditionArgs.category = local.category;
					local.executeArgs = {};
					local.executeArgs.controller = variables.params.controller;
					local.executeArgs.action = variables.params.action;
					local.executeArgs.key = local.key;
					local.executeArgs.time = local.cache;
					local.executeArgs.category = local.category;
					local.lockName = local.category & local.key & application.applicationName;
					variables.$instance.response = $doubleCheckedLock(
						name = local.lockName,
						condition = "$getFromCache",
						execute = "$callActionAndAddToCache",
						conditionArgs = local.conditionArgs,
						executeArgs = local.executeArgs
					);
				}

				// If we didn't render anything from a cached action, we call the action here.
				if (!$performedRender()) {
					$callAction(action = variables.params.action);
				}
			}

			// Run after filters with surrounding debug points. (Don't run the filters if a delayed redirect will occur though.)
			if ($get("showDebugInformation")) {
				$debugPoint("action,afterFilters");
			}

			if (local.runAction && !$performedRedirect() && ListFindNoCase("true,after", arguments.includeFilters)) {
				$runFilters(type = "after", action = variables.params.action);
			}

			if ($get("showDebugInformation")) {
				$debugPoint("afterFilters");
			}
		}

		return true;
	}

	/**
	 * Internal function.
	 */
	public void function $callAction(required string action) {
		if (Left(arguments.action, 1) == "$" || StructKeyExists(application.wheels.protectedControllerMethodsLookup, arguments.action)) {
			// A helper-named or $-prefixed action is treated exactly like a
			// missing action: it 404s (see #2845 and CLAUDE.md Anti-Pattern 8).
			// Route through $throwErrorOrShow404Page — mirroring RecordNotFound /
			// ViewNotFound — so the 404 status header is committed at the throw
			// site and production renders the 404 page instead of a generic 500
			// (#3075). In development the developer-facing Wheels.ActionNotAllowed
			// error is still thrown, and the widened EventMethods status map keeps
			// it at 404 rather than falling through to 500.
			$throwErrorOrShow404Page(
				type = "Wheels.ActionNotAllowed",
				message = "You are not allowed to execute the `#arguments.action#` method as an action.",
				extendedInfo = "Make sure your action does not have the same name as any of the built-in Wheels functions."
			);
		}
		try {
			if (StructKeyExists(this, arguments.action) && IsCustomFunction(this[arguments.action])) {
				$invoke(method = arguments.action);
			} else if (StructKeyExists(this, "onMissingMethod")) {
				local.invokeArgs = {};
				local.invokeArgs.missingMethodName = arguments.action;
				local.invokeArgs.missingMethodArguments = {};
				$invoke(method = "onMissingMethod", invokeArgs = local.invokeArgs);
			}
		} catch (any e) {
			// Re-throw the original error instead of falling through to the
			// auto-render block, which would produce a misleading ViewNotFound.
			Throw(object = e);
		}
		if (!$performedRenderOrRedirect() && !$renderWithAttempted()) {
			// Check if we should skip automatic view rendering
			local.contentType = $requestContentType();
			local.acceptableFormats = $acceptableFormats(action = arguments.action);
			
			// Only attempt to render a view if:
			// 1. The content type is html OR
			// 2. The content type is in the acceptable formats AND a format-specific template exists
			local.shouldRenderView = true;
			
			if (local.contentType != "html") {
				// For non-HTML formats, check if we should skip view rendering
				if (!ListFindNoCase(local.acceptableFormats, local.contentType)) {
					// Format not acceptable for this action
					local.shouldRenderView = false;
				} else if (ListFindNoCase("json,xml", local.contentType)) {
					// JSON and XML can be auto-generated, so check if a template exists
					local.templateName = $generateRenderWithTemplatePath(
						controller = variables.params.controller,
						action = arguments.action,
						template = "",
						contentType = local.contentType
					);
					if (!$formatTemplatePathExists($name = local.templateName)) {
						// No template exists and these formats can be auto-generated
						local.shouldRenderView = false;
					}
				}
			}
			
			if (local.shouldRenderView) {
				try {
					renderView();
				} catch (any e) {
					local.file = $get("viewPath")
					& "/"
					& LCase(ListChangeDelims(variables.$class.name, '/', '.'))
					& "/"
					& LCase(arguments.action)
					& ".cfm";
					if (FileExists(ExpandPath(local.file))) {
						Throw(object = e);
					} else {
						// For non-HTML formats, provide a more helpful error message
						if (local.contentType != "html") {
							$throwErrorOrShow404Page(
								type = "Wheels.ViewNotFound",
								message = "No content was rendered for the `#arguments.action#` action in the `#variables.$class.name#` controller.",
								extendedInfo = "For content type `#local.contentType#`, either: 1) Call a render function (renderText, renderWith, etc.) in your action, 2) Create a view template named `#LCase(arguments.action)#.#local.contentType#.cfm`, or 3) Use onlyProvides() to restrict acceptable formats."
							);
						} else {
							$throwErrorOrShow404Page(
								type = "Wheels.ViewNotFound",
								message = "Could not find the view page for the `#arguments.action#` action in the `#variables.$class.name#` controller.",
								extendedInfo = "Create a file named `#LCase(arguments.action)#.cfm` in the `app/views/#LCase(ListChangeDelims(variables.$class.name, '/', '.'))#` directory (create the directory as well if it doesn't already exist)."
							);
						}
					}
				}
			}
		}
	}

	/**
	 * Internal function.
	 */
	public string function $callActionAndAddToCache(
		required string action,
		required numeric time,
		required string key,
		required string category
	) {
		$callAction(action = arguments.action);
		$addToCache(
			key = arguments.key,
			value = variables.$instance.response,
			time = arguments.time,
			category = arguments.category
		);
		return response();
	}

	/**
	 * Internal function. Appends resolved appendToKey segments onto an action cache key.
	 * Every listed item must resolve; silent omission would share one key across users.
	 */
	public string function $appendToCacheKey(required string key, required string appendToKey, required struct scopeMap) {
		local.rv = arguments.key;
		local.items = ListToArray(arguments.appendToKey);
		local.iEnd = ArrayLen(local.items);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv &= $resolveAppendToKeyValue(item = local.items[local.i], scopeMap = arguments.scopeMap);
		}
		return local.rv;
	}

	/**
	 * Internal function. Walks a dotted appendToKey path (scope.a.b.c) and returns
	 * the simple value. Throws Wheels.KeyNotFound when any segment is missing.
	 */
	public string function $resolveAppendToKeyValue(required string item, required struct scopeMap) {
		local.segments = ListToArray(arguments.item, ".");
		if (ArrayLen(local.segments) < 2) {
			Throw(type = "Wheels.KeyNotFound", message = "The `#arguments.item#` argument was not found.");
		}
		local.scopeName = local.segments[1];
		if (!StructKeyExists(arguments.scopeMap, local.scopeName)) {
			Throw(type = "Wheels.KeyNotFound", message = "The `#arguments.item#` argument was not found.");
		}
		local.cursor = arguments.scopeMap[local.scopeName];
		local.iEnd = ArrayLen(local.segments);
		for (local.i = 2; local.i <= local.iEnd; local.i++) {
			local.segment = local.segments[local.i];
			if (!IsStruct(local.cursor) || !StructKeyExists(local.cursor, local.segment)) {
				Throw(type = "Wheels.KeyNotFound", message = "The `#arguments.item#` argument was not found.");
			}
			local.cursor = local.cursor[local.segment];
		}
		if (IsNull(local.cursor) || !IsSimpleValue(local.cursor)) {
			Throw(type = "Wheels.KeyNotFound", message = "The `#arguments.item#` argument was not found.");
		}
		return ToString(local.cursor);
	}
}
