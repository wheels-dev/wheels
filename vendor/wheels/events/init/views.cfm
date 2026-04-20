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
		application.$wheels.packagePath = "/vendor";
		application.$wheels.enablePackagesComponent = true;
		application.$wheels.stylesheetPath = "stylesheets";
		application.$wheels.viewPath = "/app/views";
		application.$wheels.controllerPath = "/app/controllers";

		// Vite asset pipeline settings.
		application.$wheels.viteDevServerUrl = "http://localhost:5173";
		application.$wheels.viteBuildPath = "build";
		application.$wheels.viteManifestFile = ".vite/manifest.json";
		application.$wheels.viteDevMode = (application.$wheels.environment == "development");
		application.$wheels.viteStrictManifest = true;

		// Test framework settings.
		application.$wheels.validateTestPackageMetaData = true;
		application.$wheels.restoreTestRunnerApplicationScope = true;

		// Form helper settings.
		// When true, object-bound form helpers (textField, emailField, select, etc.) also emit a
		// `data-auto-id` attribute alongside the auto-derived `id`. The `id` uses the historical
		// dash convention (e.g. `post-title`) and `data-auto-id` uses the underscore convention
		// (e.g. `post_title`) favored by Rails/Laravel-style browser test selectors. Only emitted
		// when the id is auto-derived from objectName + property; a user-supplied `id` suppresses it.
		application.$wheels.formHelperDataAutoId = true;
</cfscript>
