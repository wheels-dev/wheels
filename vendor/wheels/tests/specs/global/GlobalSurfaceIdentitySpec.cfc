/**
 * Pin the public Global helper surface after the DC7 split (issue ##3241).
 *
 * `vendor/wheels/Global.cfc` is now a thin include orchestrator; the helpers
 * live in `vendor/wheels/global/*.cfm` and compile into the component.
 * Behavior must stay byte-identical: every name that was a public method on
 * wheels.Global before the split must still be a custom function on a live
 * Global instance (application.wo), and `$buildProtectedControllerMethods()`
 * must still list every public non-`$` helper so `$callAction()` rejects
 * dispatch to `env` / `model` / `URLFor` and friends.
 *
 * New `$`-prefixed internals added for Adobe include-discovery are allowed
 * (they are not a user-facing API). Removals or renames fail this spec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		var ctx = {
			g: application.wo,
			expected: $preSplitGlobalPublicNames()
		};

		describe("Global.cfc public mixin surface (issue ##3241)", () => {

			it("keeps every pre-split public helper callable on a live Global instance", () => {
				var missing = [];
				var nameCount = ArrayLen(ctx.expected);
				for (var i = 1; i <= nameCount; i++) {
					var name = ctx.expected[i];
					if (!StructKeyExists(ctx.g, name) || !IsCustomFunction(ctx.g[name])) {
						ArrayAppend(missing, name);
					}
				}
				expect(ArrayLen(missing)).toBe(
					0,
					"pre-split public Global helpers missing from application.wo: " & ArrayToList(missing)
				);
			});

			it("lists every pre-split public non-$ helper in the protected-controller set", () => {
				var protectedMethods = ctx.g.$buildProtectedControllerMethods();
				var missing = [];
				var nameCount = ArrayLen(ctx.expected);
				for (var i = 1; i <= nameCount; i++) {
					var name = ctx.expected[i];
					if (Left(name, 1) == "$") {
						continue;
					}
					if (!ListFindNoCase(protectedMethods, name)) {
						ArrayAppend(missing, name);
					}
				}
				expect(ArrayLen(missing)).toBe(
					0,
					"public non-$ Global helpers missing from $buildProtectedControllerMethods(): " & ArrayToList(missing)
				);
			});

			it("source-scans Global.cfc and vendor/wheels/global/*.cfm for the same public names", () => {
				var fromFiles = ctx.g.$readGlobalIncludeFunctionNames();
				var fileSet = {};
				var fileCount = ArrayLen(fromFiles);
				for (var i = 1; i <= fileCount; i++) {
					fileSet[fromFiles[i]] = true;
				}
				var missing = [];
				var nameCount = ArrayLen(ctx.expected);
				for (var j = 1; j <= nameCount; j++) {
					if (!StructKeyExists(fileSet, ctx.expected[j])) {
						ArrayAppend(missing, ctx.expected[j]);
					}
				}
				expect(ArrayLen(missing)).toBe(
					0,
					"pre-split public helpers not found in Global.cfc / vendor/wheels/global/*.cfm: " & ArrayToList(missing)
				);
			});

			it("still resolves representative helpers after the include split", () => {
				expect(Len(ctx.g.$appKey())).toBeGT(0);
				expect(ctx.g.capitalize("wheels")).toBe("Wheels");
				expect(ctx.g.singularize("statuses")).toBe("status");
			});

			it("resolves the Application.cfc onAbort include path against /app, not the webroot", () => {
				// Lives on Global.cfc (not tags.cfm) so this path uses mappings.
				// When $include was compiled from vendor/wheels/global/tags.cfm,
				// Lucee resolved /app/events/onabort.cfm under the webroot and
				// every abort (including GET / and LuCLI) returned HTTP 500.
				ctx.g.$include(template = "../../" & application.wheels.eventPath & "/onabort.cfm");
			});

			it("collapses Application.cfc event-include prefixes to the /app mapping", () => {
				// Application.cfc concatenated "../../" onto eventPath
				// (`/app/events`), producing ../../../app/events/onabort.cfm.
				// That missed after the include split (LuCLI 1 fail / 4 error).
				var eventPath = application.wheels.eventPath;
				expect(ctx.g.$resolveGlobalIncludeTemplate("../../" & eventPath & "/onabort.cfm")).toBe(
					"/app/events/onabort.cfm"
				);
				expect(ctx.g.$resolveGlobalIncludeTemplate("../../" & eventPath & "/onapplicationend.cfm")).toBe(
					"/app/events/onapplicationend.cfm"
				);
				expect(ctx.g.$resolveGlobalIncludeTemplate(eventPath & "/onabort.cfm")).toBe("/app/events/onabort.cfm");
				expect(ctx.g.$resolveGlobalIncludeTemplate("/config/routes.cfm")).toBe("/config/routes.cfm");
				ctx.g.$include(template = eventPath & "/onabort.cfm");
				ctx.g.$include(template = eventPath & "/onapplicationend.cfm");
			});

			it("invalid-request guard is deeper than the front controller, not the include file", () => {
				// $abortInvalidRequest used GetCurrentTemplatePath(), which on
				// Lucee is the mapping-absolute include /wheels/global/request.cfm
				// when the helper is an include UDF. public/index.cfm is deeper
				// than that short path, so every GET / looked "invalid" and
				// 404'd (issue ##3241). ExpandPath("/wheels/Global.cfc") is
				// the pre-split baseline.
				var globalCfc = Replace(ExpandPath("/wheels/Global.cfc"), "\", "/", "all");
				var frontController = Replace(
					ExpandPath(GetDirectoryFromPath(globalCfc) & "../../public/index.cfm"),
					"\",
					"/",
					"all"
				);
				expect(FileExists(globalCfc)).toBeTrue();
				expect(FileExists(frontController)).toBeTrue();
				expect(ListLen(frontController, "/")).toBeLTE(
					ListLen(globalCfc, "/"),
					"front controller must not look deeper than Global.cfc"
				);
			});

		});
	}

	/**
	 * Public function names declared on wheels.Global before the DC7 split.
	 * Kept as a method (not a closure-local) so Adobe CF closures can reach
	 * it via the spec instance (cross-engine invariant ##3).
	 */
	public array function $preSplitGlobalPublicNames() {
		return [
			"$abortInvalidRequest",
			"$addToCache",
			"$appKey",
			"$args",
			"$buildComponentIntegrationPlan",
			"$buildDebugReloadUrl",
			"$buildProtectedControllerMethods",
			"$buildReleaseZip",
			"$cache",
			"$cacheCount",
			"$cachedControllerClassExists",
			"$cachedControllerLookup",
			"$cachedModelClassExists",
			"$cachedModelLookup",
			"$canonicalize",
			"$cfinvoke",
			"$cgiScope",
			"$checkMinimumVersion",
			"$cleanInlist",
			"$clearCache",
			"$clearControllerInitializationCache",
			"$clearModelInitializationCache",
			"$combineArguments",
			"$componentIntegrationPlan",
			"$constructParams",
			"$content",
			"$contentType",
			"$convertToString",
			"$corsMiddlewareActive",
			"$createControllerClass",
			"$createModelClass",
			"$createObjectFromRoot",
			"$dbinfo",
			"$debugPoint",
			"$deprecated",
			"$directory",
			"$dollarify",
			"$doubleCheckedLock",
			"$engineAdapter",
			"$ensurePaginationStore",
			"$excludeSystemSchemaRows",
			"$file",
			"$fileExistsNoCase",
			"$findRoute",
			"$fireOnErrorCallbacks",
			"$fullCgiDomainString",
			"$fullDomainString",
			"$get",
			"$getChannelEngine",
			"$getFromCache",
			"$getRequestTimeout",
			"$globalIncludesChanged",
			"$hasEngineAdapter",
			"$hashedKey",
			"$header",
			"$htmlhead",
			"$image",
			"$include",
			"$includeAndOutput",
			"$includeAndReturnOutput",
			"$includeConfig",
			"$initializeRequestScope",
			"$invoke",
			"$listClean",
			"$listToStruct",
			"$loadPackages",
			"$loadPlugins",
			"$loadRoutes",
			"$location",
			"$lockedLoadRoutes",
			"$mail",
			"$maintenanceModeExempt",
			"$mixinOverrideSet",
			"$namedArguments",
			"$normalizeMixinCollisions",
			"$normalizePath",
			"$objectFileName",
			"$parseSlashDate",
			"$pluginObj",
			"$prependUrl",
			"$promoteIncludedGlobalsToThis",
			"$protectedControllerMethodsLookup",
			"$query",
			"$readFrameworkVersion",
			"$reincludeGlobals",
			"$removeFromCache",
			"$resolveFrameworkPaths",
			"$resolveSubpathInclude",
			"$responseCommitted",
			"$restoreTestRunnerApplicationScope",
			"$routeVariables",
			"$scanAndPromoteIncludedGlobals",
			"$secureCompare",
			"$set",
			"$setCORSHeaders",
			"$setNamedRoutePositions",
			"$simpleLock",
			"$singularizeOrPluralize",
			"$snapshotGlobalIncludes",
			"$splitOutsideFunctions",
			"$statusCode",
			"$structKeysExist",
			"$tenantDataSource",
			"$throwErrorOrShow404Page",
			"$timeSpanForCache",
			"$timestamp",
			"$toXml",
			"$trustProxyHeaders",
			"$trustedClientIp",
			"$verifyInterfaceContracts",
			"$warnGlobalCorsDeferred",
			"$wddx",
			"$wildcardDomainMatch",
			"$wildcardDomainMatchCGI",
			"$zip",
			"URLFor",
			"addFormat",
			"capitalize",
			"controller",
			"deobfuscateParam",
			"distanceOfTimeInWords",
			"env",
			"excerpt",
			"generateUUID",
			"get",
			"humanize",
			"hyphenize",
			"injector",
			"mapper",
			"mimeTypes",
			"model",
			"obfuscateParam",
			"pagination",
			"pluginNames",
			"pluralize",
			"processRequest",
			"publish",
			"registerOnError",
			"service",
			"set",
			"setPagination",
			"singularize",
			"switchTenant",
			"tenant",
			"timeAgoInWords",
			"timeUntilInWords",
			"titleize",
			"truncate",
			"wordTruncate"
		];
	}

}
