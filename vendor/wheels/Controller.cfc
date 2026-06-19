component output="false" displayName="Controller" extends="wheels.Global"{

	function init(){
		$integrateComponents("wheels.controller");
		$integrateComponents("wheels.view");
		return this;
	}

	/**
	 * If the controller file exists we instantiate it, otherwise we instantiate the parent controller.
	 * This is done so that an action's view page can be rendered without having an actual controller file for it.
	 */
	public any function $createControllerObject(required struct params) {
		local.controllerName = $objectFileName(
			name = variables.$class.name,
			objectPath = variables.$class.path,
			type = "controller"
		);
		return $createObjectFromRoot(
			path = variables.$class.path,
			fileName = local.controllerName,
			method = "$initControllerObject",
			name = variables.$class.name,
			params = arguments.params
		);
	}

	/**
	 * Return the controller data that is on the class level.
	 */
	public struct function $getControllerClassData() {
		return variables.$class;
	}

	/**
	 * Initialize the controller class level object and return it.
	 */
	public any function $initControllerClass(string name = "") {
		variables.$class.name = arguments.name;
		variables.$class.path = arguments.path;
		variables.$class.verifications = [];
		variables.$class.filters = [];
		variables.$class.cachableActions = [];
		variables.$class.layouts = [];

		// Setup format info for providing content.
		// Default the controller to only respond to HTML.
		variables.$class.formats = {};
		variables.$class.formats.default = "html";
		variables.$class.formats.actions = {};
		variables.$class.formats.templateCache = {};

		// Storage for declared service injections (populated by inject() in config)
		variables.$class.services = [];

		$setFlashStorage($get("flashStorage"));
		$setFlashAppend($get("flashAppend"));

		// Call the developer's "config" function if it exists.
		if (StructKeyExists(variables, "config")) {
			config();
			$warnIfConfigSkipsSuper();
		}

		return this;
	}

	/**
	 * Initialize the controller instance level object and return it.
	 */
	public any function $initControllerObject(required string name, required struct params) {
		// Create a struct for storing request specific data.
		variables.$instance = {};
		variables.$instance.contentFor = {};

		// Set file name to look for (e.g. "app/views/folder/helpers.cfm").
		// Name could be dot notation so we need to change delimiters.
		local.template = $get("viewPath") & "/" & LCase(ListChangeDelims(arguments.name, '/', '.')) & "/helpers.cfm";

		// Check if the file exists on the file system if we have not already checked in a previous request.
		// When the controller is not present in the cache we know that we have not yet checked for it.
		local.helperFileExists = false;
		if (!StructKeyExists(application.wheels.helperFileCache, arguments.name)) {
			if (FileExists(ExpandPath(local.template))) {
				local.helperFileExists = true;
			}
			if ($get("cacheFileChecking")) {
				application.wheels.helperFileCache[arguments.name] = local.helperFileExists;
			}
		}

		// Include controller specific helper file if it exists.
		if (
			Len(arguments.name)
			&& (
				local.helperFileExists
				|| (
					StructKeyExists(application.wheels.helperFileCache, arguments.name)
					&& application.wheels.helperFileCache[arguments.name]
				)
			)
		) {
			$include(template = local.template);
		}

		local.executeArgs = {};
		local.executeArgs.name = arguments.name;
		local.lockName = "controllerLock" & application.applicationName;
		$simpleLock(
			name = local.lockName,
			type = "readonly",
			execute = "$setControllerClassData",
			executeArgs = local.executeArgs
		);
		variables.params = arguments.params;

		// Resolve any services declared via inject() in config()
		$resolveInjectedServices();

		return this;
	}

	/**
	 * Get the class level data from the controller object in the application scope and set it to this controller.
	 * By class level we mean that it's stored in the controller object in the application scope.
	 */
	public void function $setControllerClassData() {
		variables.$class = application.wheels.controllers[arguments.name].$getControllerClassData();
	}

	/**
	 * Internal function. Called once per controller class at init time (after the
	 * developer's config() has run). In the development environment it registers a
	 * warning when the controller overrides config() without calling super.config(),
	 * which silently drops the parent controller's setup: protectsFromForgery() CSRF
	 * protection, filters, verifies, injected services, etc. The warning is surfaced
	 * in the debug bar and the standard wheels log. Best-effort by design (mirrors
	 * $deprecated() in Global.cfc): any failure here must never break controller
	 * initialization.
	 */
	public void function $warnIfConfigSkipsSuper() {
		try {
			if ($get("environment") != "development") {
				return;
			}
			if (!$configOverrideSkipsSuper()) {
				return;
			}
			local.appKey = $appKey();
			if (!StructKeyExists(application, local.appKey)) {
				return;
			}
			local.message = "Controller '#variables.$class.name#' overrides config() without calling super.config(). Setup in its parent controller's config() (including protectsFromForgery() CSRF protection, filters, and verifies) will not run for this controller. Add super.config() as the first line of its config().";
			// One app-wide lock serializes the lazy creation of the registry array and
			// the dedup check / registration (mirrors $deprecated() in Global.cfc).
			lock name="wheels_config_warning_registry" type="exclusive" timeout="5" {
				if (!StructKeyExists(application[local.appKey], "controllerConfigWarnings")) {
					application[local.appKey].controllerConfigWarnings = [];
				}
				for (local.existing in application[local.appKey].controllerConfigWarnings) {
					if (local.existing.controller == variables.$class.name) {
						return;
					}
				}
				ArrayAppend(
					application[local.appKey].controllerConfigWarnings,
					{controller = variables.$class.name, message = local.message}
				);
				// Log if-and-only-if the registration above just succeeded; the registry
				// enforces the warn-once policy for the log too.
				try {
					WriteLog(type = "warning", text = "[Wheels] " & local.message, file = "wheels");
				} catch (any e) {
					// Logging is best-effort; the registry entry above already records the warning.
				}
			}
		} catch (any e) {
			// Best-effort by design (including lock timeouts); never let this advisory
			// break controller initialization.
		}
	}

	/**
	 * Internal function. Returns true when this controller class overrides config()
	 * (shadowing a config() declared by an ancestor below wheels.Controller) without
	 * its source calling super.config(). Pure detection; returns false whenever the
	 * situation cannot be verified (never warn on uncertainty).
	 */
	public boolean function $configOverrideSkipsSuper() {
		// Walk the inheritance chain from the leaf up to (but excluding) the
		// framework's wheels.Controller, collecting each component's metadata node.
		// The boundary match is belt-and-braces: no framework ancestor declares a
		// config() function, so walking past a differently-named boundary is benign.
		local.nodes = [];
		local.node = GetMetaData(this);
		while (IsStruct(local.node)) {
			if (
				StructKeyExists(local.node, "name")
				&& ReFindNoCase("(^|\.)wheels\.Controller$", local.node.name)
			) {
				break;
			}
			ArrayAppend(local.nodes, local.node);
			if (!StructKeyExists(local.node, "extends")) {
				break;
			}
			local.node = local.node.extends;
		}

		// Find the leaf-most node that declares config(): that is the implementation
		// that actually executed at class init.
		local.declarerIndex = 0;
		local.iEnd = ArrayLen(local.nodes);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if ($nodeDeclaresConfig(local.nodes[local.i])) {
				local.declarerIndex = local.i;
				break;
			}
		}

		// No user-level config() declared anywhere (e.g. mixin-injected): nothing to check.
		if (local.declarerIndex == 0) {
			return false;
		}

		// Unless an ancestor of the declarer also declares config(), nothing was
		// shadowed (the base-controller case: its config() simply has no parent
		// config() to call up to).
		local.shadowed = false;
		for (local.i = local.declarerIndex + 1; local.i <= local.iEnd; local.i++) {
			if ($nodeDeclaresConfig(local.nodes[local.i])) {
				local.shadowed = true;
				break;
			}
		}
		if (!local.shadowed) {
			return false;
		}

		// Cannot verify the source: never warn on uncertainty.
		local.declarer = local.nodes[local.declarerIndex];
		if (!StructKeyExists(local.declarer, "path") || !FileExists(local.declarer.path)) {
			return false;
		}
		return !$sourceCallsSuperConfig(local.declarer.path);
	}

	/**
	 * Internal function. Returns true when the given component metadata node declares
	 * its own (non-inherited) config() function.
	 */
	public boolean function $nodeDeclaresConfig(required struct node) {
		if (StructKeyExists(arguments.node, "functions") && IsArray(arguments.node.functions)) {
			local.iEnd = ArrayLen(arguments.node.functions);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (
					StructKeyExists(arguments.node.functions[local.i], "name")
					&& arguments.node.functions[local.i].name == "config"
				) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Internal function. Comment-aware scan of a component source file for a
	 * super.config() call. Strips line comments, block comments, and tag comments
	 * line by line before matching, so a commented-out super.config() is correctly
	 * reported as not calling it.
	 *
	 * Known accepted limitation: a literal comment-opener sequence inside a quoted
	 * string before a same-line super.config() call strips the call from view and
	 * yields a false positive warning. The commented-out super.config() case (the
	 * realistic footgun) is detected correctly.
	 *
	 * NOTE: deliberately a line-by-line scanner. A global non-greedy regex comment
	 * stripper is known to hang Lucee 7 on large files.
	 */
	public boolean function $sourceCallsSuperConfig(required string filePath) {
		// Build the tag-comment markers without a literal angle bracket so engine
		// tag scanners never mistake this source file for containing an unclosed tag.
		local.tagOpen = Chr(60) & "!---";
		local.tagClose = "---" & Chr(62);
		local.lines = ListToArray(FileRead(arguments.filePath), Chr(10), false);
		local.inBlock = false;
		local.blockCloser = "";
		local.iEnd = ArrayLen(local.lines);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.remaining = local.lines[local.i];
			local.code = "";
			// Bounded loop: every iteration consumes at least one comment marker.
			local.guard = 0;
			while (Len(local.remaining) && local.guard < 1000) {
				local.guard++;
				if (local.inBlock) {
					local.closePos = Find(local.blockCloser, local.remaining);
					if (local.closePos == 0) {
						// Comment continues on the next line.
						local.remaining = "";
					} else {
						local.remaining = Mid(
							local.remaining,
							local.closePos + Len(local.blockCloser),
							Len(local.remaining)
						);
						local.inBlock = false;
					}
				} else {
					// Earliest comment opener wins; 0 means not present on this line.
					local.linePos = Find("//", local.remaining);
					local.blockPos = Find("/*", local.remaining);
					local.tagPos = Find(local.tagOpen, local.remaining);
					local.firstPos = 0;
					local.marker = "";
					if (local.linePos > 0) {
						local.firstPos = local.linePos;
						local.marker = "line";
					}
					if (local.blockPos > 0 && (local.firstPos == 0 || local.blockPos < local.firstPos)) {
						local.firstPos = local.blockPos;
						local.marker = "block";
					}
					if (local.tagPos > 0 && (local.firstPos == 0 || local.tagPos < local.firstPos)) {
						local.firstPos = local.tagPos;
						local.marker = "tag";
					}
					if (local.firstPos == 0) {
						local.code &= local.remaining;
						local.remaining = "";
					} else {
						if (local.firstPos > 1) {
							local.code &= Left(local.remaining, local.firstPos - 1);
						}
						if (local.marker == "line") {
							// The rest of the line is a comment.
							local.remaining = "";
						} else {
							local.inBlock = true;
							if (local.marker == "block") {
								local.blockCloser = "*/";
								local.openerLen = 2;
							} else {
								local.blockCloser = local.tagClose;
								local.openerLen = Len(local.tagOpen);
							}
							local.remaining = Mid(
								local.remaining,
								local.firstPos + local.openerLen,
								Len(local.remaining)
							);
						}
					}
				}
			}
			if (ReFindNoCase("super\s*\.\s*config\s*\(", local.code)) {
				return true;
			}
		}
		return false;
	}

	if (
		IsDefined("application")
		&& StructKeyExists(application, "wheels")
		&& StructKeyExists(application.wheels, "viewPath")
	) {
		include "#application.wheels.viewPath#/helpers.cfm";
	}

	/**
	 * Gets all the component files from the provided path
	 *
	 * @path The path to get component files from
	 */
	private function $integrateComponents(required string path) {
		local.basePath = arguments.path;
		local.folderPath = expandPath("/#replace(local.basePath, ".", "/", "all")#");

		// Get a list of all CFC files in the folder
		local.fileList = directoryList(local.folderPath, false, "name", "*.cfc");
		for (local.fileName in local.fileList) {
			// Remove the file extension to get the component name
			local.componentName = replace(local.fileName, ".cfc", "", "all");

			$integrateFunctions(createObject("component", "#local.basePath#.#local.componentName#"));
		}
	}

	/**
	 * Dynamically mix methods from a given component into this component
	 */
	private function $integrateFunctions(componentInstance) {
		// Get all methods from the given component
		local.methods = getMetaData(componentInstance).functions;

		for (local.method in local.methods) {
			local.functionName = local.method.name;

			// Only add public, non-inherited methods
			if (local.method.access eq "public") {
				local.methodExists = structKeyExists(variables, local.method.name) || structKeyExists(this, local.method.name);
				
				if (!local.methodExists) {
					variables[local.functionName] = componentInstance[local.functionName];
					this[local.functionName] = componentInstance[local.functionName];
				}
				
				// Only add super prefix for functions that will be overridden by plugins/mixins
				if ($willBeOverriddenByMixin(local.functionName)) {
					local.superMethodName = "super" & local.functionName;
					variables[local.superMethodName] = componentInstance[local.functionName];
					this[local.superMethodName] = componentInstance[local.functionName];
				}
				
			}
		}
	}

	/**
	 * Check if a function will be overridden by a plugin/mixin
	 */
	private boolean function $willBeOverriddenByMixin(required string functionName) {
		// Check if application and mixins are available
		if (!IsDefined("application") || !StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "mixins")) {
			return false;
		}
		
		// Check for both "controller" and "global" mixins
		local.componentTypes = ["controller", "global"];
		
		for (local.componentType in local.componentTypes) {
			if (StructKeyExists(application.wheels.mixins, local.componentType) && 
				StructKeyExists(application.wheels.mixins[local.componentType], arguments.functionName)) {
				return true;
			}
		}
		
		return false;
	}

	function onDIcomplete(){
		$engineAdapter().prepareDIComplete(variables, this);
		// Shared application-cached instance — constructing wheels.Plugins here
		// paid the full Global pseudo-constructor on every request (issue 2897).
		$pluginObj().$initializeMixins(variables);
	}
}
