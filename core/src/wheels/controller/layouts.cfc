component {
	/**
	 * Used within a controller's `config()` function to specify controller- or action-specific layouts.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @template Name of the layout template or function name you want to use.
	 * @ajax Name of the layout template you want to use for AJAX requests.
	 * @except List of actions that should not get the layout.
	 * @only List of actions that should only get the layout.
	 * @useDefault When specifying conditions or a function, pass in `true` to use the default `layout.cfm` if none of the conditions are met.
	 */
	public void function usesLayout(
		required string template,
		string ajax = "",
		string except,
		string only,
		boolean useDefault = true
	) {
		// Exit the function if we're on an internal CFWheels page (we don't want to allow overriding the layout there).
		if (variables.$class.name == "Wheels") {
			return;
		}

		// If the layout is a function, the function itself should handle all the logic.
		if (
			(StructKeyExists(this, arguments.template) && IsCustomFunction(this[arguments.template]))
			|| IsCustomFunction(arguments.template)
		) {
			StructDelete(arguments, "except");
			StructDelete(arguments, "only");
		}

		if (StructKeyExists(arguments, "except")) {
			arguments.except = $listClean(arguments.except);
		}
		if (StructKeyExists(arguments, "only")) {
			arguments.only = $listClean(arguments.only);
		}

		// Check to see if the layout struct is already present in the array
		local.layoutInArray = false;
		if (ArrayLen(variables.$class.layouts)) {
			for (local.i = 1; local.i <= ArrayLen(variables.$class.layouts); local.i++) {
				local.layout = variables.$class.layouts[local.i];
				if (StructCount(local.layout) eq StructCount(arguments)) {
					local.oneKeyIsDifferent = false;
					for (local.key in arguments) {
						if (local.layout[local.key] neq arguments[key]) {
							local.oneKeyIsDifferent = true;
						}
					}
					if (!local.oneKeyIsDifferent) {
						local.layoutInArray = true;
						local.layoutPostionInArray = local.i;
					}
				}
			}
		}

		variables.$class.layouts.append(arguments);

		// If this layout was is in the array, we need to delete it to respect the order of declaration
		if (local.layoutInArray) {
			ArrayDeleteAt(variables.$class.layouts, local.layoutPostionInArray);
		}
	}

	/**
	 * Internal function.
	 */
	public any function $useLayout(required string $action) {
		local.rv = true;
		local.layoutType = "template";

		for (local.layout in variables.$class.layouts) {
			local.rv = local.layout.useDefault;

			if (
				(!StructKeyExists(local.layout, "except") || !ListFindNoCase(local.layout.except, arguments.$action))
				&& (!StructKeyExists(local.layout, "only") || ListFindNoCase(local.layout.only, arguments.$action))
			) {
				if (isAjax() && StructKeyExists(local.layout, "ajax") && Len(local.layout.ajax)) {
					local.layoutType = "ajax";
				}
				if (
					(
						StructKeyExists(this, local.layout[local.layoutType])
						&& IsCustomFunction(this[local.layout[local.layoutType]])
					)
					|| IsCustomFunction(local.layout[local.layoutType])
				) {
					local.invokeArgs = {};
					local.invokeArgs.action = arguments.$action;
					local.result = $invoke(method = local.layout[local.layoutType], invokeArgs = local.invokeArgs);

					// If the developer doesn't return anything from the function or if they return a blank string it should use the default layout still.
					if (StructKeyExists(local, "result")) {
						local.rv = local.result;
					}
				} else {
					local.rv = local.layout[local.layoutType];
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $renderLayout(required string $content, required $layout) {
		if (
			(IsBoolean(arguments.$layout) && arguments.$layout)
			|| (!IsBoolean(arguments.$layout) && Len(arguments.$layout))
		) {
			// Store the content in a variable in the request scope so it can be accessed by the includeContent function that the developer uses in layout files.
			// This is done so we avoid passing data to/from it since it would complicate things for the developer.
			contentFor(body = arguments.$content, overwrite = true);

			local.viewPath = $get("viewPath");
			local.include = local.viewPath;
			if (IsBoolean(arguments.$layout)) {
				local.layoutFileExists = false;
				if (
					!ListFindNoCase(application.wheels.existingLayoutFiles, variables.params.controller)
					&& !ListFindNoCase(application.wheels.nonExistingLayoutFiles, variables.params.controller)
				) {
					local.file = local.viewPath & "/" & LCase(variables.params.controller) & "/layout.cfm";
					if (FileExists(ExpandPath(local.file))) {
						local.layoutFileExists = true;
					}
					if ($get("cacheFileChecking")) {
						if (local.layoutFileExists) {
							application.wheels.existingLayoutFiles = ListAppend(
								application.wheels.existingLayoutFiles,
								variables.params.controller
							);
						} else {
							application.wheels.nonExistingLayoutFiles = ListAppend(
								application.wheels.nonExistingLayoutFiles,
								variables.params.controller
							);
						}
					}
				}
				if (
					ListFindNoCase(application.wheels.existingLayoutFiles, variables.params.controller)
					|| local.layoutFileExists
				) {
					local.include &= "/" & variables.params.controller & "/" & "layout.cfm";
				} else {
					local.include &= "/" & "layout.cfm";
				}
				local.rv = $includeAndReturnOutput($template = local.include);
			} else {
				arguments.$name = arguments.$layout;
				arguments.$template = $generateIncludeTemplatePath(argumentCollection = arguments);
				local.rv = $includeFile(argumentCollection = arguments);
			}
		} else {
			local.rv = arguments.$content;
		}
		return local.rv;
	}
}
