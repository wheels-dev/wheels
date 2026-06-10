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
		// Guard against unbalanced end() calls: once the scope stack is empty there
		// is no open block left to close, so fail with a clear DSL error instead of
		// a raw array-index engine error.
		if (ArrayIsEmpty(variables.scopeStack)) {
			Throw(
				type = "Wheels.InvalidRoute",
				message = "Unbalanced `end()` call in the route configuration.",
				detail = "Each `end()` closes one block opened by `mapper()`, `scope()`, `namespace()`, `package()`, `group()`, `resource()`, or `resources()`. This `end()` has no matching open block, so remove the extra `end()`."
			);
		}

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
			$addMemberRoutes(local.formatPattern);
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
			$addMemberRoutes(local.formatPattern);
			end();
		}

		// Remove top of stack to end nesting.
		ArrayDeleteAt(variables.scopeStack, 1);

		return this;
	}

	/**
	 * Internal function.
	 * Generate the edit/show/update/delete member routes shared by both singular and plural resources.
	 */
	public void function $addMemberRoutes(required string formatPattern) {
		if (ListFind(variables.scopeStack[1].actions, "edit")) {
			get(pattern = "edit#arguments.formatPattern#", action = "edit", name = "edit");
		}
		if (ListFind(variables.scopeStack[1].actions, "show")) {
			get(pattern = arguments.formatPattern, action = "show");
		}
		if (ListFind(variables.scopeStack[1].actions, "update")) {
			patch(pattern = arguments.formatPattern, action = "update");
			put(pattern = arguments.formatPattern, action = "update");
		}
		if (ListFind(variables.scopeStack[1].actions, "delete")) {
			delete(pattern = arguments.formatPattern, action = "delete");
		}
	}
}
