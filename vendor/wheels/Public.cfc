component output="false" displayName="Internal GUI" extends="wheels.Global" {

	/**
	 * Internal function.
	 */
	public struct function $init() {
		// The helpers include MUST live in its own method. 4.0.6 added
		// `$scanAndPromoteIncludedGlobals()` immediately after a raw `include`
		// in this same `$init` body (##3302 / 6bff054). That nests Adobe's
		// include page-context with a parent-class method call (Global's
		// promote scan). On the first request after a CommandBox cold start,
		// Adobe CF 2023's `UDFMethod.invoke` cleanup then calls
		// `NeoPageContext.popSuperScope` against an empty stack —
		// EmptyStackException at onapplicationstart.cfc:409
		// (`$createObjectFromRoot` → Public.$init). A later request succeeds
		// because helpers.cfm is already compiled. 4.0.5 `$init` only
		// included and returned, which is why discarding 4.0.6 files cleared
		// it. Isolate the include so its page-context pops before the promote
		// scan runs; keep the raw scan (not the memoized wrapper) so the
		// ##3302 `this`-visibility contract stays.
		$includePublicHelpers();
		$scanAndPromoteIncludedGlobals();

		return this;
	}

	/**
	 * Includes `/wheels/public/helpers.cfm` in its own UDF frame so Adobe's
	 * include page-context is popped before `$init` calls the parent-class
	 * promote scan. Do not inline this `include` back into `$init` — that
	 * nest is the 4.0.6 first-boot EmptyStackException on Adobe CF 2023.
	 *
	 * The include declares its UDFs into `variables` only — they never
	 * reach `this` on Lucee 6, Adobe 2023 or Adobe 2025 (Lucee 7 and BoxLang
	 * do promote them, which is why the split stayed invisible). Every helper
	 * in helpers.cfm is declared `public`, and the framework's own views reach
	 * them through `variables`, so the divergence only bites an external
	 * caller — `CreateObject("component", "wheels.Public").$init().$$findMatchingRoutes(…)`
	 * threw "has no function with name" on three of five engines (##3302).
	 *
	 * Same problem, same fix as the `/app/global/functions.cfm` include in
	 * `Global.cfc`'s pseudo-constructor. `$init` calls the raw scan rather than
	 * `$promoteIncludedGlobalsToThis()`: that wrapper memoizes its promote
	 * list per class in application scope, and the entry for `wheels.Public`
	 * is written by the pseudo-constructor *before* this include runs — so the
	 * memoized path would replay a stale, pre-include key list and promote
	 * nothing. This is the dev-only GUI component, not a request hot path.
	 */
	public void function $includePublicHelpers() {
		include "/wheels/public/helpers.cfm";
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
	 * included. Called as the first statement of every handler in
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
			local.separator = CreateObject("java", "java.io.File").separator;
			// Join in CFML instead of the java.io.File(parent, child)
			// constructor: RustCFML's java.io.File shim ignores the child
			// argument, so the two-argument form resolves to the parent
			// alone. Joining first keeps an absolute child contained the
			// same way java.io.File(parent, child) does on JVM engines.
			local.canonicalTarget = CreateObject("java", "java.io.File").init(local.canonicalRoot & local.separator & arguments.output).getCanonicalPath();
		} catch (any e) {
			return "";
		}
		// Lexically collapse "." and ".." for the confinement check so the
		// prefix comparison below also holds on engines whose java.io.File
		// shim does not canonicalize traversal (RustCFML). Both sides are
		// normalized the same way, so the check is equivalent on JVM engines
		// (whose getCanonicalPath() already produced canonical paths).
		local.normalizedTarget = $normalizeZipPath(Replace(local.canonicalTarget, "\", "/", "all"));
		local.normalizedRoot = $normalizeZipPath(Replace(local.canonicalRoot, "\", "/", "all"));
		if (Right(local.normalizedRoot, 1) != "/") {
			local.normalizedRoot &= "/";
		}
		if (CompareNoCase(Left(local.normalizedTarget, Len(local.normalizedRoot)), local.normalizedRoot) != 0) {
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
	 * Returns the shared CliBridge instance — the dev-UI / CLI command
	 * handlers extracted from cli.cfm (issue #2959). CliBridge is stateless
	 * (only an immutable command->method allowlist lives in its `variables`),
	 * so one instance is cached on `application.wheels` and shared across
	 * concurrent requests; `?reload=true` rebuilds `application.wheels` and
	 * re-creates it. Falls back to a fresh instance during early bootstrap
	 * (before `application.wheels` exists), mirroring `$componentIntegrationPlan`.
	 */
	public any function $cliBridge() {
		if (!StructKeyExists(application, "wheels")) {
			return CreateObject("component", "wheels.public.CliBridge").init();
		}
		if (!StructKeyExists(application.wheels, "cliBridge")) {
			lock name="wheels.cliBridge.#application.applicationName#" type="exclusive" timeout="10" {
				if (!StructKeyExists(application.wheels, "cliBridge")) {
					application.wheels.cliBridge = CreateObject("component", "wheels.public.CliBridge").init();
				}
			}
		}
		return application.wheels.cliBridge;
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
		$blockInProduction();
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
	/**
	 * API reference.
	 *
	 * The BROWSABLE page is served from the local docs bundle so it works
	 * offline, replacing the CFML renderer that walked the installed framework's
	 * source comments. The prebuilt Starlight site is the single source, so what
	 * you read locally is identical to api.wheels.dev rather than a second
	 * rendering of it.
	 *
	 * The non-HTML formats are NOT retired. `?format=json` is a published
	 * interface, not a page: the Wheels Snapshots workflow fetches
	 * /wheels/api?format=json&type=core to build the API snapshot the docs site
	 * consumes, and /wheels/ai derives its condensed summary from the same data.
	 * Those keep the CFML renderer.
	 */
	function api() {
		$blockInProduction();
		var format = StructKeyExists(request.wheels.params, "format") ? request.wheels.params.format : "html";
		if (LCase(format) != "html") {
			include "/wheels/public/views/api.cfm";
			return "";
		}
		var path = StructKeyExists(request.wheels.params, "path") ? request.wheels.params.path : "";
		if ($serveDocsFile("api", path)) {
			return "";
		}
		$docsUnavailable("api");
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

	/**
	 * Serves the prebuilt docs bundle mounted under the app webroot.
	 *
	 * The bundle is served as /wheels-docs/guides/... and /wheels-docs/api/....
	 * Assets under those prefixes are served by the container straight off
	 * disk; only the extension-less page paths reach this handler, which maps
	 * them onto the matching index.html.
	 */
	function docsBundle() {
		$blockInProduction();
		var path = StructKeyExists(request.wheels.params, "path") ? request.wheels.params.path : "";
		var site = "guides";
		if (Find("/", path)) {
			site = LCase(ListFirst(path, "/"));
			path = ListRest(path, "/");
		} elseif (Len(path)) {
			site = LCase(path);
			path = "";
		}
		if (site != "guides" && site != "api") {
			$docsUnavailable("guides");
			return "";
		}
		if ($serveDocsFile(site, path)) {
			return "";
		}
		$docsUnavailable(site);
		return "";
	}

	/**
	 * Guides. Served from the local docs bundle so they work offline.
	 *
	 * When no bundle is installed this falls back to views/guides.cfm, which
	 * redirects HTML callers to guides.wheels.dev and returns a sidebar-derived
	 * summary for AI/MCP callers hitting ?format=json — so an install without
	 * the bundle keeps working exactly as it did before.
	 */
	function guides() {
		$blockInProduction();
		var path = StructKeyExists(request.wheels.params, "path") ? request.wheels.params.path : "";
		if ($serveDocsFile("guides", path)) {
			return "";
		}
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

	/**
	 * Serves a bundled dev-UI static asset (JS/CSS/fonts) from
	 * /wheels/public/assets/ with immutable cache headers. The dev-UI pages
	 * previously inlined ~1MB of JS/CSS into every response via cfinclude
	 * (issue #2959); this action lets the browser cache those assets at
	 * versioned URLs instead. Same canonicalize-and-confine shape as
	 * guideImage(), except subdirectory paths are allowed
	 * (css/woff_files/icons.woff2) while traversal stays blocked.
	 */
	function assets() {
		$blockInProduction();
		var file = StructKeyExists(request.wheels.params, "file") ? request.wheels.params.file : "";
		var assetPath = $resolveDevAssetPath(file);
		if (!Len(assetPath)) {
			cfheader(statusCode = 404);
			WriteOutput("Asset not found");
			return;
		}
		var mime = $devAssetMimeType(assetPath);
		cfheader(name = "Cache-Control", value = "public, max-age=31536000, immutable");
		cfheader(name = "Content-Type", value = mime);
		cffile(action = "readBinary", file = assetPath, variable = "assetData");
		cfcontent(type = mime, variable = assetData);
	}

	/**
	 * Resolves a webroot-relative dev-UI asset path (e.g.
	 * `css/semantic.min.css`, `css/woff_files/icons.woff2`) to a canonical
	 * absolute path confined to /wheels/public/assets/. Unlike guideImage()
	 * this keeps subdirectory components, so the confinement relies on the
	 * charset check, the `..` rejection, AND the canonical-prefix compare.
	 * Returns "" for traversal payloads, absolute/backslash paths,
	 * disallowed extensions, and missing files.
	 */
	public string function $resolveDevAssetPath(required string file) {
		if (!Len(Trim(arguments.file))) {
			return "";
		}
		// Reject traversal, backslashes, absolute paths, and anything outside a
		// conservative charset before touching the filesystem.
		if (
			Find("..", arguments.file)
			|| Left(arguments.file, 1) == "/"
			|| ReFind("[^A-Za-z0-9_\-./]", arguments.file)
		) {
			return "";
		}
		// Extension allowlist: only known static asset types are servable —
		// prevents serving stray source files dropped under assets/.
		if (!ListFindNoCase("css,js,woff,woff2,ttf,eot,svg,png,jpg,jpeg,gif,map", ListLast(arguments.file, "."))) {
			return "";
		}
		var assetsDir = ExpandPath("/wheels/public/assets/");
		var assetPath = assetsDir & arguments.file;
		try {
			var canonicalAssets = CreateObject("java", "java.io.File").init(assetsDir).getCanonicalPath();
			var canonicalPath = CreateObject("java", "java.io.File").init(assetPath).getCanonicalPath();
		} catch (any e) {
			return "";
		}
		var separator = CreateObject("java", "java.io.File").separator;
		if (Right(canonicalAssets, 1) != separator) {
			canonicalAssets &= separator;
		}
		if (CompareNoCase(Left(canonicalPath, Len(canonicalAssets)), canonicalAssets) != 0) {
			return "";
		}
		if (!FileExists(canonicalPath)) {
			return "";
		}
		return canonicalPath;
	}

	/**
	 * Maps a dev-UI asset filename to its MIME type. Falls back to
	 * application/octet-stream for anything not in the serving allowlist.
	 */
	public string function $devAssetMimeType(required string file) {
		switch (LCase(ListLast(arguments.file, "."))) {
			case "css":
				return "text/css";
			case "js":
				return "application/javascript";
			case "map":
			case "json":
				return "application/json";
			// Added for the local docs bundle, which serves whole pages and the
			// Pagefind search index rather than just dev-UI assets.
			case "html":
			case "htm":
				return "text/html";
			case "xml":
				return "application/xml";
			case "txt":
				return "text/plain";
			case "wasm":
				return "application/wasm";
			case "webp":
				return "image/webp";
			case "avif":
				return "image/avif";
			case "ico":
				return "image/x-icon";
			case "woff2":
				return "font/woff2";
			case "woff":
				return "font/woff";
			case "ttf":
				return "font/ttf";
			case "eot":
				return "application/vnd.ms-fontobject";
			case "svg":
				return "image/svg+xml";
			case "png":
				return "image/png";
			case "jpg":
			case "jpeg":
				return "image/jpeg";
			case "gif":
				return "image/gif";
			default:
				return "application/octet-stream";
		}
	}

	/**
	 * Absolute path to the unpacked local docs bundle, or "" when there isn't
	 * one.
	 *
	 * The bundle is built by tools/build/scripts/build-docs.sh and unpacked
	 * under the CLI home as docs/<frameworkVersion>/. `wheels docs fetch`
	 * populates it, and the Homebrew formula stages it during install/upgrade.
	 * `docsBundlePath` overrides the location (used by the spec suite, and by
	 * anyone serving the bundle from somewhere else).
	 */
	public string function $docsBundleRoot() {
		var override = $get("docsBundlePath");
		if (IsSimpleValue(override) && Len(Trim(override))) {
			var trimmed = REReplace(Trim(override), "[/\\]+$", "");
			return DirectoryExists(trimmed) ? trimmed : "";
		}
		// Prefer a bundle mounted under the app's own webroot. It has to live
		// there for ASSETS to work at all: the dev server's Lucee urlRewrite
		// only routes extension-less paths to the front controller, so
		// extension-bearing URLs under /wheels/ never reach Wheels. Files under
		// the webroot are served by the container directly, and only the
		// extension-less page paths come through here.
		var webrootMount = ExpandPath("/wheels-docs");
		if (DirectoryExists(webrootMount) && FileExists(webrootMount & "/manifest.json")) {
			return webrootMount;
		}
		// Fall back to the shared cache that `wheels docs fetch` populates.
		// Pages serve from here; assets cannot (see above).
		var cliHome = env("LUCLI_HOME", "");
		if (!IsSimpleValue(cliHome) || !Len(Trim(cliHome))) {
			var userHome = env("HOME", "");
			if (!IsSimpleValue(userHome) || !Len(Trim(userHome))) {
				return "";
			}
			cliHome = userHome & "/.wheels";
		}
		var candidate = REReplace(Trim(cliHome), "[/\\]+$", "") & "/docs/" & application.wheels.version;
		return DirectoryExists(candidate) ? candidate : "";
	}

	/**
	 * Resolves a requested docs path to an absolute file inside the bundle.
	 *
	 * Mirrors $resolveDevAssetPath: reject traversal, backslashes, absolute
	 * paths and anything outside a conservative charset before touching the
	 * filesystem, then confirm with a canonical-prefix compare. Returns "" for
	 * anything that escapes the bundle or does not exist.
	 *
	 * The extension allowlist is intentionally wider than the dev-asset one
	 * because the bundle contains whole pages, the search index and fonts. It
	 * still excludes anything that could be executed — no .cfc, .cfm, .cfml.
	 */
	public string function $resolveDocsPath(required string site, required string requested) {
		if (arguments.site != "guides" && arguments.site != "api") {
			return "";
		}
		if (!Len(Trim(arguments.requested))) {
			return "";
		}
		if (
			Find("..", arguments.requested)
			|| Left(arguments.requested, 1) == "/"
			|| ReFind("[^A-Za-z0-9_\-./]", arguments.requested)
		) {
			return "";
		}
		if (
			!ListFindNoCase(
				"html,htm,css,js,json,map,xml,txt,wasm,woff,woff2,ttf,eot,svg,png,jpg,jpeg,gif,webp,avif,ico",
				ListLast(arguments.requested, ".")
			)
		) {
			return "";
		}
		var root = $docsBundleRoot();
		if (!Len(root)) {
			return "";
		}
		var siteDir = root & "/" & arguments.site;
		var target = siteDir & "/" & arguments.requested;
		try {
			var canonicalSite = CreateObject("java", "java.io.File").init(siteDir).getCanonicalPath();
			var canonicalTarget = CreateObject("java", "java.io.File").init(target).getCanonicalPath();
		} catch (any e) {
			return "";
		}
		var separator = CreateObject("java", "java.io.File").separator;
		if (Right(canonicalSite, 1) != separator) {
			canonicalSite &= separator;
		}
		if (CompareNoCase(Left(canonicalTarget, Len(canonicalSite)), canonicalSite) != 0) {
			return "";
		}
		return FileExists(canonicalTarget) ? canonicalTarget : "";
	}

	/**
	 * Serves a file from the local docs bundle, or returns false when there is
	 * no bundle / the path is not in it so the caller can fall back.
	 *
	 * Directory-style requests resolve to index.html, matching the static site
	 * Astro builds.
	 */
	private boolean function $serveDocsFile(required string site, string path = "") {
		var requested = Len(Trim(arguments.path)) ? Trim(arguments.path) : "index.html";
		if (Right(requested, 1) == "/") {
			requested &= "index.html";
		}
		// The app's urlrewrite.xml has a "Convert dot to format parameter" rule
		// that maps /foo/bar.css to /foo/bar?format=css, so for any asset with an
		// extension the filename arrives WITHOUT it and the extension shows up as
		// the format param. Re-attach it, but only for extensions we serve — a
		// genuine `?format=json` API call must not become a bogus filename.
		if (!Find(".", ListLast(requested, "/"))) {
			var fmt = StructKeyExists(request.wheels.params, "format") ? request.wheels.params.format : "";
			if (
				Len(fmt)
				&& ListFindNoCase("css,js,json,map,xml,txt,wasm,woff,woff2,ttf,eot,svg,png,jpg,jpeg,gif,webp,avif,ico", fmt)
			) {
				requested &= "." & fmt;
			}
		}
		var resolved = $resolveDocsPath(arguments.site, requested);
		if (!Len(resolved)) {
			return false;
		}
		var mime = $devAssetMimeType(resolved);
		// The bundle is content-addressed by framework version, so a file only
		// changes on upgrade — safe to cache hard, but not immutably, since the
		// directory is replaced in place rather than renamed.
		cfheader(name = "Cache-Control", value = "public, max-age=3600");
		cfheader(name = "Content-Type", value = mime);
		cffile(action = "readBinary", file = resolved, variable = "docsData");
		cfcontent(type = mime, variable = docsData);
		return true;
	}

	/**
	 * Rendered when a docs route is hit but no local bundle is installed, so
	 * the reader gets an actionable message instead of a bare 404. The bundle
	 * arrives with the CLI (Homebrew stages it on install/upgrade); a source
	 * checkout or a non-brew install needs `wheels docs fetch` once.
	 */
	private void function $docsUnavailable(required string site) {
		cfheader(statusCode = 404);
		// "API reference" is singular, "guides" is plural. The starter page links
		// straight here, so this is now a page users actually land on.
		var label = arguments.site == "api" ? "API reference" : "guides";
		var verb = arguments.site == "api" ? "is" : "are";
		WriteOutput(
			"<h1>Wheels " & label & " " & verb & " not available offline yet</h1>"
			& "<p>These pages are served from a local copy of the documentation so they work "
			& "with no internet connection, and that copy is not installed.</p>"
			& "<p>Run <code>wheels docs fetch</code> once to download it. Homebrew installs "
			& "stage it automatically on <code>brew install</code> / <code>brew upgrade</code>.</p>"
		);
	}


	/**
	 * Builds a versioned URL for a bundled dev-UI asset, served by the
	 * wheelsAssets route with immutable cache headers. The framework version
	 * works as the cache-buster because these assets only change with a
	 * framework upgrade. encode=false because the path segment contains
	 * literal slashes (values are hardcoded framework paths, never user
	 * input) — EncodeForURL would emit %2F, which servlet containers reject
	 * in paths by default. Lives on the component (not helpers.cfm) so the
	 * layout can call it from every Public.cfc include chain AND specs can
	 * call it on an instance.
	 */
	public string function devAssetUrl(required string relativePath) {
		return urlFor(
			route = "wheelsAssets",
			file = arguments.relativePath,
			params = "v=" & application.wheels.version,
			encode = false
		);
	}

	function mcp() {
		$blockInProduction();
		include "/wheels/public/views/mcp.cfm";
		return "";
	}

}
