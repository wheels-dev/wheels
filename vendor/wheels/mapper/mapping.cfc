component {
	/**
	 * Internal function.
	 */
	public struct function $draw(
		boolean restful = true,
		boolean methods = arguments.restful,
		boolean mapFormat = variables.mapFormat
	) {
		variables.restful = arguments.restful;
		variables.methods = arguments.restful || arguments.methods;
		variables.mapFormat = arguments.mapFormat;

		// Start with clean scope stack that is locked for race conditions.
		$simpleLock(name = "mapper.reset", timeout = 5, type = "exclusive", execute = "$resetScopeStack");

		return this;
	}

	/**
	 * Call this to end a nested routing block or the entire route configuration. This method is chained on a sequence of routing mapper method calls started by `mapper()`.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 */
	public struct function end() {
		local.formatPattern = "";

		if (StructKeyExists(variables.scopeStack[1], "mapFormat") && variables.scopeStack[1].mapFormat) {
			local.formatPattern = "(.[format])";
		}

		// If last action was a plural resource, set up its RESTful routes.
		if (variables.scopeStack[1].$call == "resources") {
			collection();

			if (ListFind(variables.scopeStack[1].actions, "index")) {
				get(pattern = local.formatPattern, action = "index");
			}
			if (ListFindNoCase(variables.scopeStack[1].actions, "create")) {
				post(pattern = local.formatPattern, action = "create");
			}

			end();

			if (ListFindNoCase(variables.scopeStack[1].actions, "new")) {
				scope(path = variables.scopeStack[1].collectionPath, $call = "new");
				get(pattern = "new#local.formatPattern#", action = "new", name = "new");
				end();
			}

			member();

			if (ListFind(variables.scopeStack[1].actions, "edit")) {
				get(pattern = "edit#local.formatPattern#", action = "edit", name = "edit");
			}
			if (ListFind(variables.scopeStack[1].actions, "show")) {
				get(pattern = local.formatPattern, action = "show");
			}
			if (ListFind(variables.scopeStack[1].actions, "update")) {
				patch(pattern = local.formatPattern, action = "update");
				put(pattern = local.formatPattern, action = "update");
			}
			if (ListFind(variables.scopeStack[1].actions, "delete")) {
				delete(pattern = local.formatPattern, action = "delete");
			}

			end();
			// If last action was a singular resource, set up its RESTful routes.
		} else if (variables.scopeStack[1].$call == "resource") {
			if (ListFind(variables.scopeStack[1].actions, "create")) {
				collection();
				post(pattern = local.formatPattern, action = "create");
				end();
			}

			if (ListFind(variables.scopeStack[1].actions, "new")) {
				scope(path = variables.scopeStack[1].memberPath, $call = "new");
				get(pattern = "new#local.formatPattern#", action = "new", name = "new");
				end();
			}

			member();

			if (ListFind(variables.scopeStack[1].actions, "edit")) {
				get(pattern = "edit#local.formatPattern#", action = "edit", name = "edit");
			}
			if (ListFind(variables.scopeStack[1].actions, "show")) {
				get(pattern = local.formatPattern, action = "show");
			}
			if (ListFind(variables.scopeStack[1].actions, "update")) {
				patch(pattern = local.formatPattern, action = "update");
				put(pattern = local.formatPattern, action = "update");
			}
			if (ListFind(variables.scopeStack[1].actions, "delete")) {
				delete(pattern = local.formatPattern, action = "delete");
			}

			end();
		}

		// Remove top of stack to end nesting.
		ArrayDeleteAt(variables.scopeStack, 1);

		return this;
	}
}
