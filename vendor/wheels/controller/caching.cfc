component {
	/**
	 * Tells Wheels to cache one or more actions.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @action Action(s) to cache. This argument is also aliased as `actions`.
	 * @time Minutes to cache the action(s) for.
	 * @static Set to `true` to tell Wheels that this is a static page and that it can skip running the controller filters (before and after filters set on actions). Please note that the `onSessionStart` and `onRequestStart` events still execute though.
	 * @appendToKey List of variables to be evaluated at runtime and included in the cache key so that content can be cached separately.
	 */
	public void function caches(string action = "", numeric time, boolean static, string appendToKey = "") {
		$args(args = arguments, name = "caches", combine = "action/actions");
		arguments.action = $listClean(arguments.action);

		if (!Len(arguments.action)) {
			Throw(type = "Wheels.InvalidArgument", message = "caches() requires one or more actions.");
		}

		local.actionsArray = ListToArray(arguments.action);
		local.iEnd = ArrayLen(local.actionsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.actionsArray[local.i];
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
		$dropCachedActionBodies(action = arguments.action);
		if (!Len(arguments.action)) {
			return $clearCachableActions();
		}

		local.filtered = [];
		for (local.i = 1; local.i <= ArrayLen(variables.$class.cachableActions); local.i++) {
			local.cachableAction = variables.$class.cachableActions[local.i];
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
		local.cachableActions = $cachableActions();
		local.iEnd = ArrayLen(local.cachableActions);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (
				CompareNoCase(local.cachableActions[local.i].action, arguments.action) == 0
				|| local.cachableActions[local.i].action == "*"
			) {
				local.rv = {};
				local.rv.time = local.cachableActions[local.i].time;
				local.rv.static = local.cachableActions[local.i].static;
				local.rv.appendToKey = StructKeyExists(local.cachableActions[local.i], "appendToKey")
					? local.cachableActions[local.i].appendToKey
					: "";
				return local.rv;
			}
		}
		return false;
	}

	/**
	 * Delete all cache info, only called from the test suite.
	 */
	public void function $clearCachableActions() {
		$dropCachedActionBodies();
		ArrayClear(variables.$class.cachableActions);
	}

	/**
	 * Drops this controller's action bodies from application.wheels.cache.
	 * Keys are recorded by $addToCache when category is action.
	 */
	public void function $dropCachedActionBodies(string action = "") {
		if (!StructKeyExists(application.wheels, "cacheActionIndex")) {
			return;
		}
		local.controllerName = variables.$class.name;
		if (!StructKeyExists(application.wheels.cacheActionIndex, local.controllerName)) {
			return;
		}
		local.byAction = application.wheels.cacheActionIndex[local.controllerName];
		if (!Len(arguments.action)) {
			for (local.indexedAction in local.byAction) {
				for (local.key in local.byAction[local.indexedAction]) {
					$removeFromCache(key = local.key, category = "action");
				}
			}
			StructDelete(application.wheels.cacheActionIndex, local.controllerName);
			return;
		}
		local.keep = {};
		for (local.indexedAction in local.byAction) {
			if (ListFindNoCase(arguments.action, local.indexedAction)) {
				for (local.key in local.byAction[local.indexedAction]) {
					$removeFromCache(key = local.key, category = "action");
				}
			} else {
				local.keep[local.indexedAction] = local.byAction[local.indexedAction];
			}
		}
		if (StructIsEmpty(local.keep)) {
			StructDelete(application.wheels.cacheActionIndex, local.controllerName);
		} else {
			application.wheels.cacheActionIndex[local.controllerName] = local.keep;
		}
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
