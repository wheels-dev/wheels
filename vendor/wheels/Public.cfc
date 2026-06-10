component output="false" displayName="Internal GUI" extends="wheels.Global" {

	/**
	 * Internal function.
	 */
	public struct function $init() {
		include "/wheels/public/helpers.cfm";
		return this;
	}

	/**
	 * Returns true unless the current application environment is `development`
	 * (fail closed: a missing `application.wheels` struct or `environment` key
	 * also blocks). This is an allowlist matching the environment checks in
	 * consoleeval.cfm and mcp.cfm; the name is historical from issue #2233,
	 * when the gate only matched `production`.
	 *
	 * The public GUI exposes routes, env info, a CFML REPL, test runners, and
	 * a migration UI. Even if a developer overrides `enablePublicComponent` to
	 * true outside development (documented historical behavior for ad-hoc
	 * debugging), these surfaces must stay gated.
	 */
	public boolean function $shouldBlockInProduction() {
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "environment")) {
			return true;
		}
		return application.wheels.environment != "development";
	}

	/**
	 * Defense-in-depth: unless the current environment is `development`,
	 * short-circuit the handler with a 404 response before any view is
	 * included. Called as the first statement of every non-`index` handler in
	 * this component.
	 */
	public void function $blockInProduction() {
		if ($shouldBlockInProduction()) {
			cfheader(statuscode = 404);
			cfcontent(type = "text/plain");
			WriteOutput("Not Found");
			abort;
		}
	}

	/**
	 * Returns true when a /wheels/cli bridge command changes state — DB
	 * schema/data mutations (migrations, seeds, resets, job processing) or
	 * file writes (migration generators, dump output). These commands must
	 * pass $cliMutationGateCheck() before running; read-only commands stay
	 * reachable over plain GET for the CLI and the legacy GUI bridge.
	 *
	 * `diff` is read-only analysis unless asked to write migration files,
	 * so the caller passes that flag separately (2026-06-09 review SEC-4).
	 */
	public boolean function $cliCommandIsMutating(required string command, boolean writesFiles = false) {
		local.mutating = "createMigration,migrateTo,migrateToLatest,migrateUp,migrateDown,renameSystemTables,"
			& "redoMigration,forgetVersion,pretendVersion,dbRollback,dbSeed,dbCreate,dbReset,dbSetup,dbDump,"
			& "jobsProcessNext,jobsRetry,jobsPurge";
		if (ListFindNoCase(local.mutating, arguments.command)) {
			return true;
		}
		return CompareNoCase(arguments.command, "diff") == 0 && arguments.writesFiles;
	}

	/**
	 * Gate for state-changing /wheels/cli commands (2026-06-09 review SEC-4):
	 * the request must be a POST, from a loopback address (with no
	 * non-loopback X-Forwarded-For hop), carrying the reload password. A
	 * plain GET was CSRF-reachable — `<img src=".../wheels/cli?command=dbReset">`
	 * on any page a developer visits would silently drop every table.
	 *
	 * Inputs arrive as arguments (instead of reading cgi directly) so the
	 * policy is unit-testable. Returns {allowed, statusCode, error}. Fails
	 * closed when no reload password is configured, matching consoleeval.cfm.
	 */
	public struct function $cliMutationGateCheck(
		required string requestMethod,
		required string remoteAddr,
		string forwardedFor = "",
		string password = ""
	) {
		if (arguments.requestMethod != "POST") {
			return {
				allowed = false,
				statusCode = 405,
				error = "This command changes state and must be sent as a POST request with the reload password. Upgrade the wheels CLI if it still sends GET."
			};
		}
		if (!$isLoopbackAddress(arguments.remoteAddr)) {
			return {allowed = false, statusCode = 403, error = "State-changing CLI commands are restricted to localhost."};
		}
		if (Len(Trim(arguments.forwardedFor))) {
			for (local.ip in ListToArray(arguments.forwardedFor)) {
				if (!$isLoopbackAddress(Trim(local.ip))) {
					return {allowed = false, statusCode = 403, error = "State-changing CLI commands are restricted to localhost."};
				}
			}
		}
		if (
			!StructKeyExists(application, "wheels")
			|| !StructKeyExists(application.wheels, "reloadPassword")
			|| !Len(Trim(application.wheels.reloadPassword))
		) {
			return {
				allowed = false,
				statusCode = 403,
				error = "State-changing CLI commands require a reload password. Set WHEELS_RELOAD_PASSWORD in .env or reloadPassword in config/settings.cfm."
			};
		}
		if (!$cliSecureCompare(arguments.password, application.wheels.reloadPassword)) {
			return {allowed = false, statusCode = 403, error = "Invalid reload password."};
		}
		return {allowed = true, statusCode = 200, error = ""};
	}

	/**
	 * True when the supplied IP address (or hostname) resolves to a loopback
	 * address. Empty input and unresolvable input both fail closed.
	 */
	public boolean function $isLoopbackAddress(required string ipAddress) {
		if (!Len(Trim(arguments.ipAddress))) {
			return false;
		}
		try {
			return CreateObject("java", "java.net.InetAddress").getByName(Trim(arguments.ipAddress)).isLoopbackAddress();
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Constant-time string comparison (hash both sides, compare digests via
	 * MessageDigest.isEqual) to prevent timing attacks on the reload
	 * password. Same construction as consoleeval.cfm / onapplicationstart.cfc.
	 */
	public boolean function $cliSecureCompare(required string input, required string expected) {
		return CreateObject("java", "java.security.MessageDigest").isEqual(
			Hash(arguments.input, "SHA-256").getBytes("UTF-8"),
			Hash(arguments.expected, "SHA-256").getBytes("UTF-8")
		);
	}

	/**
	 * Resolves the dbDump `output` parameter to a canonical absolute path
	 * and confines it to the application's web root — the same
	 * canonicalize-and-confine pattern guideImage() uses. Returns "" when
	 * the path is empty or escapes the root via `../` traversal
	 * (2026-06-09 review SEC-5).
	 */
	public string function $cliResolveDumpPath(required string output) {
		if (!Len(Trim(arguments.output))) {
			return "";
		}
		try {
			local.canonicalRoot = CreateObject("java", "java.io.File").init(ExpandPath("/")).getCanonicalPath();
			// Treat the requested path as web-root-relative. The old raw
			// ExpandPath() resolved bare relative paths against the current
			// template directory and let `../` climb out of the application
			// entirely; java.io.File(parent, child) keeps absolute child
			// paths contained too, and getCanonicalPath() collapses any
			// remaining traversal before the confinement check below.
			local.canonicalTarget = CreateObject("java", "java.io.File").init(local.canonicalRoot, arguments.output).getCanonicalPath();
		} catch (any e) {
			return "";
		}
		local.separator = CreateObject("java", "java.io.File").separator;
		if (Right(local.canonicalRoot, 1) != local.separator) {
			local.canonicalRoot &= local.separator;
		}
		if (CompareNoCase(Left(local.canonicalTarget, Len(local.canonicalRoot)), local.canonicalRoot) != 0) {
			return "";
		}
		return local.canonicalTarget;
	}

	/**
	 * Returns the migrator adapter name for the application datasource,
	 * memoized in the application scope — $getDBType() costs a $dbinfo
	 * round-trip on every call and the driver behind a datasource cannot
	 * change without a reload (which rebuilds application.wheels and so
	 * clears this cache). Keyed by datasource name so a datasource swap
	 * re-probes (2026-06-09 review P10).
	 */
	public string function $cliDatabaseType() {
		local.dsName = application.wheels.dataSourceName;
		if (!StructKeyExists(application.wheels, "$cliDbTypeCache")) {
			application.wheels["$cliDbTypeCache"] = {};
		}
		if (!StructKeyExists(application.wheels.$cliDbTypeCache, local.dsName)) {
			application.wheels.$cliDbTypeCache[local.dsName] = CreateObject("component", "wheels.migrator.Base").$getDBType();
		}
		return application.wheels.$cliDbTypeCache[local.dsName];
	}

	/**
	 * Formats the migrator's discovery list for the /wheels/cli dbStatus
	 * command, mapping the migrator's own status field ("migrated" or "")
	 * to applied/pending. The previous version-comparison heuristic
	 * (version <= currentVersion → "applied") misclassified out-of-sequence
	 * pending migrations as applied — the exact shared-dev-DB drift
	 * `migrate doctor` exists to surface (2026-06-09 review P3).
	 */
	public struct function $cliFormatMigrationStatus(required array migrations) {
		local.rv = {migrations = [], summary = {total = 0, applied = 0, pending = 0}};
		for (local.migration in arguments.migrations) {
			local.isApplied = local.migration.status == "migrated";
			// getAvailableMigrations() does not track per-row apply
			// timestamps; keep the key for CLI display compatibility
			// (the CLI prints "-" when empty).
			ArrayAppend(
				local.rv.migrations,
				{
					version = local.migration.version,
					description = local.migration.name,
					status = local.isApplied ? "applied" : "pending",
					appliedAt = ""
				}
			);
			if (local.isApplied) {
				local.rv.summary.applied++;
			} else {
				local.rv.summary.pending++;
			}
		}
		local.rv.summary.total = ArrayLen(local.rv.migrations);
		return local.rv;
	}

	/**
	 * Returns a struct { packages: [...], error: "" } populated from the
	 * wheels-packages registry. Short-circuits outside development (defense in
	 * depth — the handler is already $blockInProduction()-gated, which since
	 * #2903 is a development-only allowlist). Captures
	 * any registry error into the `error` field so the view can render a
	 * friendly banner instead of a stack trace.
	 *
	 * The optional `registry` argument is for tests; normal callers pass
	 * nothing and get a memoized application-scope Registry instance.
	 */
	public struct function $loadRegistryPackages(any registry = "") {
		if ($shouldBlockInProduction()) {
			return {packages = [], error = ""};
		}
		local.reg = IsObject(arguments.registry) ? arguments.registry : $getRegistryClient();
		try {
			return {packages = local.reg.listAll(), error = ""};
		} catch ("Wheels.Packages.RegistryUnavailable" e) {
			return {packages = [], error = "Registry lookup failed: " & e.message};
		} catch ("Wheels.Packages.RegistryMalformed" e) {
			return {packages = [], error = "Registry lookup failed: " & e.message};
		} catch ("Wheels.Packages.UnknownPackage" e) {
			return {packages = [], error = "Registry lookup failed: " & e.message};
		}
	}

	/**
	 * Lazy, app-scope memo of the framework's Registry component.
	 *
	 * Lives at `vendor/wheels/services/packages/` so it ships with every
	 * generated app — the framework's debug panel can surface registry
	 * packages without any CLI dependency on disk. Issue #2530.
	 */
	private any function $getRegistryClient() {
		if (!StructKeyExists(application.wheels, "$packageRegistry")) {
			application.wheels.$packageRegistry = new wheels.services.packages.Registry();
		}
		return application.wheels.$packageRegistry;
	}

	/**
	 * Returns true when a setting name looks like it holds a secret (keys,
	 * passwords, passphrases, tokens, credentials). Single source of truth for
	 * the /wheels/info page so the HTML and JSON branches cannot drift — the
	 * JSON branch omits matching settings and the HTML branch redacts them.
	 *
	 * `accessControlAllowCredentials` (and any future `*allowCredentials` flag)
	 * is exempt: it mirrors the boolean `Access-Control-Allow-Credentials` CORS
	 * response header and is not a credential value.
	 */
	public boolean function $isProtectedSetting(required string settingName) {
		if (ReFindNoCase("allowcredentials$", arguments.settingName)) {
			return false;
		}
		return ReFindNoCase("(secret|password|passphrase|privatekey|apikey|credential|token)", arguments.settingName) > 0;
	}

	/**
	 * Returns the display-safe HTML value for a setting row on the /wheels/info
	 * page. Secret-shaped settings are redacted without ever being read, so an
	 * unset key cannot throw and the raw value never reaches the output buffer.
	 */
	public string function $settingDisplayValue(required string settingName) {
		if ($isProtectedSetting(arguments.settingName)) {
			return "<em>[redacted]</em>";
		}
		return formatSettingOutput(get(arguments.settingName));
	}

	/**
	 * Returns the whitelisted subset of getApplicationMetadata() that the JSON
	 * branch of /wheels/info may serialize. The full metadata struct carries
	 * datasource definitions (credentials), ORM settings, and arbitrary
	 * application config, so anything not explicitly listed here is dropped
	 * (issue #2974).
	 */
	public struct function $safeApplicationMetadata(required struct metadata) {
		local.whitelist = ListToArray("applicationTimeout,mappings,name,sessionManagement,sessionTimeout,setClientCookies");
		local.rv = {};
		for (local.metaKey in local.whitelist) {
			if (StructKeyExists(arguments.metadata, local.metaKey)) {
				local.rv[local.metaKey] = arguments.metadata[local.metaKey];
			}
		}
		return local.rv;
	}

	/**
	 * Resolves the docs-viewer `format` request parameter to a safe layout
	 * filename. Falls back to `"html"` for empty input or anything that isn't
	 * a bare alphanumeric token — matching the LFI hardening shipped for
	 * $getRequestFormat() so `vendor/wheels/public/docs/core.cfm` can't be
	 * tricked into including arbitrary files via the `layouts/<format>.cfm`
	 * interpolation.
	 */
	public string function $resolveDocFormat(required string format) {
		if (ReFind("^[A-Za-z0-9]+$", arguments.format)) {
			return arguments.format;
		}
		return "html";
	}

	/*
	This is just a proof of concept
	*/
	function index() {
		include "/wheels/public/views/congratulations.cfm";
		return "";
	}
	function info() {
		$blockInProduction();
		include "/wheels/public/views/info.cfm";
		return "";
	}
	function routes() {
		$blockInProduction();
		include "/wheels/public/views/routes.cfm";
		return "";
	}
	function routetester(verb, path) {
		$blockInProduction();
		include "/wheels/public/views/routetester.cfm";
		return "";
	}
	function routetesterprocess(verb, path) {
		$blockInProduction();
		include "views/routetesterprocess.cfm";
		return "";
	}
	function api() {
		$blockInProduction();
		include "/wheels/public/views/api.cfm";
		return "";
	}
	function runner() {
		$blockInProduction();
		include "/wheels/public/views/runner.cfm";
		return "";
	}

	function testbox() {
		$blockInProduction();
		// Prefer the project's own runner if it exists (advanced users who
		// scaffolded a custom tests/runner.cfm). Otherwise fall back to a
		// built-in app-test runner that scans tests.specs/ via TestBox and
		// emits the same JSON shape as the framework's core runner. Without
		// this fallback, fresh apps got "Page [/tests/runner.cfm] not found"
		// because `wheels new` doesn't scaffold one.
		var projectRunner = ExpandPath("/tests/runner.cfm");
		if (FileExists(projectRunner)) {
			include "/tests/runner.cfm";
			return;
		}
		include "/wheels/tests/app-runner.cfm";
	}

	public function tests_testbox() {
		$blockInProduction();
		// Delegate to RocketUnit if testFramework setting says so
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "testFramework")
			&& application.wheels.testFramework == "rocketunit"
		) {
			include "/wheels/public/views/tests.cfm";
			return "";
		}

		// Set proper HTTP status first
		cfheader(statuscode = "200");

		// Simple test to ensure the endpoint works
		if (StructKeyExists(url, "test") && url.test == "simple") {
			cfcontent(type = "application/json");
			WriteOutput('{"success":true,"message":"TestBox endpoint is working"}');
			abort;
		}

		// Set content type based on format
		if (StructKeyExists(url, "format") && url.format == "json") {
			cfcontent(type = "application/json");
		} else if (StructKeyExists(url, "format") && url.format == "txt") {
			cfcontent(type = "text/plain");
		}

		// Include the TestBox runner
		include "/wheels/tests/runner.cfm";

		// Ensure we abort to prevent any further processing
		abort;
	}
	public function clitests() {
		$blockInProduction();
		include "/wheels/public/views/clitests.cfm";
		abort;
	}

	function packages() {
		$blockInProduction();
		include "/wheels/public/views/packages.cfm";
		return "";
	}
	function tests() {
		$blockInProduction();
		include "/wheels/public/views/tests.cfm";
		return "";
	}
	function migrator() {
		$blockInProduction();
		include "/wheels/public/views/migrator.cfm";
		return "";
	}
	function migratortemplates() {
		$blockInProduction();
		include "/wheels/public/views/templating.cfm";
		return "";
	}
	function migratortemplatescreate() {
		$blockInProduction();
		include "/wheels/public/migrator/templating.cfm";
		return "";
	}
	function migratorcommand() {
		$blockInProduction();
		include "/wheels/public/migrator/command.cfm";
		return "";
	}
	function migratorsql() {
		$blockInProduction();
		include "/wheels/public/migrator/sql.cfm";
		return "";
	}
	function consoleeval() {
		$blockInProduction();
		include "/wheels/public/views/consoleeval.cfm";
		return "";
	}
	function cli() {
		$blockInProduction();
		include "/wheels/public/views/cli.cfm";
		return "";
	}
	function packagelist() {
		$blockInProduction();
		include "/wheels/public/views/packagelist.cfm";
		return "";
	}
	function packageentry() {
		$blockInProduction();
		include "/wheels/public/views/packageentry.cfm";
		return "";
	}
	function plugins() {
		$blockInProduction();
		include "/wheels/public/views/plugins.cfm";
		return "";
	}
	function pluginentry() {
		$blockInProduction();
		include "/wheels/public/views/pluginentry.cfm";
		return "";
	}
	function build() {
		$blockInProduction();
		setting requestTimeout=10000 showDebugOutput=false;
		zipPath = $buildReleaseZip();
		$header(name = "Content-disposition", value = "inline; filename=#GetFileFromPath(zipPath)#");
		$content(file = zipPath, type = "application/zip", deletefile = true);
		return "";
	}

	/*
		Check for legacy urls and params
		Example Strings to test against
		?controller=wheels&action=wheels&
			view=routes
			view=docs
			view=build
			view=migrate
			view=cli

			// Packages
			view=packages&type=core
			view=packages&type=app
			view=packages&type=[PLUGIN]

			// Test Runnner
			view=tests&type=core
			view=tests&type=app
			view=tests&type=[PLUGIN]
		*/
	function wheels() {
		$blockInProduction();
		local.action = StructKeyExists(request.wheels.params, "action") ? request.wheels.params.action : "";
		local.view = StructKeyExists(request.wheels.params, "view") ? request.wheels.params.view : "";
		local.type = StructKeyExists(request.wheels.params, "type") ? request.wheels.params.type : "";

		switch (local.view) {
			case "routes":
			case "docs":
			case "cli":
			case "tests":
			case "runner":
				include "/wheels/public/views/#local.view#.cfm";
				break;
			case "testbox":
				// Handle testbox specifically
				return tests_testbox();
			case "packages":
				include "/wheels/public/views/packages.cfm";
				break;
			case "migrate":
				include "/wheels/public/views/migrator.cfm";
				break;
			default:
				include "/wheels/public/views/congratulations.cfm";
				break;
		}
		return "";
	}

	function legacy() {
		$blockInProduction();
		// Handle legacy ?controller=wheels&action=wheels&view=xxx URLs
		return wheels();
	}

	function guides() {
		$blockInProduction();
		include "/wheels/public/views/guides.cfm";
		return "";
	}

	function ai() {
		$blockInProduction();
		include "/wheels/public/views/ai.cfm";
		return "";
	}

	function guideImage() {
		$blockInProduction();
		var file = StructKeyExists(request.wheels.params, "file") ? request.wheels.params.file : "";

		file = GetFileFromPath(file);
		if (!Len(file) || Find("..", file) || ReFind("[/\\]", file)) {
			cfheader(statusCode = 404);
			WriteOutput("Image not found");
			return;
		}

		var assetsDir = ExpandPath("/wheels/docs/src/.gitbook/assets/");
		var assetPath = assetsDir & file;

		try {
			var canonicalAssets = CreateObject("java", "java.io.File").init(assetsDir).getCanonicalPath();
			var canonicalPath = CreateObject("java", "java.io.File").init(assetPath).getCanonicalPath();
		} catch (any e) {
			cfheader(statusCode = 404);
			WriteOutput("Image not found");
			return;
		}
		if (!FileExists(assetPath) || CompareNoCase(Left(canonicalPath, Len(canonicalAssets)), canonicalAssets) != 0) {
			cfheader(statusCode = 404);
			WriteOutput("Image not found");
			return;
		}

		var ext = LCase(ListLast(file, "."));
		var mime = "application/octet-stream";
		switch (ext) {
			case "png":
				mime = "image/png";
				break;
			case "jpg":
			case "jpeg":
				mime = "image/jpeg";
				break;
			case "gif":
				mime = "image/gif";
				break;
			case "svg":
				mime = "image/svg+xml";
				break;
			case "webp":
				mime = "image/webp";
				break;
		}
		cfheader(name = "Content-Type", value = mime);
		cffile(action = "readBinary", file = assetPath, variable = "imgData");
		cfcontent(type = mime, variable = imgData);
	}

	function mcp() {
		$blockInProduction();
		include "/wheels/public/views/mcp.cfm";
		return "";
	}

}
