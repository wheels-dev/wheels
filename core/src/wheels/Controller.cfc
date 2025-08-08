component output="false" displayName="Controller" extends="wheels.Global"{

	property name="Mixins" inject="id:Plugins";

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
		variables.$class.formats.existingTemplates = "";
		variables.$class.formats.nonExistingTemplates = "";

		$setFlashStorage($get("flashStorage"));
		$setFlashAppend($get("flashAppend"));

		// Call the developer's "config" function if it exists.
		if (StructKeyExists(variables, "config")) {
			config();
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
		// When the file is not found in either the existing or nonexisting list we know that we have not yet checked for it.
		local.helperFileExists = false;
		if (
			!ListFindNoCase(application.wheels.existingHelperFiles, arguments.name)
			&& !ListFindNoCase(application.wheels.nonExistingHelperFiles, arguments.name)
		) {
			if (FileExists(ExpandPath(local.template))) {
				local.helperFileExists = true;
			}
			if ($get("cacheFileChecking")) {
				if (local.helperFileExists) {
					application.wheels.existingHelperFiles = ListAppend(application.wheels.existingHelperFiles, arguments.name);
				} else {
					application.wheels.nonExistingHelperFiles = ListAppend(
						application.wheels.nonExistingHelperFiles,
						arguments.name
					);
				}
			}
		}

		// Include controller specific helper file if it exists.
		if (
			Len(arguments.name)
			&& (ListFindNoCase(application.wheels.existingHelperFiles, arguments.name) || local.helperFileExists)
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
		return this;
	}

	/**
	 * Get the class level data from the controller object in the application scope and set it to this controller.
	 * By class level we mean that it's stored in the controller object in the application scope.
	 */
	public void function $setControllerClassData() {
		variables.$class = application.wheels.controllers[arguments.name].$getControllerClassData();
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
		if (structKeyExists(server, "boxlang")) {
			variables.this = this;
		}
		Mixins.$initializeMixins(variables);
	}
}
