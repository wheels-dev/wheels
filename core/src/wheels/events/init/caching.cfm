<cfscript>
		// Cache settings that are always turned on regardless of mode setting.
		application.$wheels.cacheControllerConfig = true;
		application.$wheels.cacheDatabaseSchema = true;
		application.$wheels.cacheModelConfig = true;
		application.$wheels.cachePlugins = true;
		application.$wheels.cacheFileChecking = true;

		// Cache settings that are turned off in development mode only.
		application.$wheels.cacheActions = false;
		application.$wheels.cacheImages = false;
		application.$wheels.cachePages = false;
		application.$wheels.cachePartials = false;
		application.$wheels.cacheQueries = false;
		if (application.$wheels.environment != "development") {
			application.$wheels.cacheActions = true;
			application.$wheels.cacheImages = true;
			application.$wheels.cachePages = true;
			application.$wheels.cachePartials = true;
			application.$wheels.cacheQueries = true;
		}

		// Other caching settings.
		application.$wheels.maximumItemsToCache = 5000;
		application.$wheels.cacheCullPercentage = 10;
		application.$wheels.cacheCullInterval = 5;
		application.$wheels.cacheDatePart = "n";
		application.$wheels.defaultCacheTime = 60;
		application.$wheels.clearQueryCacheOnReload = true;
		application.$wheels.clearTemplateCacheOnReload = true;
		application.$wheels.cacheQueriesDuringRequest = true;
</cfscript>
