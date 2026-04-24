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
		var results = {issues: [], warnings: [], passed: [], mixinCollisions: []};

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
	 * legacy plugins in plugins/. Reads manifests, strips block comments,
	 * and parses each package's main CFC — plus any in-package `extends`
	 * ancestors — for public-function declarations. Per-method `mixin="..."`
	 * attributes in the signature tail override the manifest-level target,
	 * matching the runtime semantics in PackageLoader.$collectMixins.
	 *
	 * Reports method×target pairs registered by more than one package/plugin
	 * unless any participant declared the method in provides.overrides.
	 *
	 * Residual limitations (runtime PackageLoader remains authoritative):
	 *   • `extends` outside the package dir (e.g., wheels.* or a dotted path
	 *     resolved via mapping) is not followed — we can't see those methods
	 *     statically.
	 *   • Methods composed into the main CFC at runtime (mixin injection,
	 *     dynamic registration) are invisible to any static pass.
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
				arrayAppend(arguments.results.mixinCollisions, {
					target: second.target,
					method: second.method,
					firstName: first.name,
					firstSource: first.source,
					secondName: second.name,
					secondSource: second.source
				});
				first = second;
			}
		}

		if (collisionCount > 0) {
			arrayAppend(
				arguments.results.warnings,
				"#collisionCount# mixin collision(s) detected — run 'wheels doctor --verbose' for details"
			);
		} else if (directoryExists(vendorDir) || directoryExists(pluginsDir)) {
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

		// Collect methods from the main CFC and its in-package extends chain.
		// Each value is either "" (use manifest target) or a per-method mixin
		// attribute value (supports "none", "global", or a comma list).
		var methods = {};
		$scanCfcRecursive(arguments.pkgDir, cfcPath, methods, {});

		// Expand targets (global = all supported mixin component types).
		// Wrap in listToArray so Adobe CF's for...in iterates elements, not chars.
		var allTargets = "application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test";
		var defaultTargetsRaw = targetsRaw;

		for (var methodName in methods) {
			var perMethod = trim(methods[methodName]);
			var effective = len(perMethod) ? perMethod : defaultTargetsRaw;
			if (!len(effective) || effective == "none") continue;
			var expanded = (effective == "global") ? allTargets : effective;
			for (var target in listToArray(expanded)) {
				target = trim(target);
				if (!len(target) || !listFindNoCase(allTargets, target)) continue;
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

	/**
	 * Walks a CFC and its in-package `extends` ancestors, recording public
	 * methods (excluding lifecycle hooks). Inherited entries write first, so
	 * a method redeclared in the child overwrites — mirroring runtime
	 * inheritance where the instantiated object sees the child's definition.
	 *
	 * @methods Out-param. Keys are method names; values are the per-method
	 *          `mixin="..."` attribute (if declared in the signature tail)
	 *          or "" to signal "inherit manifest target".
	 * @visited Cycle guard, keyed by lowercased absolute path.
	 */
	private void function $scanCfcRecursive(
		required string pkgDir,
		required string cfcPath,
		required struct methods,
		required struct visited
	) {
		if (!fileExists(arguments.cfcPath)) return;
		var canonical = lCase(arguments.cfcPath);
		if (structKeyExists(arguments.visited, canonical)) return;
		if (structCount(arguments.visited) >= 16) return;
		arguments.visited[canonical] = true;

		var source = $stripCfmlBlockComments(fileRead(arguments.cfcPath));

		// Recurse into in-package parent FIRST so the child's redeclarations
		// overwrite (last-write-wins matches runtime inheritance).
		var extendsMatch = reFindNoCase(
			"\bcomponent\b[^{]*?\bextends\s*=\s*[""']([^""']+)[""']",
			source, 1, true
		);
		if (
			structKeyExists(extendsMatch, "pos")
			&& arrayLen(extendsMatch.pos) >= 2
			&& extendsMatch.pos[2] > 0
		) {
			var parentRef = extendsMatch.match[2];
			var parentName = listLast(parentRef, ".");
			var parentPath = arguments.pkgDir & "/" & parentName & ".cfc";
			if (fileExists(parentPath)) {
				$scanCfcRecursive(arguments.pkgDir, parentPath, arguments.methods, arguments.visited);
			}
		}

		// Function header. Access + return type both optional. Non-capturing
		// group handles explicit return types (including Namespaced.Type).
		var headerPattern = "\b(public|private|package|remote)?\s*(?:[a-zA-Z0-9_\[\]\.]+\s+)?function\s+([a-zA-Z0-9_\$]+)\s*\(";
		var lifecycleHooks = "init,onPluginLoad,onPluginActivate,register,boot";
		var sourceLen = len(source);
		var pos = 1;

		while (true) {
			var nameMatch = reFindNoCase(headerPattern, source, pos, true);
			if (!structKeyExists(nameMatch, "pos") || !arrayLen(nameMatch.pos) || nameMatch.pos[1] == 0) break;

			var access = arrayLen(nameMatch.match) >= 2 ? lCase(trim(nameMatch.match[2])) : "";
			var methodName = arrayLen(nameMatch.match) >= 3 ? nameMatch.match[3] : "";

			// Advance past the `(` (last char of the matched header) so we can
			// walk balanced parens and capture the per-method attribute tail.
			var openParenPos = nameMatch.pos[1] + nameMatch.len[1] - 1;
			var afterArgs = $advancePastBalancedParens(source, openParenPos);
			var advanceTo = afterArgs > 0 ? afterArgs + 1 : (openParenPos + 1);

			if (
				len(methodName)
				&& access != "private"
				&& !listFindNoCase(lifecycleHooks, methodName)
			) {
				var perMethodTargets = "";
				if (afterArgs > 0 && afterArgs < sourceLen) {
					var bracePos = find("{", source, afterArgs + 1);
					if (bracePos > afterArgs + 1) {
						var tailLen = bracePos - afterArgs - 1;
						var tail = mid(source, afterArgs + 1, tailLen);
						var attrMatch = reFindNoCase(
							"\bmixin\s*=\s*[""']([^""']*)[""']",
							tail, 1, true
						);
						if (
							structKeyExists(attrMatch, "pos")
							&& arrayLen(attrMatch.pos) >= 2
							&& attrMatch.pos[2] > 0
						) {
							perMethodTargets = trim(attrMatch.match[2]);
						}
					}
				}
				// Last-write-wins: if the child redeclares a parent method we
				// keep the child's per-method attribute (runtime semantics).
				arguments.methods[methodName] = perMethodTargets;
			}

			if (advanceTo <= pos) advanceTo = pos + 1;
			if (advanceTo > sourceLen) break;
			pos = advanceTo;
		}
	}

	/**
	 * Strip `/* ... *\/` block comments (including docblocks). Keeps line
	 * comments as-is — stripping `//` is unsafe near URLs in string literals
	 * and block-comment false-positives are the only class documented in
	 * issue #2260.
	 */
	private string function $stripCfmlBlockComments(required string source) {
		var s = arguments.source;
		s = reReplace(s, "<!---[\s\S]*?--->", " ", "all");
		s = reReplace(s, "/\*[\s\S]*?\*/", " ", "all");
		return s;
	}

	/**
	 * Scan forward from `openPos` (pointing AT `(`) and return the 1-indexed
	 * position of the balanced `)`. Ignores parens inside `"..."`/`'...'`
	 * string literals so default-value parens don't throw off the count.
	 * Returns 0 if unbalanced (malformed source or truncated header).
	 */
	private numeric function $advancePastBalancedParens(required string source, required numeric openPos) {
		var depth = 0;
		var i = arguments.openPos;
		var n = len(arguments.source);
		var stringDelim = "";
		while (i <= n) {
			var ch = mid(arguments.source, i, 1);
			if (len(stringDelim)) {
				if (ch == stringDelim) stringDelim = "";
			} else if (ch == '"' || ch == "'") {
				stringDelim = ch;
			} else if (ch == "(") {
				depth++;
			} else if (ch == ")") {
				depth--;
				if (depth == 0) return i;
			}
			i++;
		}
		return 0;
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
