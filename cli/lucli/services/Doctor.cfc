/**
 * Health check service for diagnosing Wheels application issues.
 *
 * Performs 8 categories of checks: required dirs, recommended dirs,
 * required files, config validation, write permissions, database config,
 * test coverage, and — when running from a source checkout — CLI install
 * freshness. All checks are local file operations — no running server
 * required.
 */
component {

	public function init(required string projectRoot, string installedModuleRoot = "") {
		variables.projectRoot = arguments.projectRoot;
		variables.installedModuleRoot = arguments.installedModuleRoot;
		return this;
	}

	/**
	 * Run all health checks and return categorized results.
	 */
	public struct function runChecks() {
		var results = {issues: [], warnings: [], passed: []};

		checkRequiredDirs(results);
		checkRecommendedDirs(results);
		checkRequiredFiles(results);
		checkConfigValidation(results);
		checkWritePermissions(results);
		checkDatabaseConfig(results);
		checkTestCoverage(results);
		checkCliInstallFreshness(results);
		checkMixinCollisions(results);

		// Determine overall status
		if (arrayLen(results.issues)) {
			results.status = "CRITICAL";
		} else if (arrayLen(results.warnings)) {
			results.status = "WARNING";
		} else {
			results.status = "HEALTHY";
		}

		// Generate recommendations
		results.recommendations = buildRecommendations(results);

		return results;
	}

	// ── Check functions ──────────────────────────────────────

	private void function checkRequiredDirs(required struct results) {
		var dirs = [
			"app",
			"app/controllers",
			"app/models",
			"app/views",
			"config",
			"public"
		];
		for (var dir in dirs) {
			var fullPath = variables.projectRoot & "/" & dir;
			if (directoryExists(fullPath)) {
				arrayAppend(arguments.results.passed, "Required directory exists: #dir#/");
			} else {
				arrayAppend(arguments.results.issues, "Missing required directory: #dir#/");
			}
		}
	}

	private void function checkRecommendedDirs(required struct results) {
		var dirs = [
			{path: "tests", label: "tests/"},
			{path: "tests/specs", label: "tests/specs/"},
			{path: "app/migrator/migrations", label: "app/migrator/migrations/"}
		];
		for (var dir in dirs) {
			var fullPath = variables.projectRoot & "/" & dir.path;
			if (directoryExists(fullPath)) {
				arrayAppend(arguments.results.passed, "Recommended directory exists: #dir.label#");
			} else {
				arrayAppend(arguments.results.warnings, "Missing recommended directory: #dir.label#");
			}
		}
	}

	private void function checkRequiredFiles(required struct results) {
		var files = [
			"config/routes.cfm",
			"config/settings.cfm"
		];
		for (var f in files) {
			var fullPath = variables.projectRoot & "/" & f;
			if (fileExists(fullPath)) {
				arrayAppend(arguments.results.passed, "Required file exists: #f#");
			} else {
				arrayAppend(arguments.results.issues, "Missing required file: #f#");
			}
		}
	}

	private void function checkConfigValidation(required struct results) {
		// Check routes.cfm has content
		var routesPath = variables.projectRoot & "/config/routes.cfm";
		if (fileExists(routesPath)) {
			var routesContent = fileRead(routesPath);
			if (len(trim(routesContent)) < 10) {
				arrayAppend(arguments.results.warnings, "config/routes.cfm appears empty or minimal");
			} else {
				arrayAppend(arguments.results.passed, "config/routes.cfm has content");
			}
		}

		// Check settings.cfm exists and has content
		var settingsPath = variables.projectRoot & "/config/settings.cfm";
		if (fileExists(settingsPath)) {
			var settingsContent = fileRead(settingsPath);
			if (len(trim(settingsContent)) < 10) {
				arrayAppend(arguments.results.warnings, "config/settings.cfm appears empty or minimal");
			} else {
				arrayAppend(arguments.results.passed, "config/settings.cfm has content");
			}
		}
	}

	private void function checkWritePermissions(required struct results) {
		var dirs = [
			"app/migrator/migrations",
			"public/files"
		];
		for (var dir in dirs) {
			var fullPath = variables.projectRoot & "/" & dir;
			if (!directoryExists(fullPath)) continue;

			var testFile = fullPath & "/.write_test_" & createUUID();
			try {
				fileWrite(testFile, "test");
				fileDelete(testFile);
				arrayAppend(arguments.results.passed, "Write permission OK: #dir#/");
			} catch (any e) {
				arrayAppend(arguments.results.warnings, "No write permission: #dir#/");
			}
		}
	}

	private void function checkDatabaseConfig(required struct results) {
		// Check for datasource in settings.cfm
		var settingsPath = variables.projectRoot & "/config/settings.cfm";
		var envPath = variables.projectRoot & "/.env";
		var foundDatasource = false;

		if (fileExists(settingsPath)) {
			var content = fileRead(settingsPath);
			if (findNoCase("datasource", content) || findNoCase("dataSourceName", content)) {
				foundDatasource = true;
				arrayAppend(arguments.results.passed, "Datasource configured in config/settings.cfm");
			}
		}

		if (!foundDatasource && fileExists(envPath)) {
			var envContent = fileRead(envPath);
			if (reFindNoCase("(DATABASE|DB_)", envContent)) {
				foundDatasource = true;
				arrayAppend(arguments.results.passed, "Database config found in .env");
			}
		}

		if (!foundDatasource) {
			arrayAppend(arguments.results.warnings, "No datasource configuration found");
		}

		// Check for migrations
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";
		if (directoryExists(migrationDir)) {
			var migrations = directoryList(migrationDir, false, "name", "*.cfc");
			if (arrayLen(migrations)) {
				arrayAppend(arguments.results.passed, "#arrayLen(migrations)# migration(s) found");
			} else {
				arrayAppend(arguments.results.warnings, "No migrations found in app/migrator/migrations/");
			}
		}
	}

	private void function checkTestCoverage(required struct results) {
		var testDir = variables.projectRoot & "/tests/specs";
		if (!directoryExists(testDir)) return;

		var testFiles = directoryList(testDir, true, "name", "*.cfc");
		if (arrayLen(testFiles)) {
			arrayAppend(arguments.results.passed, "#arrayLen(testFiles)# test file(s) found");
		} else {
			arrayAppend(arguments.results.warnings, "No test files found in tests/specs/");
		}
	}

	/**
	 * Detect a stale installed CLI module that shadows the source checkout.
	 *
	 * When invoked as `wheels`, LuCLI loads modules from ~/.wheels/modules/.
	 * If ~/.wheels/modules/wheels/ is a real directory holding a pre-install
	 * copy of Module.cfc, edits a contributor makes in cli/lucli/ of their
	 * checkout silently do not take effect — exit-0 behavior persists even
	 * after a fix is merged. See issue #2223.
	 *
	 * This check runs only when all three signals are present:
	 *   - installedModuleRoot was supplied (we know where LuCLI loaded us from)
	 *   - projectRoot looks like a wheels source checkout (has cli/lucli/Module.cfc
	 *     and vendor/wheels/)
	 *   - the installed module is NOT the checkout's cli/lucli/ directory
	 *     (i.e., not a dev-install pointing directly at the checkout)
	 */
	private void function checkCliInstallFreshness(required struct results) {
		if (!len(variables.installedModuleRoot)) return;

		var checkoutModulePath = variables.projectRoot & "/cli/lucli/Module.cfc";
		var vendorWheelsPath = variables.projectRoot & "/vendor/wheels";
		if (!fileExists(checkoutModulePath) || !directoryExists(vendorWheelsPath)) return;

		var installedDir = $normalizePath(variables.installedModuleRoot);
		var checkoutDir = $normalizePath(variables.projectRoot & "/cli/lucli");
		if (installedDir == checkoutDir) return;

		var installedModulePath = variables.installedModuleRoot & "/Module.cfc";
		if (!fileExists(installedModulePath)) return;

		if ($isSymbolicLink(installedModulePath) || $isSymbolicLink(variables.installedModuleRoot)) {
			arrayAppend(arguments.results.passed, "Installed CLI module is a symlink (source changes take effect immediately)");
			return;
		}

		if ($filesBytesEqual(installedModulePath, checkoutModulePath)) {
			arrayAppend(arguments.results.passed, "Installed CLI module matches source checkout");
			return;
		}

		arrayAppend(
			arguments.results.warnings,
			"Installed CLI module at #variables.installedModuleRoot# diverges from this source checkout. "
			& "Edits under cli/lucli/ will not take effect until you reinstall or replace the installed copy with a symlink."
		);
	}

	/**
	 * Static best-effort mixin collision scan for packages in vendor/ and
	 * legacy plugins in plugins/. Reads manifests and regex-scans the main
	 * CFC of each package for public-function declarations, mapping method
	 * names to declared mixin targets. Reports method×target pairs that are
	 * registered by more than one package/plugin unless the second source
	 * acknowledged the override via provides.overrides.
	 *
	 * Limitations: regex-based, so unusual CFC shapes may under-detect; only
	 * scans the main CFC (directory-name match) — included files and script-
	 * imported functions are ignored. Runtime detection in PackageLoader is
	 * authoritative; this check exists for pre-boot visibility.
	 */
	private void function checkMixinCollisions(required struct results) {
		var vendorDir = variables.projectRoot & "/vendor";
		var pluginsDir = variables.projectRoot & "/plugins";
		var providers = {};

		if (directoryExists(vendorDir)) {
			for (var dirName in directoryList(vendorDir, false, "name")) {
				if (lCase(dirName) == "wheels") continue;
				var pkgPath = vendorDir & "/" & dirName;
				if (!directoryExists(pkgPath)) continue;
				var manifestPath = pkgPath & "/package.json";
				if (!fileExists(manifestPath)) continue;
				$recordProvidersFromManifest(providers, pkgPath, manifestPath, dirName, "package", "provides");
			}
		}

		if (directoryExists(pluginsDir)) {
			for (var dirName in directoryList(pluginsDir, false, "name")) {
				var pluginPath = pluginsDir & "/" & dirName;
				if (!directoryExists(pluginPath)) continue;
				var manifestPath = pluginPath & "/plugin.json";
				if (!fileExists(manifestPath)) continue;
				$recordProvidersFromManifest(providers, pluginPath, manifestPath, dirName, "plugin", "");
			}
		}

		var collisionCount = 0;
		for (var key in providers) {
			var entries = providers[key];
			if (arrayLen(entries) < 2) continue;
			// Static scan has no authoritative load order, so suppress the warning
			// if ANY participant declared the method in provides.overrides — that
			// signals someone is intentionally accepting the overlap. The runtime
			// path in PackageLoader still enforces the stricter semantic.
			var anyAcknowledged = false;
			for (var entry in entries) {
				if (entry.acknowledged) {
					anyAcknowledged = true;
					break;
				}
			}
			if (anyAcknowledged) continue;
			var first = entries[1];
			for (var i = 2; i <= arrayLen(entries); i++) {
				var second = entries[i];
				collisionCount++;
				arrayAppend(
					arguments.results.warnings,
					"Mixin collision: method '#second.method#' on '#second.target#' provided by #first.source# '#first.name#' is overwritten by #second.source# '#second.name#'. Acknowledge via provides.overrides to silence."
				);
				first = second;
			}
		}

		if (collisionCount == 0 && (directoryExists(vendorDir) || directoryExists(pluginsDir))) {
			arrayAppend(arguments.results.passed, "No static mixin collisions detected in vendor/ or plugins/");
		}
	}

	/**
	 * Reads a manifest + main CFC and appends provider records keyed by target+method.
	 *
	 * @providerStore Out-param struct keyed "target::method" → array of records
	 * @providesKey   "provides" for packages (nested), "" for plugins (flat)
	 */
	private void function $recordProvidersFromManifest(
		required struct providerStore,
		required string pkgDir,
		required string manifestPath,
		required string name,
		required string source,
		required string providesKey
	) {
		var manifest = {};
		try {
			manifest = deserializeJSON(fileRead(arguments.manifestPath));
		} catch (any e) {
			return;
		}
		if (!isStruct(manifest)) return;

		var provides = len(arguments.providesKey) && structKeyExists(manifest, arguments.providesKey) && isStruct(manifest[arguments.providesKey])
			? manifest[arguments.providesKey]
			: manifest;

		var targetsRaw = "";
		if (structKeyExists(provides, "mixins") && isSimpleValue(provides.mixins)) {
			targetsRaw = trim(provides.mixins);
		} else if (structKeyExists(manifest, "mixins") && isSimpleValue(manifest.mixins)) {
			targetsRaw = trim(manifest.mixins);
		}
		if (!len(targetsRaw) || targetsRaw == "none") return;

		var overrides = {};
		if (structKeyExists(provides, "overrides") && isArray(provides.overrides)) {
			for (var ov in provides.overrides) {
				if (isSimpleValue(ov) && len(trim(ov))) overrides[lCase(trim(ov))] = true;
			}
		}

		var cfcPath = arguments.pkgDir & "/" & arguments.name & ".cfc";
		if (!fileExists(cfcPath)) {
			var cfcs = directoryList(arguments.pkgDir, false, "name", "*.cfc");
			if (!arrayLen(cfcs)) return;
			cfcPath = arguments.pkgDir & "/" & cfcs[1];
		}

		var cfcSource = fileRead(cfcPath);
		var lifecycleHooks = "init,onPluginLoad,onPluginActivate,register,boot";
		var methods = {};
		// Capture (access, methodName). Access and return type are both optional
		// so we catch: `public string function x()`, `public function x()`,
		// and the implicit-public `function x()`. Skip when access == "private".
		var pattern = "\b(public|private|package|remote)?\s*(?:[a-zA-Z0-9_\[\]\.]+\s+)?function\s+([a-zA-Z0-9_\$]+)\s*\(";
		var pos = 1;
		while (true) {
			var nameMatch = reFindNoCase(pattern, cfcSource, pos, true);
			if (!structKeyExists(nameMatch, "pos") || !arrayLen(nameMatch.pos) || nameMatch.pos[1] == 0) break;
			if (arrayLen(nameMatch.match) >= 3) {
				var access = lCase(trim(nameMatch.match[2]));
				var methodName = nameMatch.match[3];
				if (access != "private" && !listFindNoCase(lifecycleHooks, methodName)) {
					methods[methodName] = true;
				}
			}
			pos = nameMatch.pos[1] + nameMatch.len[1];
		}

		// Expand targets (global = all supported mixin component types).
		// Wrap in listToArray so Adobe CF's for...in iterates elements, not chars.
		var allTargets = "application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test";
		var expanded = (targetsRaw == "global") ? allTargets : targetsRaw;
		for (var target in listToArray(expanded)) {
			target = trim(target);
			if (!len(target) || !listFindNoCase(allTargets, target)) continue;
			for (var methodName in methods) {
				var key = target & "::" & methodName;
				if (!structKeyExists(arguments.providerStore, key)) {
					arguments.providerStore[key] = [];
				}
				arrayAppend(arguments.providerStore[key], {
					name = arguments.name,
					source = arguments.source,
					target = target,
					method = methodName,
					acknowledged = structKeyExists(overrides, lCase(methodName))
				});
			}
		}
	}

	// ── Path helpers ─────────────────────────────────────────

	private string function $normalizePath(required string path) {
		var p = replace(arguments.path, "\", "/", "all");
		while (len(p) > 1 && right(p, 1) == "/") {
			p = left(p, len(p) - 1);
		}
		return p;
	}

	private boolean function $isSymbolicLink(required string path) {
		try {
			var Paths = createObject("java", "java.nio.file.Paths");
			var Files = createObject("java", "java.nio.file.Files");
			var javaPath = Paths.get(javacast("string", arguments.path), javacast("string[]", []));
			return Files.isSymbolicLink(javaPath);
		} catch (any e) {
			return false;
		}
	}

	private boolean function $filesBytesEqual(required string a, required string b) {
		try {
			var Paths = createObject("java", "java.nio.file.Paths");
			var Files = createObject("java", "java.nio.file.Files");
			var pa = Paths.get(javacast("string", arguments.a), javacast("string[]", []));
			var pb = Paths.get(javacast("string", arguments.b), javacast("string[]", []));
			if (Files.size(pa) != Files.size(pb)) return false;
			var bytesA = Files.readAllBytes(pa);
			var bytesB = Files.readAllBytes(pb);
			return createObject("java", "java.util.Arrays").equals(bytesA, bytesB);
		} catch (any e) {
			return false;
		}
	}

	// ── Recommendations ──────────────────────────────────────

	private array function buildRecommendations(required struct results) {
		var recs = [];
		var allMessages = [];
		arrayAppend(allMessages, arguments.results.issues, true);
		arrayAppend(allMessages, arguments.results.warnings, true);
		var combined = arrayToList(allMessages, " ");

		if (findNoCase("datasource", combined) || findNoCase("No datasource", combined)) {
			arrayAppend(recs, "Configure your datasource in config/settings.cfm or .env");
		}
		if (findNoCase("No migrations", combined)) {
			arrayAppend(recs, "Run 'wheels generate migration' to create your first migration");
		}
		if (findNoCase("No test files", combined) || findNoCase("Missing recommended directory: tests", combined)) {
			arrayAppend(recs, "Run 'wheels generate test' to add test coverage");
		}
		if (findNoCase("Missing required directory", combined)) {
			arrayAppend(recs, "Run 'wheels new' to scaffold a complete project structure");
		}
		if (findNoCase("Installed CLI module", combined) && findNoCase("diverges", combined)) {
			arrayAppend(
				recs,
				"Replace the stale installed module with a symlink to your checkout: "
				& "rm -rf #variables.installedModuleRoot# && "
				& "ln -s #variables.projectRoot#/cli/lucli #variables.installedModuleRoot#"
			);
		}

		return recs;
	}

}
