component {
	/**
	 * Tells CFWheels to cache one or more actions.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @action Action(s) to cache. This argument is also aliased as `actions`.
	 * @time Minutes to cache the action(s) for.
	 * @static Set to `true` to tell CFWheels that this is a static page and that it can skip running the controller filters (before and after filters set on actions). Please note that the `onSessionStart` and `onRequestStart` events still execute though.
	 * @appendToKey List of variables to be evaluated at runtime and included in the cache key so that content can be cached separately.
	 */
	public void function caches(string action = "", numeric time, boolean static, string appendToKey = "") {
		$args(args = arguments, name = "caches", combine = "action/actions");
		arguments.action = $listClean(arguments.action);

		// When no actions are passed in we assume that all actions should be cacheable and indicate this with a *.
		if (!Len(arguments.action)) {
			arguments.action = "*";
		}

		local.iEnd = ListLen(arguments.action);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.action, local.i);
			local.action = {
				action = local.item,
				time = arguments.time,
				static = arguments.static,
				appendToKey = arguments.appendToKey
			};
			$addCachableAction(local.action);
		}
	}

	/**
	 * Clears cached action metadata for current controller.
	 * 
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @action Optional. A single action or list of actions to clear. If not provided, clears all cached actions of current controller.
	 */
	public void function clearCachableActions(string action = "") {
		if (!Len(arguments.action)) {
			return $clearCachableActions();
		}

		// Only remove specific actions from the cache list
		local.filtered = [];
		for (local.i = 1; local.i <= ArrayLen(variables.$class.cachableActions); local.i++) {
			local.cachableAction = variables.$class.cachableActions[i];
			if (!ListFindNoCase(arguments.action, local.cachableAction.action)) {
				ArrayAppend(local.filtered, local.cachableAction);
			}
		}
		variables.$class.cachableActions = local.filtered;
	}

	/**
	 * Called from the caches function.
	 */
	public void function $addCachableAction(required struct action) {
		ArrayAppend(variables.$class.cachableActions, arguments.action);
	}

	/**
	 * Called when processing a request, and from other functions in this file, to get all cacheable actions.
	 */
	public array function $cachableActions() {
		return variables.$class.cachableActions;
	}

	/**
	 * Get cache info, only called from the test suite
	 */
	public any function $cacheSettingsForAction(required string action) {
		local.rv = false;
		local.cachableActions = $cachableActions();
		local.iEnd = ArrayLen(local.cachableActions);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (local.cachableActions[local.i].action == arguments.action || local.cachableActions[local.i].action == "*") {
				local.rv = {};
				local.rv.time = local.cachableActions[local.i].time;
				local.rv.static = local.cachableActions[local.i].static;
			}
		}
		return local.rv;
	}

	/**
	 * Delete all cache info, only called from the test suite.
	 */
	public void function $clearCachableActions() {
		ArrayClear(variables.$class.cachableActions);
	}

	/**
	 * Called when processing a request to see if any actions are cacheable.
	 */
	public boolean function $hasCachableActions() {
		if (ArrayIsEmpty($cachableActions())) {
			return false;
		} else {
			return true;
		}
	}

	/**
	 * Set cache info, only called from the test suite.
	 */
	public void function $setCachableActions(required array actions) {
		variables.$class.cachableActions = arguments.actions;
	}
}
