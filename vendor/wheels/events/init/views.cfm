<cfscript>
		// Asset path settings.
		// assetPaths can be struct with two keys, http and https, if no https struct key, http is used for secure and non-secure.
		// Example: {http="asset0.domain1.com,asset2.domain1.com,asset3.domain1.com", https="secure.domain1.com"}
		application.$wheels.assetQueryString = false;
		application.$wheels.assetPaths = false;
		if (application.$wheels.environment != "development") {
			application.$wheels.assetQueryString = true;
		}

		// Configurable paths.
		application.$wheels.eventPath = "/app/events";
		application.$wheels.filePath = "files";
		application.$wheels.imagePath = "images";
		application.$wheels.javascriptPath = "javascripts";
		application.$wheels.modelPath = "/app/models";
		application.$wheels.pluginPath = "/plugins";
		application.$wheels.pluginComponentPath = "/plugins";
		application.$wheels.stylesheetPath = "stylesheets";
		application.$wheels.viewPath = "/app/views";
		application.$wheels.controllerPath = "/app/controllers";

		// Test framework settings.
		application.$wheels.validateTestPackageMetaData = true;
		application.$wheels.restoreTestRunnerApplicationScope = true;
</cfscript>
