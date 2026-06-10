/**
 * Wheels CLI Module for LuCLI
 *
 * Provides code generation, migrations, testing, and server management
 * for Wheels applications. Each public function is a subcommand:
 *
 *   wheels new myapp
 *   wheels create app myapp --port=3000
 *   wheels generate model User name email
 *   wheels migrate latest
 *   wheels test --filter=models
 *   wheels start
 *
 * hint: Wheels framework CLI - create, generate, migrate, test, and manage your app
 */
component extends="modules.BaseModule" {

	function init(
		boolean verboseEnabled = false,
		boolean timingEnabled = false,
		string cwd = "",
		any timer = nullValue(),
		struct moduleConfig = {}
	) {
		super.init(argumentCollection = arguments);

		// Normalize cwd to forward slashes. Lucee 7 on Windows fails to
		// distinguish a drive-letter path (e.g. `C:\Users\cy/blog`, where
		// the backslash came from `user.dir` and the forward slash from
		// `cwd & "/" & appName`) from a URI like `http:/...`. The mixed-
		// slash form trips ResourceUtil's scheme-detection regex, which
		// extracts "c" as the scheme and throws "no Resource provider
		// available with the name [c]" before any module code runs. All-
		// forward-slash paths are accepted by both Lucee and the JDK on
		// every platform, so we normalize once here and again on every
		// canonical-path concatenation downstream.
		variables.cwd = $normalizePath(variables.cwd);

		// Resolve project root (where lucee.json / vendor/wheels lives)
		variables.projectRoot = resolveProjectRoot(variables.cwd);

		// Module root for template resolution
		variables.moduleRoot = $normalizePath(getDirectoryFromPath(getCurrentTemplatePath()));

		// Lazy-init service instances
		variables.services = {};

		return this;
	}

	/**
	 * Bootstrap-safe wrapper around `Helpers.normalizePath()` — the single
	 * source of truth for path normalisation (GH #2841). Collapses Windows
	 * backslashes to forward slashes so a mixed-slash path like
	 * `C:\Users\cy/blog` can't trip Lucee's Resource API into reading `c:`
	 * as a URI scheme (see init() comment).
	 *
	 * Helpers is instantiated directly rather than via `getService()`
	 * because `$normalizePath()` runs inside `init()` before
	 * `variables.services` exists. Helpers is a dependency-free leaf
	 * utility, so constructing it at bootstrap is cheap and safe.
	 */
	private string function $normalizePath(required string p) {
		return new services.Helpers().normalizePath(arguments.p);
	}

	/**
	 * Java-backed directoryExists() — bypasses Lucee's path resolver so
	 * paths starting with a Windows drive letter (`C:\…`) never reach
	 * ResourceUtil's scheme detection. The defensive `try/catch` honors
	 * Lucee's built-in first (in case mappings or symlinks matter) and
	 * only falls back to `java.io.File.isDirectory()` when Lucee throws.
	 *
	 * Use this in any path-existence check that runs early in `wheels
	 * new` (before the framework source is located) or in any code that
	 * constructs paths from `variables.cwd` / `File.getCanonicalPath()`.
	 */
	private boolean function $safeDirExists(required string p) {
		try {
			return directoryExists(arguments.p);
		} catch (any e) {
			return createObject("java", "java.io.File").init(arguments.p).isDirectory();
		}
	}

	/**
	 * Source the structured argument collection LuCLI handed this command.
	 *
	 * LuCLI parses the command line once and invokes the subcommand as
	 * `module.cmd(argumentCollection = argsMap)`, so the function's `arguments`
	 * scope already IS the structured map (positionals as `arg1..argN`, named
	 * options as `key=value`, and `--no-X` normalized to `key=false`). Commands
	 * migrated to ArgSpec consume that directly — no flatten to argv, no
	 * re-parse, no lossy `false` round trip (the #2855 root cause, see #2861).
	 *
	 * The fallback covers direct invocation where a caller stashed a raw argv
	 * array in the instance-level `__arguments` (internal delegation such as
	 * `create` → `new`, and unit tests). That array is reconstructed into the
	 * same structured shape LuCLI would have produced, so a command behaves
	 * identically whether LuCLI dispatched it or another command delegated to it.
	 */
	private struct function structuredArgs(struct callerArgs = {}) {
		if (!structIsEmpty(arguments.callerArgs)) {
			return arguments.callerArgs;
		}
		var raw = __arguments ?: [];
		return argvToCollection(isArray(raw) ? raw : []);
	}

	/**
	 * Reconstruct LuCLI's structured argCollection from a raw argv array.
	 *
	 * Mirrors LuCLI's own `parseArguments()` normalization so the fallback path
	 * is indistinguishable from a live dispatch: `--no-X` → `X=false`, bare
	 * `--X` → `X=true`, `--key=value` → `key=value` (leading dashes stripped),
	 * and bare tokens → `arg<n>` keyed by their global position (a flag between
	 * two positionals leaves a numbering gap, exactly as LuCLI produces).
	 */
	private struct function argvToCollection(required array argv) {
		var coll = {};
		var count = 0;
		for (var raw in arguments.argv) {
			count++;
			if (left(raw, 5) == "--no-" && !find("=", raw) && len(raw) > 5) {
				coll[mid(raw, 6, len(raw))] = "false";
			} else if (left(raw, 2) == "--" && !find("=", raw) && len(raw) > 2) {
				coll[mid(raw, 3, len(raw))] = "true";
			} else {
				var eq = find("=", raw);
				if (eq > 1) {
					var key = trim(left(raw, eq - 1));
					if (left(key, 2) == "--") {
						key = mid(key, 3, len(key));
					} else if (left(key, 1) == "-") {
						key = mid(key, 2, len(key));
					}
					coll[key] = mid(raw, eq + 1, len(raw));
				} else {
					coll["arg" & count] = raw;
				}
			}
		}
		return coll;
	}

	// ─────────────────────────────────────────────────
	//  MCP framework convention — hide CLI-only commands
	// ─────────────────────────────────────────────────

	/**
	 * hint: Declare public functions to hide from MCP tools/list.
	 *
	 * These remain reachable as CLI subcommands. Hidden because they are
	 * stateful (start/stop), destructive (new scaffolds a whole project),
	 * interactive (console), meta (mcp), alias (d), or don't translate to
	 * single-call MCP semantics (browser). Read by LuCLI >= 0.3.4 per the
	 * mcpHiddenTools() convention.
	 */
	public array function mcpHiddenTools() {
		return [
			"main",     // bare `wheels` no-args dispatch target — not an MCP tool
			"mcp",      // meta command — prints MCP setup instructions
			"d",        // alias for destroy
			"g",        // alias for generate
			"new",      // scaffolds a whole new Wheels project
			"console",  // interactive CFML REPL — not usable over stdio
			"start",    // dev server lifecycle (stateful)
			"stop",     // dev server lifecycle (stateful)
			"browser",  // multi-step browser testing flow
			// $-prefixed internal helpers. Public ONLY so TestCommandSpec can
			// unit-test them directly (the cli/CLAUDE.md "public for specs"
			// carve-out) — they are not commands and must never surface as MCP
			// tools. LuCLI matches these case-insensitively (McpCommand lowercases
			// both the entry and the discovered function name).
			"$normalizeTestFilter",
			"$resolveAppTestDataSource"
		];
	}

	// ─────────────────────────────────────────────────
	//  version / help — banner + command listing
	// ─────────────────────────────────────────────────

	// Emits the three-line `wheels --version` format the installation guide
	// documents (Wheels Module + LuCLI runtime + JVM). See
	// web/sites/guides/.../command-line-tools/installation.mdx for the
	// canonical output shape; issue #2431 tracked the prior banner output
	// drifting from the doc.
	/**
	 * hint: Show Wheels Module, LuCLI runtime, and JVM versions
	 */
	public string function version() {
		var nl = chr(10);
		var moduleVersion = super.version();
		var channel = new services.ReleaseChannel().classify(moduleVersion);
		var channelTag = len(channel) ? " (" & channel & ")" : "";

		var lines = ["Wheels " & moduleVersion & channelTag];

		var lucliVersion = $detectLucliVersion();
		if (len(lucliVersion)) {
			arrayAppend(lines, "LuCLI " & lucliVersion);
		}

		var javaVersion = $detectJavaVersion();
		if (len(javaVersion)) {
			arrayAppend(lines, "Java " & javaVersion);
		}

		return arrayToList(lines, nl);
	}

	private string function $detectLucliVersion() {
		try {
			var sys = createObject("java", "java.lang.System");
			var v = sys.getProperty("lucli.version");
			if (!isNull(v) && len(v)) {
				return v;
			}
			v = sys.getenv("LUCLI_VERSION");
			if (!isNull(v) && len(v)) {
				return v;
			}
		} catch (any e) {
			// fall through
		}
		return "";
	}

	private string function $detectJavaVersion() {
		try {
			var sys = createObject("java", "java.lang.System");
			var v = sys.getProperty("java.version");
			if (!isNull(v) && len(v)) {
				return v;
			}
		} catch (any e) {
			// fall through
		}
		return "";
	}

	// LuCLI dispatches a bare `wheels` invocation (no subcommand) to a
	// `main()` function on the module. Without it, picocli surfaces:
	//   Component [modules.wheels.Module] has no function with name [main]
	// Delegate to showHelp() so the no-args entry point lands on something useful.
	/**
	 * hint: No-args dispatch target — delegates to showHelp()
	 */
	public string function main() {
		return showHelp();
	}

	// Hand-written replacement for BaseModule's auto-discovered help. Grouped by
	// task instead of alphabetical, mirrors what `wheels --help` emits from the
	// wrapper. `wheels help` and `wheels --help` (rewritten by LuCLI's
	// preprocessModuleHelp) both reach this.
	/**
	 * hint: Show this help
	 */
	public string function showHelp() {
		var nl = chr(10);

		// Per-subcommand help. LuCLI (>= bpamiri/LuCLI#5) forwards
		// `wheels <cmd> --help` as `showHelp <cmd>`, which arrives as the raw
		// __arguments argv (`arg1`) — the same dispatch every other command uses.
		// Read `arg1` first; fall back to the CFML positional key "1" so a direct
		// function invocation (showHelp("migrate")) also resolves it. Unknown
		// commands fall through to the global listing below (also the bare
		// `wheels help` / `wheels --help` path, where there is no subcommand).
		var coll = structuredArgs(arguments);
		var sub = coll.arg1 ?: (coll["1"] ?: "");
		if (len(sub)) {
			var cmdHelp = $commandHelp(sub);
			if (len(cmdHelp)) {
				return cmdHelp;
			}
		}

		var v = super.version();
		var help = "Wheels CLI " & v & nl;
		help &= "  CFML MVC framework — code generation, migrations, testing, server management" & nl & nl;
		help &= "Usage:" & nl;
		help &= "  wheels <command> [options]" & nl & nl;
		help &= "Getting Started:" & nl;
		help &= "  new <name>          Scaffold a new Wheels application" & nl;
		help &= "  create app <name>   Alias for new — scaffold a new Wheels application" & nl;
		help &= "  start               Start the dev server" & nl;
		help &= "  stop                Stop the dev server" & nl;
		help &= "  reload              Reload the running app" & nl & nl;
		help &= "Code Generation:" & nl;
		help &= "  generate            Generate model, controller, scaffold, migration, etc." & nl;
		help &= "  destroy (or d)      Remove generated files" & nl & nl;
		help &= "Database:" & nl;
		help &= "  migrate             Run database migrations (latest, up, down, info, doctor, forget, pretend, rename-system-tables)" & nl;
		help &= "  seed                Run database seeds" & nl;
		help &= "  db                  Database management (reset, status, version)" & nl & nl;
		help &= "Testing & Inspection:" & nl;
		help &= "  test                Run the test suite" & nl;
		help &= "  browser             Browser-based tests (Playwright)" & nl;
		help &= "  console             Open an interactive CFML REPL connected to your app" & nl;
		help &= "  routes              Print the route table" & nl;
		help &= "  info                Show framework version, environment, configuration" & nl;
		help &= "  doctor              Diagnose project setup issues" & nl;
		help &= "  validate            Validate project structure and configuration" & nl;
		help &= "  analyze             Static analysis of project code" & nl;
		help &= "  stats               Project statistics (lines of code, model counts, etc.)" & nl;
		help &= "  notes               Find TODO / FIXME / OPTIMIZE comments (--annotations to customize)" & nl & nl;
		help &= "Packages & Deployment:" & nl;
		help &= "  packages            Add, update, search Wheels packages (verb is `add`, not `install`)" & nl;
		help &= "  upgrade             Scan for breaking changes before upgrading Wheels (read-only)" & nl;
		help &= "  deploy              Deploy your app (Kamal-compatible)" & nl & nl;
		help &= "Other:" & nl;
		help &= "  mcp                 Configure Wheels MCP server for AI assistants" & nl;
		help &= "  version             Show Wheels CLI version" & nl;
		help &= "  help                Show this help" & nl & nl;
		help &= "For command-specific help: wheels <command> --help" & nl & nl;
		help &= "More info: https://guides.wheels.dev";
		return help;
	}

	/**
	 * Render per-command help for `wheels <cmd> --help` from the command function's
	 * metadata hint. Returns "" for an unknown command so showHelp() falls back to
	 * the global listing. Private so it isn't exposed as an MCP tool.
	 */
	private string function $commandHelp(required string subcommand) {
		var nl = chr(10);
		// Resolve aliases to the implementing function.
		var fnName = lCase(trim(arguments.subcommand));
		if (fnName == "g") { fnName = "generate"; }
		if (fnName == "d") { fnName = "destroy"; }

		var hint = "";
		var meta = getMetaData(this);
		for (var fn in (meta.functions ?: [])) {
			if (lCase(fn.name ?: "") == fnName && (fn.access ?: "public") == "public") {
				hint = trim(fn.hint ?: "");
				// The `/** hint: ... */` convention surfaces the value with the
				// literal "hint:" key prefix on Lucee — strip it for clean output.
				hint = trim(reReplaceNoCase(hint, "^hint\s*:\s*", ""));
				break;
			}
		}
		if (!len(hint)) {
			return "";
		}

		var help = "wheels " & lCase(trim(arguments.subcommand)) & nl & nl;
		help &= "  " & hint & nl & nl;
		help &= "Run 'wheels help' for the full command list." & nl;
		help &= "More info: https://guides.wheels.dev";
		return help;
	}

	// ─────────────────────────────────────────────────
	//  generate — Code generation
	// ─────────────────────────────────────────────────

	/**
	 * hint: Generate Wheels components (model, controller, view, migration, scaffold, route, test, property, api-resource, helper, snippets)
	 */
	public string function generate() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));

		if (!arrayLen(args)) {
			out("Usage: wheels generate <type> <name> [attributes...]", "yellow");
			out("");
			out("Types:", "bold");
			out("  app           Create a new Wheels application (alias for 'wheels new')");
			out("  model         Generate a model CFC");
			out("  controller    Generate a controller CFC");
			out("  view          Generate a view template");
			out("  migration     Generate a database migration");
			out("  scaffold      Generate model + controller + views + migration + tests + routes");
			out("  api-resource  Generate API-only model + controller + migration + tests + routes (no views)");
			out("  route         Add a resource route to config/routes.cfm");
			out("  test          Generate a test spec file");
			out("  property      Generate an add-column migration for a model property");
			out("  helper        Generate a helper file in app/helpers/");
			out("  snippets      Generate common code pattern snippets (auth, soft-delete, api, etc.)");
			out("  admin         Generate admin CRUD interface for an existing model");
			out("");
			out("Examples:", "bold");
			out("  wheels generate app myapp");
			out("  wheels generate model User name email:string active:boolean");
			out("  wheels generate controller Users index show create");
			out("  wheels generate migration CreateUsers");
			out("  wheels generate scaffold Post title body:text publishedAt:datetime");
			out("  wheels generate api-resource Product name price:decimal sku:string");
			out("  wheels generate route posts");
			out("  wheels generate test model User");
			out("  wheels generate property User email:string");
			out("  wheels generate helper formatting");
			out("  wheels generate snippets auth");
			out("  wheels generate admin User");
			return "";
		}

		var type = args[1];
		var remaining = args.len() > 1 ? args.slice(2) : [];

		switch (lCase(type)) {
			case "app":
			case "a":
				// Delegate to wheels new — pass remaining args as __arguments
				__arguments = remaining;
				return new();
			case "model":
			case "m":
				return generateModel(remaining);
			case "controller":
			case "c":
				return generateController(remaining);
			case "view":
			case "v":
				return generateView(remaining);
			case "migration":
			case "migrate":
				return generateMigration(remaining);
			case "scaffold":
			case "s":
				return generateScaffold(remaining);
			case "api-resource":
			case "api":
				return generateApiResource(remaining);
			case "route":
			case "r":
				return generateRoute(remaining);
			case "test":
				return generateTest(remaining);
			case "property":
			case "prop":
				return generateProperty(remaining);
			case "helper":
			case "h":
				return generateHelper(remaining);
			case "snippets":
				return generateSnippets(remaining);
			case "admin":
				return generateAdmin(remaining);
			default:
				out("Unknown generator type: #type#", "red");
				out("Run 'wheels generate' for available types.");
				// throw maps to non-zero exit; return "" would silently succeed.
				throw(type = "Wheels.InvalidArguments", message = "Unknown generator type: #type#");
		}
	}

	// ─────────────────────────────────────────────────
	//  migrate — Database migration management
	// ─────────────────────────────────────────────────

	/**
	 * hint: Run database migrations (latest, up, down, info, doctor, forget, pretend, rename-system-tables)
	 */
	public string function migrate() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));
		var action = arrayLen(args) ? lCase(args[1]) : "latest";

		switch (action) {
			case "latest":
			case "up":
			case "down":
			case "info":
				try {
					return runMigration(action);
				} catch (MigrationError e) {
					out("Migration failed: #e.message#", "red");
					// rethrow maps to non-zero exit; return "" would silently succeed.
					rethrow;
				}
			case "doctor":
				try {
					return runMigration("doctor");
				} catch (MigrationError e) {
					out("Doctor failed: #e.message#", "red");
					rethrow;
				}
			case "forget":
				return runForgetOrPretend("forgetVersion", args);
			case "pretend":
				return runForgetOrPretend("pretendVersion", args);
			case "rename-system-tables":
				// F15 Phase 2: opt-in one-shot rename of legacy c_o_r_e_*
				// system tables to wheels_*. Idempotent (no-op when nothing
				// to rename); refuses to run on a partial-rename state.
				var dryRun = false;
				for (var i = 2; i <= arrayLen(args); i++) {
					if (args[i] == "--dry-run") dryRun = true;
				}
				try {
					return runRenameSystemTables(dryRun);
				} catch (MigrationError e) {
					out("Rename failed: #e.message#", "red");
					rethrow;
				}
			default:
				out("Unknown migration action: #action#", "red");
				out("Usage: wheels migrate [latest|up|down|info|doctor|forget|pretend|rename-system-tables]");
				throw(type = "Wheels.InvalidArguments", message = "Unknown migration action: #action#");
		}
	}

	// ─────────────────────────────────────────────────
	//  seed — Database seeding
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels seed` arguments. All options are named (no positional), so
	 * before the ArgSpec migration the legacy getArgs() arg1-gate dropped them
	 * entirely — `wheels seed --environment=production` silently ran with
	 * defaults. ArgSpec consumes the named keys directly. `--generate` is a
	 * shorthand for `--mode=generate`.
	 */
	private struct function parseSeedArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.option(name = "environment", default = "")
			.option(name = "mode", default = "auto")
			.flag(name = "generate", default = false)
			.parse(arguments.coll);
		return {
			environment = parsed.environment,
			mode = parsed.generate ? "generate" : parsed.mode
		};
	}

	/**
	 * hint: Run database seeds (convention-based or generated)
	 */
	public string function seed() {
		var opts = parseSeedArgs(structuredArgs(arguments));
		return runSeed(opts.mode, opts.environment);
	}

	// ─────────────────────────────────────────────────
	//  test — Run test suite
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels test` arguments. `--filter` and its `--directory` alias set
	 * the spec filter; `--reporter` and `--db` are options (`--db` is also tracked
	 * as explicit so the runner can tell an implicit default from a chosen one);
	 * `--verbose`/`--ci`/`--core` are flags; `--no-test-db` (test-db=false) maps to
	 * useTestDB. A bare positional is the filter, and `-v` arrives as a positional
	 * (LuCLI only normalizes --x/--no-x) and toggles verbose. The space-separated
	 * option forms (`--filter x`) are dropped for `--filter=x` — LuCLI delivers the
	 * space form as a bare flag + a separate positional, not a named value (#2861).
	 */
	private struct function parseTestArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.option(name = "filter",    default = "")
			.option(name = "directory", default = "")
			.option(name = "reporter",  default = "simple")
			.option(name = "db",        default = "sqlite")
			.flag(name = "verbose", default = false)
			.flag(name = "ci",      default = false)
			.flag(name = "core",    default = false)
			.flag(name = "test-db", default = true)
			.parse(arguments.coll);

		// `--directory` is a documented alias for `--filter` (tutorial ch. 7).
		var filter = len(parsed.directory) ? parsed.directory : parsed.filter;

		// Walk positionals in LuCLI's global-index order: `-v` is the short
		// verbose flag (delivered as a positional, not normalized), and the
		// first remaining bare token is the filter when no --filter/--directory
		// option was supplied.
		var verbose = parsed.verbose;
		var indices = [];
		for (var key in arguments.coll) {
			if (reFindNoCase("^arg\d+$", key)) {
				arrayAppend(indices, val(mid(key, 4, len(key))));
			}
		}
		arraySort(indices, "numeric");
		for (var idx in indices) {
			var token = trim(arguments.coll["arg" & idx]);
			if (token == "-v") {
				verbose = true;
			} else if (len(token) && left(token, 2) != "--" && !len(filter)) {
				filter = token;
			}
		}

		return {
			filter = filter,
			reporter = parsed.reporter,
			format = "json",
			verbose = verbose,
			ci = parsed.ci,
			core = parsed.core,
			db = parsed.db,
			dbExplicit = structKeyExists(arguments.coll, "db"),
			useTestDB = parsed["test-db"]
		};
	}

	/**
	 * hint: Run test suite with optional filter and reporter
	 */
	public string function test() {
		var opts = parseTestArgs(structuredArgs(arguments));
		var filter = opts.filter;
		var reporter = opts.reporter;
		var format = opts.format;
		var verboseOutput = opts.verbose;
		var ciMode = opts.ci;
		var coreTests = opts.core;
		var db = opts.db;
		var dbExplicit = opts.dbExplicit;
		var useTestDB = opts.useTestDB;

		// Default to APP mode unless --core is set explicitly. The previous
		// auto-detection ("if vendor/wheels/tests/ exists, default to core")
		// always picked core mode for user apps because every Wheels app has
		// the framework's tests vendored at vendor/wheels/tests/. That meant
		// `wheels test` from a user's app pointed at framework specs instead
		// of the user's own tests/specs/, producing "0 passed" silently with
		// no spec discovery.

		// Normalize short filter names to dotted paths the test runner
		// accepts. The app-runner regex (`^tests(\.[a-zA-Z0-9_]+)*$`) and
		// core-runner regex (`^(wheels\.tests|vendor\.<pkg>\.tests)...$`)
		// both reject bare names like "browser" or "models" and silently
		// fall back to the default scope, running the entire suite. The
		// CLI normalizes here so `--filter=browser` does what the user
		// expects. Onboarding finding #2.
		filter = $normalizeTestFilter(filter, coreTests);

		return runTests(filter, reporter, format, verboseOutput, coreTests, db, ciMode, useTestDB, dbExplicit);
	}

	/**
	 * Normalize a short filter name to a path the test runner's directory
	 * regex will accept. App mode prepends `tests.specs.`; core mode
	 * prepends `wheels.tests.specs.`. Already-qualified inputs pass through
	 * unchanged. Empty input stays empty (server applies its default).
	 *
	 * Examples:
	 *   "" → ""                                      (default scope)
	 *   "browser" → "tests.specs.browser"            (app mode)
	 *   "browser" → "wheels.tests.specs.browser"     (core mode)
	 *   "tests.specs.browser" → "tests.specs.browser"
	 *   "wheels.tests.specs.model" → "wheels.tests.specs.model"
	 *   "vendor.wheels-sentry.tests" → "vendor.wheels-sentry.tests"
	 */
	public string function $normalizeTestFilter(
		required string filter,
		boolean coreTests = false
	) {
		var f = trim(arguments.filter);
		if (!len(f)) return "";

		if (arguments.coreTests) {
			// Core runner accepts wheels.tests.* or vendor.<pkg>.tests.*
			if (reFindNoCase("^(wheels\.tests|vendor\.[a-z0-9][a-z0-9\-]*\.tests)(\.[a-zA-Z0-9_]+)*$", f)) {
				return f;
			}
			return "wheels.tests.specs." & f;
		}

		// App runner accepts tests.* (and treats `tests` alone as a valid root)
		if (reFindNoCase("^tests(\.[a-zA-Z0-9_]+)*$", f)) {
			return f;
		}
		return "tests.specs." & f;
	}

	// ─────────────────────────────────────────────────
	//  reload — Reload application
	// ─────────────────────────────────────────────────

	/**
	 * hint: Reload the running Wheels application. The reload password
	 * gates the HTTP `?reload=true` endpoint against remote attackers;
	 * the CLI reads it from `.env` or `config/settings.cfm` and forwards
	 * it because it runs locally with filesystem access. This matches
	 * how Rails, Laravel, Symfony, etc. treat CLI-vs-HTTP — the CLI is
	 * already trusted at the same level as the project on disk. See
	 * issue #2477 and `deployment/security-hardening.mdx`.
	 */
	public string function reload() {
		// Write-side guard: reload mutates the running app's state, so it must
		// target the server bound to THIS project — never a sibling app squatting
		// a common port. Without lucee.json/.env port config we refuse the
		// common-port fallback and error loudly.
		var serverPort = $requireRunningServer(
			hints = [
				"Reload requires a running server bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			],
			requireProjectConfig = true
		);

		// Auto-detect the reload password from .env / config, but let an explicit
		// `--password=<value>` override it (parity with `wheels console`). The
		// auto-detect default is unchanged when no flag is given.
		var reloadOpts = parseConsoleArgs(structuredArgs(arguments));
		var password = len(reloadOpts.password) ? reloadOpts.password : detectReloadPassword();

		// F5 fix: physically wipe the Lucee compiled-class cache before
		// triggering the framework reload. Lucee Express's default
		// `inspectTemplate=once` means Lucee compiles each CFC once, caches
		// the .class on disk, and never re-checks the source timestamp.
		// `?reload=true` resets Wheels application state via applicationStop()
		// but does not invalidate Lucee's template cache, so edits to models,
		// controllers, and config silently miss until cfclasses is wiped.
		// See onboarding finding F5.
		$purgeServerCfclasses();

		try {
			var reloadUrl = "http://localhost:#serverPort#/?reload=true&password=#password#";
			var httpResult = makeHttpRequest(reloadUrl);
			out("Application reloaded successfully.", "green");
			// Surface the hot-vs-cold reload contract — Wheels does NOT
			// re-fire onApplicationStart on `?reload=true`. Users editing
			// app/events/onapplicationstart.cfm or config/services.cfm need
			// a full restart. See finding #8 in the 2026-04-29 fresh-VM
			// triage.
			out("Note: onApplicationStart does NOT re-fire. For init-code edits, run `wheels stop && wheels start`.", "cyan");
			verbose("URL: http://localhost:#serverPort#/?reload=true&password=***");
		} catch (any e) {
			out("Failed to reload: #e.message#", "red");
			if (!len(password)) {
				out("Hint: Set WHEELS_RELOAD_PASSWORD in .env or config/settings.cfm", "yellow");
			}
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  start / stop — Dev server management
	// ─────────────────────────────────────────────────

	/**
	 * hint: Start the Wheels development server via LuCLI
	 */
	public string function start() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));

		// Refuse to start from a non-Wheels-project directory. LuCLI's
		// `server start` derives the server name from the cwd basename and
		// silently registers a new context — running `wheels start` in the
		// wrong directory leaves orphan registrations like `ws` or
		// `Downloads`. Onboarding finding F6.
		if (!$isWheelsProjectDir(variables.projectRoot)) {
			out("This directory does not look like a Wheels project.", "yellow");
			out("  Expected: config/settings.cfm under the current directory.", "yellow");
			out("");
			out("Tip: cd into your project directory, or run `wheels new <appname>`", "cyan");
			out("     to scaffold one.", "cyan");
			return "";
		}

		// Detect a stale `<lucliHome>/servers/<basename>/` registration before
		// delegating to LuCLI. Without this intercept, LuCLI emits a numbered
		// recovery prompt referencing `lucli server start --force`, but `lucli`
		// isn't on PATH after `brew install wheels` — the user gets an
		// unactionable error from a fresh `wheels start`. Onboarding F1/F2.
		var force = false;
		var passThrough = [];
		for (var a in args) {
			if (a == "--force") { force = true; }
			else { arrayAppend(passThrough, a); }
		}
		var registry = getService("serverRegistry");
		var serverName = registry.serverNameFor(variables.projectRoot);
		var reg = registry.inspect(serverName, variables.projectRoot);

		if (reg.alive) {
			out("Server '" & serverName & "' is already running.", "yellow");
			out("To restart: wheels stop && wheels start", "cyan");
			return "";
		}

		if (reg.exists && !reg.ours && !force) {
			out("");
			out("Server name '" & serverName & "' is registered to a different project:", "yellow");
			out("  registered: " & (len(reg.registeredPath) ? reg.registeredPath : "<unknown>"), "yellow");
			out("  this dir:   " & variables.projectRoot, "yellow");
			out("");
			out("Options:", "bold");
			out("  - Pass --force to replace the registration:");
			out("      wheels start --force", "cyan");
			out("  - Or rename your project directory so it gets a unique server name.");
			return "";
		}

		// Stale-but-ours, or --force was passed: wipe the dead registration so
		// LuCLI's `server start` doesn't trip its "already exists" prompt.
		if (reg.exists) {
			registry.clean(serverName);
		}

		// Defense in depth for the IPv4-blind port check. LuCLI's own
		// LuceeServerConfig.isPortAvailable() probes with a wildcard ServerSocket
		// that binds IPv6 on a dual-stack JVM, so it never sees a port held by an
		// IPv4-only listener (python http.server, Django runserver on 8000,
		// 127.0.0.1-bound databases) and `wheels start` would boot on top of it.
		// That is fixed upstream, but older LuCLI binaries still ship the bug, so
		// when lucee.json pins a port we connect-probe it (both address families)
		// and warn before delegating. We only reach here when our own server is
		// NOT already running (the reg.alive early-return above), so an in-use
		// pinned port is a genuine foreign collision.
		var pinnedPort = $readPinnedPort(variables.projectRoot);
		if (pinnedPort > 0 && getService("portProbe").portInUse(pinnedPort)) {
			out("");
			out("Warning: port " & pinnedPort & " (configured in lucee.json) is already in use", "yellow");
			out("by another process. The server may fail to start, or silently share the port", "yellow");
			out("(IPv4 clients reaching the other process while localhost reaches Wheels).", "yellow");
			out("Fix: stop the other process, or change the 'port' in lucee.json.", "yellow");
			out("");
		}

		out("Starting Wheels server...", "cyan");

		// Stage required JDBC drivers into the Lucee Express lib/ext/ before
		// LuCLI provisions/boots Lucee. Without this, fresh `wheels new` apps
		// with the SQLite-by-default datasource hit a class-load failure on
		// the first request because the Lucee Express distribution doesn't
		// ship the SQLite driver and not every install path (chocolatey,
		// dev checkout, manual) drops the JAR via a wrapper script. See
		// GH #2326 (F8). Pre-stage (this call) covers the first-start case
		// where the express dir already exists; post-stage (after server
		// start, below) covers the case where express was extracted by this
		// very LuCLI invocation.
		$ensureWheelsBundles();

		// Drop a working rewrite.config at the project root if the project
		// doesn't already ship one. LuCLI's bundled default uses a narrow
		// allow-list and negated RewriteCond chains that 404 static assets
		// for 3.x-conventional dirs (/miscellaneous/, /javascripts/, etc.);
		// providing a project override sidesteps it. New apps get this file
		// via `wheels new`; this catches 3.x → 4.0 upgrade paths. See GH #2626.
		$ensureProjectRewriteConfig();

		// Delegate to LuCLI's server start command. Forward only args we
		// haven't consumed ourselves (--force is wheels-side, not LuCLI-side).
		var cmdArgs = ["start"];
		cmdArgs.append(passThrough, true);

		executeCommand("server", cmdArgs, variables.projectRoot);

		// Post-stage. If the express dir didn't exist at pre-stage time
		// (very first LuCLI run on a fresh VM), the start command above just
		// extracted it. Seed the JAR now so the *next* `wheels start` works
		// zero-config without the user knowing the difference.
		$ensureWheelsBundles();

		return "";
	}

	/**
	 * hint: Stop the running Wheels development server
	 */
	public string function stop() {
		out("Stopping Wheels server...", "cyan");

		// If LuCLI's stop won't find a registered server for this directory
		// (cwd doesn't match any `.project-path`), enumerate the user's
		// running servers and offer specific stop commands. Without this,
		// `wheels stop` is silently a no-op when run from a parent dir, an
		// unrelated dir, or after the project was moved/deleted — leaving
		// orphan Java processes the user has to chase with `lsof`+`kill`.
		// See GH #2316.
		var match = $findServerForProject(variables.projectRoot);
		if (!len(match)) {
			var orphans = $listRunningWheelsServers();
			if (arrayLen(orphans)) {
				out("");
				out("No registered server matches this directory.", "yellow");
				out("Running Wheels servers:", "yellow");
				for (var s in orphans) {
					out("  - " & s.name & " (port " & s.port & ", project " & s.projectPath & ")");
				}
				out("");
				out("To stop a specific server: wheels server stop --name <name>", "cyan");
				out("To list all servers:      wheels server list", "cyan");
				return "";
			}

			// Final fallback: scan live JVMs for processes whose catalina.base
			// points into this user's LuCLI servers tree but whose registration
			// was wiped (`rm -rf ~/.wheels/servers/<name>` is the user's only
			// recovery from the F1/F2 stale-server prompt; it leaves the
			// process orphaned). Without this scan, `wheels stop` falsely
			// claims "no server is running" while the port is still held.
			// Onboarding F3.
			var stranded = $findStrandedLuceeProcesses();
			if (arrayLen(stranded)) {
				out("");
				out("Found Lucee processes from prior sessions (LuCLI registration is gone):", "yellow");
				var pids = [];
				for (var p in stranded) {
					out("  - PID " & p.pid & " (was server '" & p.serverName & "')");
					arrayAppend(pids, p.pid);
				}
				out("");
				out("To stop them: kill " & arrayToList(pids, " "), "cyan");
				return "";
			}

			// No registered server AND no others running. Don't fall through
			// to LuCLI's `server stop` — it would create a phantom server
			// registration named after the cwd basename. Onboarding finding F6.
			out("");
			out("No Wheels server is registered for this directory, and none are running elsewhere.", "yellow");
			if (!$isWheelsProjectDir(variables.projectRoot)) {
				out("Tip: run this from inside your Wheels project directory.", "cyan");
			}
			return "";
		}

		executeCommand("server", ["stop"], variables.projectRoot);
		return "";
	}

	// ─────────────────────────────────────────────────
	//  new — Scaffold a new Wheels project
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels new` arguments from LuCLI's structured argCollection.
	 *
	 * `--no-sqlite` arrives as `sqlite=false`; the command's `noSQLite` flag is
	 * its inverse ("skip the default SQLite setup"). `--no-open-browser` arrives
	 * as `open-browser=false`. Returns the resolved options plus `isEmpty` so
	 * the command can distinguish "no args → show usage" from "args but no app
	 * name → error" (GH #2214).
	 */
	private struct function parseNewArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.positional(name = "appName")
			.option(name = "port", default = 8080, type = "numeric")
			.option(name = "datasource", default = "")
			.option(name = "reload-password", default = "")
			.flag(name = "setup-h2", default = false)
			.flag(name = "sqlite", default = true)
			.flag(name = "open-browser", default = true)
			.parse(arguments.coll);

		return {
			appName = parsed.appName,
			port = parsed.port,
			datasource = parsed.datasource,
			reloadPassword = parsed["reload-password"],
			setupH2 = parsed["setup-h2"],
			noSQLite = !parsed.sqlite,
			openBrowser = parsed["open-browser"],
			isEmpty = structIsEmpty(arguments.coll)
		};
	}

	/**
	 * hint: Scaffold a new Wheels project directory
	 */
	public string function new() {
		var opts = parseNewArgs(structuredArgs(arguments));

		if (opts.isEmpty) {
			out("Usage: wheels new <appname> [options]", "yellow");
			out("");
			out("Creates a new Wheels application in the specified directory.");
			out("By default, SQLite is configured as the zero-config database.");
			out("");
			out("Options:", "bold");
			out("  --port=<number>           Server port (default: 8080)");
			out("  --datasource=<name>       Datasource name (default: app name)");
			out("  --reload-password=<pw>    Reload password (default: random)");
			out("  --no-sqlite               Skip default SQLite database setup");
			out("  --setup-h2                Use H2 embedded database instead of SQLite");
			out("  --no-open-browser         Don't open browser on server start");
			out("");
			out("Examples:", "bold");
			out("  wheels new myapp");
			out("  wheels new myapp --port=3000 --setup-h2");
			out("  wheels new myapp --datasource=mydb --no-sqlite");
			return "";
		}

		var appName = opts.appName;
		var options = {
			port: opts.port,
			datasource: opts.datasource,
			reloadPassword: opts.reloadPassword,
			setupH2: opts.setupH2,
			noSQLite: opts.noSQLite,
			openBrowser: opts.openBrowser
		};

		if (!len(appName)) {
			out("Error: app name is required.", "red");
			out("Usage: wheels new <appname>");
			// Args were supplied (the empty branch above already returned usage
			// help) but none parsed as an app name — e.g. `wheels new
			// --port=3000`. Throw so LuCLI surfaces a non-zero exit (GH #2214).
			throw(
				type="Wheels.InvalidArguments",
				message="wheels new: app name argument is required"
			);
		}

		// Default datasource to app name, generate random reload password
		if (!len(options.datasource)) options.datasource = lCase(appName);
		if (!len(options.reloadPassword)) options.reloadPassword = generateRandomPassword();

		return scaffoldNewApp(appName, options);
	}

	// ─────────────────────────────────────────────────
	//  create — Create application components
	// ─────────────────────────────────────────────────

	/**
	 * hint: Create application components (wheels create app <name> [options])
	 */
	public string function create() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));

		if (!arrayLen(args)) {
			out("Usage: wheels create <type> <name> [options]", "yellow");
			out("");
			out("Types:", "bold");
			out("  app    Create a new Wheels application");
			out("");
			out("Examples:", "bold");
			out("  wheels create app myapp");
			out("  wheels create app myapp --port=3000 --setup-h2");
			return "";
		}

		var type = lCase(args[1]);
		var remaining = args.len() > 1 ? args.slice(2) : [];

		switch (type) {
			case "app":
				__arguments = remaining;
				return new();
			default:
				out("Unknown create type: #type#", "red");
				out("Run 'wheels create' for available types.");
				throw(type = "Wheels.InvalidArguments", message = "Unknown create type: #type#");
		}
	}

	// ─────────────────────────────────────────────────
	//  routes — List application routes
	// ─────────────────────────────────────────────────

	/**
	 * hint: List all configured routes with method, path, and controller action
	 */
	public string function routes() {
		var serverPort = $requireRunningServer();

		try {
			// /wheels/cli?command=routes returns the actual application route
			// table as JSON. (The previous endpoint, /wheels/ai?context=routing,
			// returns AI-documentation about routing patterns — not what users
			// asking "what routes does my app have?" expect to see.)
			var routesUrl = "http://localhost:#serverPort#/wheels/cli?command=routes&format=json";
			var httpResult = makeHttpRequest(routesUrl);

			var result = "";
			try {
				result = deserializeJSON(httpResult);
			} catch (any jsonErr) {
				out("Failed to parse routes response", "red");
				verbose(httpResult);
				throw(type = "Wheels.RoutesFailed", message = "Failed to parse routes response");
			}

			if (!structKeyExists(result, "success") || !result.success) {
				out("Failed to fetch routes: #result.message ?: 'unknown error'#", "red");
				throw(type = "Wheels.RoutesFailed", message = "Failed to fetch routes: #result.message ?: 'unknown error'#");
			}

			if (!structKeyExists(result, "routes") || !arrayLen(result.routes)) {
				out("No routes configured.", "yellow");
				return "";
			}

			// Normalise patterns so the leading "/" is shown exactly once. The
			// framework stores routes with the leading slash already present,
			// but defensively handle the case where it isn't.
			var formatPattern = function(p) {
				p = p ?: "";
				return left(p, 1) == "/" ? p : "/" & p;
			};

			// Compute column widths from the data so the table aligns cleanly.
			var maxMethod  = len("METHOD");
			var maxPattern = len("PATTERN");
			var maxAction  = len("CONTROLLER##ACTION");
			for (var route in result.routes) {
				var methodWidth  = len(uCase(route.methods ?: ""));
				var patternWidth = len(formatPattern(route.pattern));
				var actionWidth  = len((route.controller ?: "") & "##" & (route.action ?: ""));
				if (methodWidth  > maxMethod)  maxMethod  = methodWidth;
				if (patternWidth > maxPattern) maxPattern = patternWidth;
				if (actionWidth  > maxAction)  maxAction  = actionWidth;
			}

			out(lJustify("METHOD", maxMethod) & "  " & lJustify("PATTERN", maxPattern) & "  " & "CONTROLLER##ACTION", "bold");
			out(repeatString("-", maxMethod + maxPattern + maxAction + 4));

			for (var route in result.routes) {
				var line = lJustify(uCase(route.methods ?: ""), maxMethod)
					& "  " & lJustify(formatPattern(route.pattern), maxPattern)
					& "  " & (route.controller ?: "") & "##" & (route.action ?: "");
				if (structKeyExists(route, "name") && len(route.name)) {
					line &= "  (" & route.name & ")";
				}
				out(line);
			}

			out("");
			out("#arrayLen(result.routes)# route(s)", "cyan");
		} catch (any e) {
			// Inner Wheels.RoutesFailed paths already printed a diagnostic; only HTTP/unexpected errors need one here.
			if (e.type != "Wheels.RoutesFailed") {
				out("Failed to fetch routes: #e.message#", "red");
			}
			rethrow;
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  info — Show environment info
	// ─────────────────────────────────────────────────

	/**
	 * hint: Show framework version, environment, and configuration
	 */
	public string function info() {
		out("Wheels CLI v#super.version()#", "bold");
		out("");

		if (len(variables.projectRoot) && directoryExists(variables.projectRoot & "/vendor/wheels")) {
			out("Project:  #variables.projectRoot#");

			// Detect the framework version from its authoritative manifest,
			// vendor/wheels/wheels.json. The historical
			// events/onapplicationstart/settings.cfm path stopped carrying the
			// version, so this line silently never rendered. We read the project's
			// manifest by absolute path (no `wheels` mapping needed) and apply the
			// same structural placeholder check as wheels.BuildInfo: an unstamped
			// dev checkout (`@build.version@`) reports as 0.0.0-dev rather than
			// leaking the raw build token.
			var versionFile = variables.projectRoot & "/vendor/wheels/wheels.json";
			if (fileExists(versionFile)) {
				try {
					var manifest = deserializeJSON(fileRead(versionFile));
					if (isStruct(manifest) && structKeyExists(manifest, "version") && len(manifest.version)) {
						var fwVersion = manifest.version;
						if (left(fwVersion, 7) == "@build." && right(fwVersion, 1) == "@") {
							fwVersion = "0.0.0-dev";
						}
						out("Wheels:   v#fwVersion#");
					}
				} catch (any e) { /* skip */ }
			}

			// CFML engine
			out("Engine:   Lucee (LuCLI module)");

			// Datasource. Strip CFML/cfscript comments first so commented-out
			// `set(...)` calls don't get parsed as live config, and use a
			// word-boundary on the property name so `coreTestDataSourceName`
			// is not picked up as if it were `dataSourceName`.
			var settingsFile = variables.projectRoot & "/config/settings.cfm";
			if (fileExists(settingsFile)) {
				try {
					var sContent = stripCfmlComments(fileRead(settingsFile));
					var dsMatch = reFindNoCase('\bdataSourceName\s*=\s*"([^"]+)"', sContent, 1, true);
					if (arrayLen(dsMatch.match) > 1) {
						out("Database: #dsMatch.match[2]#");
					}
				} catch (any e) { /* skip */ }
			}

			// Environment file
			var envFile = variables.projectRoot & "/.env";
			if (fileExists(envFile)) {
				out("Env file: .env found", "green");
			}

			// lucee.json
			var luceeJson = variables.projectRoot & "/lucee.json";
			if (fileExists(luceeJson)) {
				out("Config:   lucee.json found", "green");
			}

			// Count routes
			var routesFile = variables.projectRoot & "/config/routes.cfm";
			if (fileExists(routesFile)) {
				// Strip comments first so a commented-out .resources(...) isn't
				// counted (anti-pattern #14 — commented code must not satisfy
				// substring scans). Mirrors the datasource block above.
				var routeContent = stripCfmlComments(fileRead(routesFile));
				var resourceCount = 0;
				var pos = 1;
				while (pos > 0) {
					pos = findNoCase(".resources(", routeContent, pos);
					if (pos > 0) { resourceCount++; pos++; }
				}
				if (resourceCount > 0) {
					out("Routes:   #resourceCount# resource route(s)");
				}
			}

			// Count models. Exclude the framework's parent `Model.cfc` — it
			// extends `wheels.Model` and is not an application/domain model.
			var modelsDir = variables.projectRoot & "/app/models";
			if (directoryExists(modelsDir)) {
				var modelFiles = directoryList(modelsDir, false, "name", "*.cfc");
				var modelCount = 0;
				for (var modelFile in modelFiles) {
					if (modelFile == "Model.cfc") {
						continue;
					}
					modelCount++;
				}
				if (modelCount > 0) {
					out("Models:   #modelCount# model(s)");
				}
			}

			// Server status
			var serverPort = detectServerPort();
			if (serverPort) {
				out("Server:   running on port #serverPort#", "green");
			} else {
				out("Server:   not running", "yellow");
			}
		} else {
			out("Not in a Wheels project directory.", "yellow");
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  mcp — MCP server instructions
	// ─────────────────────────────────────────────────

	/**
	 * hint: Show MCP server configuration instructions
	 */
	public string function mcp() {
		out("MCP is built into the Wheels CLI. Run:", "bold");
		out("  wheels mcp wheels");
		out("");
		out("Configure in Claude Code (.mcp.json):", "bold");
		out('  {"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}');
		out("");
		out("For OpenCode, Cursor, and other AI IDEs, see:");
		out("  https://guides.wheels.dev/v4-0-0/command-line-tools/mcp-integration");
		out("");
		out("All public commands in this module are auto-discovered as MCP tools.");
		out("Tools are prefixed with the module name: wheels_generate, wheels_migrate, etc.");
		out("Stateful/interactive commands (start, stop, new, console, ...) are hidden");
		out("from MCP tools/list via mcpHiddenTools() — they remain CLI-only.");
		return "";
	}

	// ─────────────────────────────────────────────────
	//  console — Interactive REPL
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels console` arguments. Only `--password=<value>` is consumed; an
	 * empty result lets the command auto-detect the reload password. The legacy
	 * arg1-gated getArgs() dropped a bare `--password=x` (no positional), silently
	 * forcing auto-detection — ArgSpec reads the named value directly. The old
	 * space-separated `--password <value>` form is dropped for `--password=<value>`:
	 * LuCLI delivers the space form as a bare flag + a positional, never a named
	 * value (#2861).
	 */
	private struct function parseConsoleArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.option(name = "password", default = "")
			.parse(arguments.coll);
		return { password = parsed.password };
	}

	/**
	 * hint: Launch interactive CFML console with Wheels app context (model, service, get)
	 */
	public string function console() {
		var password = parseConsoleArgs(structuredArgs(arguments)).password;

		// Detect server
		var serverPort = $requireRunningServer([
			"The console requires a running server.",
			"Start one with: wheels start"
		]);

		// Auto-detect reload password if not provided
		if (!len(password)) {
			password = detectReloadPassword();
		}

		// Verify connectivity with a ping
		var evalUrl = "http://localhost:#serverPort#/wheels/console/eval";
		try {
			var pingResult = makeHttpPost(evalUrl, serializeJSON({expression: "__ping__", password: password}));
			if (isJSON(pingResult)) {
				var pingData = deserializeJSON(pingResult);
				if (!pingData.success) {
					out("Console connection failed: #pingData.error#", "red");
					return "";
				}
				var wheelsVersion = pingData.version ?: "unknown";
				var wheelsEnv = pingData.environment ?: "unknown";
			} else {
				out("Server returned unexpected response. Is this a Wheels 3.x application?", "red");
				return "";
			}
		} catch (any e) {
			out("Cannot connect to console endpoint at #evalUrl#", "red");
			out("Ensure your Wheels app is v3.1+ with console support.", "yellow");
			out("Error: #e.message#", "yellow");
			return "";
		}

		// Banner
		out("", "");
		out("Wheels Console v#super.version()#", "bold");
		out("Connected to localhost:#serverPort# (#wheelsEnv#) — Wheels #wheelsVersion#", "cyan");
		out("Type expressions to evaluate in your app context. /help for commands.", "");
		out("", "");

		// Interactive REPL loop
		var System = createObject("java", "java.lang.System");
		var reader = createObject("java", "java.io.BufferedReader").init(
			createObject("java", "java.io.InputStreamReader").init(System.in)
		);

		var running = true;
		while (running) {
			// Print prompt
			System.out.print("wheels> ");
			System.out.flush();

			// Read input
			var line = reader.readLine();

			// Handle EOF (Ctrl+D)
			if (isNull(line)) {
				out("");
				out("Bye!", "cyan");
				break;
			}

			line = trim(line);

			// Skip empty lines
			if (!len(line)) continue;

			// Handle REPL commands
			switch (lCase(line)) {
				case "/exit":
				case "/quit":
				case "/q":
					out("Bye!", "cyan");
					running = false;
					continue;

				case "/help":
				case "/h":
					printConsoleHelp();
					continue;

				case "/env":
					consoleExec(evalUrl, "__env__", password);
					continue;

				case "/reload":
					out("Reloading application...", "cyan");
					try {
						var reloadUrl = "http://localhost:#serverPort#/?reload=true&password=#password#";
						makeHttpRequest(reloadUrl);
						out("Application reloaded.", "green");
					} catch (any e) {
						out("Reload failed: #e.message#", "red");
					}
					continue;

				case "/clear":
					// ANSI clear screen
					System.out.print(chr(27) & "[2J" & chr(27) & "[H");
					System.out.flush();
					continue;

				case "/models":
					consoleExec(evalUrl, "structKeyArray(application.wheels.models).sort('textnocase')", password);
					continue;

				case "/routes":
					consoleExec(evalUrl, "application.wheels.routes.map(function(r){ return r.pattern & ' -> ' & r.controller & '##' & r.action; })", password);
					continue;

				case "/version":
					consoleExec(evalUrl, "application.wheels.version", password);
					continue;

				case "/ds":
				case "/datasource":
					consoleExec(evalUrl, "application.wheels.dataSourceName", password);
					continue;
			}

			// Evaluate expression
			consoleExec(evalUrl, line, password);
		}

		return "";
	}

	/**
	 * Execute a single expression and display the result
	 */
	private void function consoleExec(required string requestUrl, required string expression, string password = "") {
		try {
			var body = serializeJSON({expression: expression, password: password});
			var httpResult = makeHttpPost(requestUrl, body);

			if (!isJSON(httpResult)) {
				out("Server returned non-JSON response.", "red");
				verbose(httpResult);
				return;
			}

			var result = deserializeJSON(httpResult);

			// Display captured output (from writeOutput calls)
			if (len(result.output ?: "")) {
				out(result.output);
			}

			if (!result.success) {
				out("Error: #result.error#", "red");
				return;
			}

			// Display result based on type
			var resultType = result.type ?: "void";
			var resultValue = result.result ?: "";

			if (resultType == "void" && !len(resultValue)) {
				// No return value and no output — nothing to display
				return;
			}

			switch (resultType) {
				case "query":
					displayQueryResult(resultValue);
					break;

				case "model":
					displayModelResult(resultValue);
					break;

				case "struct":
				case "array":
					displayJsonResult(resultValue, resultType);
					break;

				case "number":
				case "boolean":
				case "string":
					out("=> #resultValue#", "green");
					break;

				case "object":
					out("=> [#resultValue#]", "cyan");
					break;

				default:
					if (len(resultValue)) {
						out("=> #resultValue#");
					}
			}

		} catch (any e) {
			out("Request failed: #e.message#", "red");
		}
	}

	/**
	 * Display a query result as a formatted table
	 */
	private void function displayQueryResult(required string jsonResult) {
		try {
			var data = deserializeJSON(jsonResult);
			var columns = data.columns ?: [];
			var rows = data.data ?: [];
			var recordCount = data.recordCount ?: 0;

			if (!arrayLen(columns)) {
				out("(empty query)", "yellow");
				return;
			}

			// Calculate column widths
			var widths = {};
			for (var col in columns) {
				widths[col] = len(col);
			}
			for (var row in rows) {
				for (var col in columns) {
					var val = toString(row[col] ?: "");
					if (len(val) > 40) val = left(val, 37) & "...";
					widths[col] = max(widths[col], len(val));
				}
			}

			// Header
			var header = "";
			var separator = "";
			for (var col in columns) {
				var w = widths[col];
				header &= " " & lCase(col) & repeatString(" ", w - len(col)) & " |";
				separator &= repeatString("-", w + 2) & "+";
			}
			out(header, "bold");
			out(separator, "");

			// Rows
			for (var row in rows) {
				var line = "";
				for (var col in columns) {
					var w = widths[col];
					var val = toString(row[col] ?: "");
					if (len(val) > 40) val = left(val, 37) & "...";
					line &= " " & val & repeatString(" ", w - len(val)) & " |";
				}
				out(line);
			}

			// Footer
			if (recordCount > arrayLen(rows)) {
				out("(#recordCount# rows, showing first #arrayLen(rows)#)", "yellow");
			} else {
				out("(#recordCount# row#recordCount != 1 ? 's' : ''#)", "yellow");
			}

		} catch (any e) {
			// Fallback: show raw JSON
			out(jsonResult);
		}
	}

	/**
	 * Display a model result as key-value pairs
	 */
	private void function displayModelResult(required string jsonResult) {
		try {
			var props = deserializeJSON(jsonResult);
			out("=> {", "green");
			var keys = structKeyArray(props);
			arraySort(keys, "textnocase");
			for (var key in keys) {
				if (left(key, 1) == "_") continue; // Skip meta keys in main display
				var val = isNull(props[key]) ? "null" : toString(props[key]);
				if (len(val) > 80) val = left(val, 77) & "...";
				out("    #lCase(key)#: #val#");
			}
			// Show meta info
			if (structKeyExists(props, "_key")) {
				out("    _key: #props._key#", "cyan");
			}
			if (structKeyExists(props, "_isNew")) {
				out("    _isNew: #props._isNew#", "cyan");
			}
			out("  }", "green");
		} catch (any e) {
			out("=> #jsonResult#");
		}
	}

	/**
	 * Display a struct or array result as indented JSON
	 */
	private void function displayJsonResult(required string jsonResult, required string type) {
		try {
			// Simple indentation for readability
			var formatted = jsonResult;
			// Basic pretty-print: add newlines after { [ , and before } ]
			formatted = replace(formatted, "{", "{#chr(10)#  ", "all");
			formatted = replace(formatted, "}", "#chr(10)#}", "all");
			formatted = replace(formatted, "[", "[#chr(10)#  ", "all");
			formatted = replace(formatted, "]", "#chr(10)#]", "all");
			formatted = replace(formatted, ",", ",#chr(10)#  ", "all");
			out("=> #formatted#", "green");
		} catch (any e) {
			out("=> #jsonResult#");
		}
	}

	/**
	 * Print console help text
	 */
	private void function printConsoleHelp() {
		out("");
		out("Wheels Console Commands:", "bold");
		out("  /help, /h       Show this help");
		out("  /env            Show environment info");
		out("  /models         List all registered models");
		out("  /routes         List all routes");
		out("  /version        Show Wheels version");
		out("  /ds, /datasource Show current datasource");
		out("  /reload         Reload the application");
		out("  /clear          Clear the screen");
		out("  /exit, /quit, /q Exit the console");
		out("");
		out("Expression Examples:", "bold");
		out('  model("User").findAll()                      Query all users');
		out('  model("User").findByKey(1)                   Find user by ID');
		out('  model("User").findByKey(1).properties()      Get user properties');
		out('  model("User").count()                        Count records');
		out('  model("Post").findAll(where="status=''draft''")  Filtered query');
		out('  get("environment")                           Framework setting');
		out('  service("emailService")                      Resolve a service');
		out('  application.wheels.version                   Wheels version');
		out("");
	}

	// ─────────────────────────────────────────────────
	//  analyze — Code analysis
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels analyze` arguments. Single positional target (defaults to
	 * "all"); `hasTarget` distinguishes a bare `wheels analyze` from an explicit
	 * target so the "not in a project" guard only fires for the bare form.
	 */
	private struct function parseAnalyzeArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.positional(name = "target", default = "all")
			.parse(arguments.coll);
		return {
			target = lCase(parsed.target),
			hasTarget = structKeyExists(arguments.coll, "arg1")
		};
	}

	/**
	 * hint: Analyze Wheels application code for quality issues, anti-patterns, and complexity metrics
	 */
	public string function analyze() {
		var opts = parseAnalyzeArgs(structuredArgs(arguments));
		var target = opts.target;

		if (!opts.hasTarget && !directoryExists(variables.projectRoot & "/app")) {
			out("No app/ directory found. Are you in a Wheels project?", "red");
			return "";
		}

		out("Analyzing code...", "cyan");
		out("");

		try {
			var analysis = getService("analysis");
			var results = analysis.analyze(target);

			// Display metrics
			out("Code Analysis Results", "bold");
			out("────────────────────────────────────");
			out("Files:      #results.totalFiles#");
			out("Lines:      #results.totalLines#");
			out("Functions:  #results.totalFunctions#");
			out("Grade:      #results.metrics.grade# (#results.metrics.healthScore#/100)");
			out("");

			// Anti-patterns
			if (arrayLen(results.antiPatterns)) {
				out("Anti-Patterns (#arrayLen(results.antiPatterns)#)", "red");
				for (var issue in results.antiPatterns) {
					var fileName = listLast(issue.file, "/\");
					var severity = issue.severity == "error" ? "red" : "yellow";
					out("  [#uCase(issue.severity)#] #fileName#:#issue.line ?: 1# — #issue.message#", severity);
				}
				out("");
			}

			// Complex functions
			if (arrayLen(results.complexFunctions)) {
				out("Complex Functions (#arrayLen(results.complexFunctions)#)", "yellow");
				for (var f in results.complexFunctions) {
					var fName = listLast(f.file, "/\");
					out("  #fName#:#f.functionName# — complexity #f.complexity#", "yellow");
				}
				out("");
			}

			// Code smells
			if (arrayLen(results.codeSmells)) {
				out("Code Smells (#arrayLen(results.codeSmells)#)", "yellow");
				for (var smell in results.codeSmells) {
					var sName = listLast(smell.file, "/\");
					out("  #sName# — #smell.message#", "yellow");
				}
				out("");
			}

			if (!arrayLen(results.antiPatterns) && !arrayLen(results.complexFunctions) && !arrayLen(results.codeSmells)) {
				out("No issues found!", "green");
			}

			out("Completed in #numberFormat(results.executionTime, '0.00')#s");
		} catch (any e) {
			out("Analysis failed: #e.message#", "red");
		}

		return "";
	}

	// ─────────────────────────────────────────────────
	//  validate — Quick validation
	// ─────────────────────────────────────────────────

	/**
	 * hint: Validate Wheels application code for common errors and anti-patterns
	 */
	public string function validate() {
		if (!directoryExists(variables.projectRoot & "/app")) {
			out("No app/ directory found. Are you in a Wheels project?", "red");
			// throw maps to non-zero exit; return "" would silently succeed.
			throw(type = "Wheels.InvalidArguments", message = "No app/ directory found — run wheels validate from a Wheels project root.");
		}

		out("Validating...", "cyan");
		out("");

		var validationFailed = false;
		var issueCount = 0;

		try {
			var analysis = getService("analysis");
			var results = analysis.validate();

			if (results.valid) {
				out("Validation passed — no errors found (#results.totalIssues# warnings)", "green");
			} else {
				out("Validation found #results.totalIssues# issue(s):", "red");
			}

			for (var issue in results.issues) {
				var fileName = listLast(issue.file, "/\");
				var severity = issue.severity == "error" ? "red" : "yellow";
				out("  [#uCase(issue.severity)#] #fileName# — #issue.message#", severity);
			}

			// Capture before try ends; throwing inside would be swallowed by the catch.
			validationFailed = !results.valid;
			issueCount = results.totalIssues;
		} catch (any e) {
			out("Validation failed: #e.message#", "red");
			// rethrow maps to non-zero exit; an analyzer crash must not exit 0.
			rethrow;
		}

		// Throw after the full report flushes — errors exit non-zero, warnings stay green.
		if (validationFailed) {
			throw(type = "Wheels.ValidationFailed", message = "Validation found #issueCount# issue(s) — see the report above.");
		}

		return "";
	}

	// ─────────────────────────────────────────────────
	//  destroy — Remove generated components
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels destroy` arguments. Supports both `<type> <name>` (preferred)
	 * and the legacy `<name> <type>` orderings (issue #2313 / F16) plus the
	 * `--force` flag. `positionalCount` lets the command show usage when nothing
	 * was supplied. The smart reorder is business logic that survives the ArgSpec
	 * migration unchanged — ArgSpec only replaced the hand-rolled token split.
	 */
	private struct function parseDestroyArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.flag(name = "force", default = false)
			.parse(arguments.coll);

		// Collect positionals from every arg<n> value in numeric order. LuCLI
		// numbers positionals by global token index, so a leading `--force`
		// leaves a gap (arg2, arg3 with no arg1); gathering by sorted index
		// keeps the <type>/<name> pair intact wherever `--force` sits.
		var indices = [];
		for (var key in arguments.coll) {
			if (reFindNoCase("^arg\d+$", key)) {
				arrayAppend(indices, val(mid(key, 4, len(key))));
			}
		}
		arraySort(indices, "numeric");
		var positional = [];
		for (var idx in indices) {
			var token = trim(arguments.coll["arg" & idx]);
			if (len(token)) arrayAppend(positional, token);
		}

		var validTypes = "resource,model,controller,view";
		var name = "";
		var type = "resource";
		if (arrayLen(positional) == 1) {
			name = positional[1];
		} else if (arrayLen(positional) >= 2) {
			var firstArg = positional[1];
			var secondArg = positional[2];
			if (listFindNoCase(validTypes, firstArg)) {
				type = lCase(firstArg);
				name = secondArg;
			} else if (listFindNoCase(validTypes, secondArg)) {
				name = firstArg;
				type = lCase(secondArg);
			} else {
				name = firstArg;
				type = lCase(secondArg);
			}
		}

		return {
			name = name,
			type = type,
			force = parsed.force,
			positionalCount = arrayLen(positional)
		};
	}

	/**
	 * hint: Remove generated components (resource, model, controller, view)
	 */
	public string function destroy() {
		var opts = parseDestroyArgs(structuredArgs(arguments));

		if (!opts.positionalCount) {
			out("Usage: wheels destroy <type> <name>", "yellow");
			out("       wheels destroy <name>          (type defaults to 'resource')", "yellow");
			out("");
			out("Types:", "bold");
			out("  resource    Remove model + controller + views + tests + route + migration (default)");
			out("  model       Remove model + test + generate drop-table migration");
			out("  controller  Remove controller + test");
			out("  view        Remove view directory (or single file with controller/view syntax)");
			out("");
			out("Examples:", "bold");
			out("  wheels destroy User                   (remove the User resource)");
			out("  wheels destroy controller Products    (remove just the Products controller)");
			out("  wheels destroy model Product          (remove just the Product model)");
			out("  wheels destroy view products/index    (remove a single view)");
			return "";
		}

		var name = opts.name;
		var type = opts.type;
		var force = opts.force;

		if (!listFindNoCase("resource,model,controller,view", type)) {
			out("Unknown type: #type#. Valid types: resource, model, controller, view", "red");
			return "";
		}

		var svc = getService("destroy");

		// Show preview and confirm
		var preview = svc.previewDestroy(name, type);
		if (!arrayLen(preview)) {
			out("Nothing to destroy.", "yellow");
			return "";
		}

		out("The following will be deleted:", "yellow");
		for (var item in preview) {
			out("  #item#");
		}
		out("");

		if (!force) {
			out("Use --force to confirm deletion.", "yellow");
			return "";
		}

		var result = {};
		switch (type) {
			case "resource":
				result = svc.destroyResource(name);
				break;
			case "model":
				result = svc.destroyModel(name);
				break;
			case "controller":
				result = svc.destroyController(name);
				break;
			case "view":
				result = svc.destroyView(name);
				break;
		}

		// Output results
		for (var deleted in result.deleted) {
			out("  delete  #deleted#", "red");
		}
		for (var warning in result.warnings) {
			out("  skip    #warning#", "yellow");
		}
		if (structKeyExists(result, "migrationPath") && len(result.migrationPath)) {
			out("");
			out("Migration generated: #result.migrationPath#", "cyan");
			out("Run 'wheels migrate latest' to apply.", "cyan");
		}
		return "";
	}

	/**
	 * hint: Alias for destroy
	 */
	public string function d() {
		return destroy(argumentCollection = arguments);
	}

	/**
	 * hint: Alias for generate
	 */
	public string function g() {
		return generate(argumentCollection = arguments);
	}

	// ─────────────────────────────────────────────────
	//  doctor — Application health checks
	// ─────────────────────────────────────────────────

	/**
	 * Resolve the --verbose flag shared by `doctor` and `stats`. Named
	 * `--verbose` (no positional) was dropped by the legacy arg1-gate; ArgSpec
	 * reads it directly. `-v` is preserved — LuCLI only normalizes --x / --no-x,
	 * so a short flag arrives as a positional arg<n> value.
	 */
	private boolean function parseVerboseFlag(required struct coll) {
		var parsed = new services.ArgSpec()
			.flag(name = "verbose", default = false)
			.parse(arguments.coll);
		if (parsed.verbose) {
			return true;
		}
		for (var key in arguments.coll) {
			if (reFindNoCase("^arg\d+$", key) && arguments.coll[key] == "-v") {
				return true;
			}
		}
		return false;
	}

	/**
	 * hint: Run health checks on your Wheels application
	 */
	public string function doctor() {
		var verbose = parseVerboseFlag(structuredArgs(arguments));

		var svc = getService("doctor");
		var results = svc.runChecks();

		out("Wheels Health Check", "bold");
		out(repeatString("=", 40));
		out("");

		// Issues
		if (arrayLen(results.issues)) {
			out("Issues (#arrayLen(results.issues)#):", "red");
			for (var issue in results.issues) {
				out("  x #issue#", "red");
			}
			out("");
		}

		// Warnings
		if (arrayLen(results.warnings)) {
			out("Warnings (#arrayLen(results.warnings)#):", "yellow");
			for (var warning in results.warnings) {
				out("  ! #warning#", "yellow");
			}
			out("");
		}

		// Mixin collision detail (verbose only)
		if (verbose && structKeyExists(results, "mixinCollisions") && arrayLen(results.mixinCollisions)) {
			out("Mixin collisions (#arrayLen(results.mixinCollisions)#):", "yellow");
			for (var c in results.mixinCollisions) {
				out(
					"  ! method '#c.method#' on '#c.target#' provided by #c.firstSource# '#c.firstName#' is overwritten by #c.secondSource# '#c.secondName#'. Acknowledge via provides.overrides to silence.",
					"yellow"
				);
			}
			out("");
		}

		// Passed (verbose only, or when no issues)
		if (verbose || (results.status == "HEALTHY")) {
			out("Passed (#arrayLen(results.passed)#):", "green");
			for (var passed in results.passed) {
				out("  + #passed#", "green");
			}
			out("");
		}

		// Status
		switch (results.status) {
			case "CRITICAL":
				out("Status: CRITICAL", "red");
				break;
			case "WARNING":
				out("Status: WARNING", "yellow");
				break;
			case "HEALTHY":
				out("Status: HEALTHY", "green");
				break;
		}

		// Recommendations
		if (arrayLen(results.recommendations)) {
			out("");
			out("Recommendations:", "cyan");
			for (var rec in results.recommendations) {
				out("  * #rec#", "cyan");
			}
		}

		return "";
	}

	// ─────────────────────────────────────────────────
	//  deploy — Kamal-style production deploys
	// ─────────────────────────────────────────────────

	/**
	 * hint: Deploy the app to production servers.
	 *
	 * Usage:
	 *   wheels deploy                          - full deploy
	 *   wheels deploy --dry-run                - print commands, skip execution
	 *   wheels deploy --destination production - load deploy.production.yml overlay
	 *   wheels deploy rollback v1              - roll back to version v1
	 *   wheels deploy config                   - print resolved config as YAML
	 *   wheels deploy init                     - create config stub
	 *   wheels deploy setup                    - full setup (Phase 2 adds accessories)
	 *   wheels deploy bootstrap                - install Docker on every host
	 *   wheels deploy exec "uname -a"          - run a command on every host
	 *   wheels deploy version                  - show version pinning
	 */
	public string function deploy() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));
		var opts = $deployArgsToOptions(args);
		if (!structKeyExists(opts, "configPath") || !len(opts.configPath)) {
			opts.configPath = expandPath("config/deploy.yml");
		}

		var positional = $deployStripFlags(args);
		var sub = arrayLen(positional) >= 1 ? positional[1] : "deploy";

		var dmc = new modules.wheels.services.deploy.cli.DeployMainCli(
			$deployBuildSshPool(opts.configPath)
		);

		switch (sub) {
			case "deploy":
				return dmc.deploy(opts);
			case "redeploy":
				return dmc.redeploy(opts);
			case "rollback":
				if (arrayLen(positional) < 2) {
					throw(message="rollback requires a version argument: wheels deploy rollback <version>");
				}
				opts.version = positional[2];
				return dmc.rollback(opts);
			case "config":
				return dmc.config(opts);
			case "init":
				return dmc.init_stub(opts);
			case "setup":
				return dmc.setup(opts);
			case "version":
				return dmc.version();
			case "audit":
				return dmc.audit(opts);
			case "docs":
				// `docs [SECTION]` — section is the optional second positional.
				opts.section = arrayLen(positional) >= 2 ? positional[2] : "";
				return dmc.docs(opts);
			case "details":
				return dmc.details(opts);
			case "remove":
				return dmc.remove(opts);
			case "app":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy app requires a verb");
				}
				var appVerb = positional[2];
				var appCli = new modules.wheels.services.deploy.cli.DeployAppCli(
					$deployBuildSshPool(opts.configPath)
				);
				switch (appVerb) {
					case "boot":
					case "start":
					case "stop":
					case "details":
					case "containers":
					case "images":
					case "logs":
					case "live":
					case "maintenance":
					case "remove":
						return invoke(appCli, appVerb, [opts]);
					default:
						throw(message="Unknown wheels deploy app verb: #appVerb#");
				}
			case "proxy":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy proxy requires a verb");
				}
				var proxyVerb = positional[2];
				var proxyCli = new modules.wheels.services.deploy.cli.DeployProxyCli(
					$deployBuildSshPool(opts.configPath)
				);
				switch (proxyVerb) {
					case "boot":
					case "reboot":
					case "start":
					case "stop":
					case "restart":
					case "details":
					case "logs":
					case "remove":
						return invoke(proxyCli, proxyVerb, [opts]);
					default:
						throw(message="Unknown wheels deploy proxy verb: #proxyVerb#");
				}
			case "registry":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy registry requires a verb");
				}
				var registryVerb = positional[2];
				var registryCli = new modules.wheels.services.deploy.cli.DeployRegistryCli(
					$deployBuildSshPool(opts.configPath)
				);
				switch (registryVerb) {
					case "setup":
					case "login":
					case "logout":
					case "remove":
						return invoke(registryCli, registryVerb, [opts]);
					default:
						throw(message="Unknown wheels deploy registry verb: #registryVerb#");
				}
			case "build":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy build requires a verb");
				}
				var buildVerb = positional[2];
				var buildCli = new modules.wheels.services.deploy.cli.DeployBuildCli(
					$deployBuildSshPool(opts.configPath)
				);
				switch (buildVerb) {
					case "deliver":
					case "push":
					case "pull":
					case "create":
					case "remove":
					case "details":
					case "dev":
						return invoke(buildCli, buildVerb, [opts]);
					default:
						throw(message="Unknown wheels deploy build verb: #buildVerb#");
				}
			case "accessory":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy accessory requires a verb");
				}
				var accVerb = positional[2];
				opts.name = arrayLen(positional) >= 3 ? positional[3] : "";
				var accCli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(
					$deployBuildSshPool(opts.configPath)
				);
				switch (accVerb) {
					case "boot":
					case "reboot":
					case "start":
					case "stop":
					case "restart":
					case "details":
					case "logs":
					case "remove":
						return invoke(accCli, accVerb, [opts]);
					default:
						throw(message="Unknown wheels deploy accessory verb: #accVerb#");
				}
			case "prune":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy prune requires a verb (all/images/containers)");
				}
				var pruneVerb = positional[2];
				if (!listFindNoCase("all,images,containers", pruneVerb)) {
					throw(message="Unknown wheels deploy prune verb: " & pruneVerb);
				}
				var pruneCli = new modules.wheels.services.deploy.cli.DeployPruneCli(
					$deployBuildSshPool(opts.configPath)
				);
				return invoke(pruneCli, pruneVerb, [opts]);
			// `bootstrap` and `exec` are top-level aliases for `server bootstrap`
			// and `server exec`. LuCLI's picocli root registers `server` as a
			// top-level subcommand for Lucee instance management, so the nested
			// `wheels deploy server <verb>` form gets shortcut into LuCLI's
			// own server help before module dispatch — see #2677. These flat
			// aliases sidestep the collision entirely. The original `server`
			// branch below is retained for Kamal parity and direct callers
			// (MCP, internal tests) that don't go through LuCLI's picocli root.
			case "bootstrap":
				var bootstrapCli = new modules.wheels.services.deploy.cli.DeployServerCli(
					new modules.wheels.services.deploy.lib.SshPool()
				);
				return bootstrapCli.bootstrap(opts);
			case "exec":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy exec requires a command");
				}
				// Preserve multi-token commands: join all positional args after `exec`.
				var execCmdParts = [];
				for (var ei = 2; ei <= arrayLen(positional); ei++) {
					arrayAppend(execCmdParts, positional[ei]);
				}
				opts.cmd = arrayToList(execCmdParts, " ");
				var execCli = new modules.wheels.services.deploy.cli.DeployServerCli(
					new modules.wheels.services.deploy.lib.SshPool()
				);
				return execCli.exec(opts);
			case "server":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy server requires a verb (exec or bootstrap)");
				}
				var serverVerb = positional[2];
				if (serverVerb == "exec") {
					if (arrayLen(positional) < 3) {
						throw(message="wheels deploy server exec requires a command");
					}
					// Preserve multi-token commands: join all positional args after the verb.
					var cmdParts = [];
					for (var ci = 3; ci <= arrayLen(positional); ci++) {
						arrayAppend(cmdParts, positional[ci]);
					}
					opts.cmd = arrayToList(cmdParts, " ");
				}
				var serverCli = new modules.wheels.services.deploy.cli.DeployServerCli(
					$deployBuildSshPool(opts.configPath)
				);
				switch (serverVerb) {
					case "exec":
						return serverCli.exec(opts);
					case "bootstrap":
						return serverCli.bootstrap(opts);
					default:
						throw(message="Unknown wheels deploy server verb: #serverVerb#");
				}
			case "lock":
				if (arrayLen(positional) < 2) throw(message="wheels deploy lock requires a verb (acquire/release/status)");
				var lockVerb = positional[2];
				if (!listFindNoCase("acquire,release,status", lockVerb)) {
					throw(message="Unknown wheels deploy lock verb: " & lockVerb);
				}
				var lockCli = new modules.wheels.services.deploy.cli.DeployLockCli(
					$deployBuildSshPool(opts.configPath)
				);
				return invoke(lockCli, lockVerb, [opts]);
			// `fetch-secrets`, `extract-secrets`, and `print-secrets` are
			// top-level aliases for `secrets fetch`/`extract`/`print`. LuCLI's
			// picocli root registers `secrets` as a top-level subcommand for
			// the local secrets store (init/set/list/rm/get/provider), so the
			// nested `wheels deploy secrets <verb>` form gets shortcut into
			// LuCLI's own secrets help before module dispatch — see #2697.
			// These flat aliases sidestep the collision entirely, mirroring
			// the `bootstrap`/`exec` pattern from #2677. The original
			// `secrets` branch below is retained for Kamal parity and direct
			// callers (MCP, internal tests) that don't go through LuCLI's
			// picocli root.
			case "fetch-secrets":
				opts.keys = [];
				for (var fsi = 2; fsi <= arrayLen(positional); fsi++) arrayAppend(opts.keys, positional[fsi]);
				var fetchSecretsCli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
				return fetchSecretsCli.fetch(opts);
			case "extract-secrets":
				opts.key = arrayLen(positional) >= 2 ? positional[2] : "";
				var extractSecretsCli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
				return extractSecretsCli.extract(opts);
			case "print-secrets":
				var printSecretsCli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
				return printSecretsCli.print(opts);
			case "secrets":
				if (arrayLen(positional) < 2) {
					throw(message="wheels deploy secrets requires a verb (fetch/extract/print)");
				}
				var secVerb = positional[2];
				if (!listFindNoCase("fetch,extract,print", secVerb)) {
					throw(message="Unknown wheels deploy secrets verb: " & secVerb);
				}
				if (secVerb == "fetch") {
					opts.keys = [];
					for (var si = 3; si <= arrayLen(positional); si++) arrayAppend(opts.keys, positional[si]);
				}
				if (secVerb == "extract") {
					opts.key = arrayLen(positional) >= 3 ? positional[3] : "";
				}
				var secCli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
				return invoke(secCli, secVerb, [opts]);
			default:
				throw(message="Unknown deploy subcommand: #sub#");
		}
	}

	/**
	 * Build an SshPool seeded from the deploy.yml at `configPath`.
	 * Delegates to `SshPoolFactory.fromConfigPath` — see that CFC for the
	 * load, fallback, and tilde-expansion semantics.
	 */
	private any function $deployBuildSshPool(string configPath = "") {
		return new modules.wheels.services.deploy.lib.SshPoolFactory()
			.fromConfigPath(arguments.configPath);
	}

	private struct function $deployArgsToOptions(required array args) {
		// Delegates to a standalone parser CFC so the logic can be unit-tested
		// without instantiating Module.cfc (which requires the modules.BaseModule
		// mapping that only exists inside the LuCLI runtime). See issue #2674
		// and cli/lucli/services/deploy/cli/DeployArgsParser.cfc.
		return new modules.wheels.services.deploy.cli.DeployArgsParser().parse(arguments.args);
	}

	// ─────────────────────────────────────────────────
	//  packages — registry-backed package manager
	// ─────────────────────────────────────────────────

	/**
	 * hint: Install, update, and list Wheels packages — use `add` (not `install`) to install
	 *
	 * The verb is `add`, NOT `install`. Typing `wheels packages install <name>`
	 * is intercepted by LuCLI's built-in extension installer before dispatch
	 * reaches this module, and prints `[INFO] No git or extension dependencies
	 * to install` without actually installing anything. See chapter 8 of the
	 * tutorial for the explanation.
	 *
	 * Usage:
	 *   wheels packages list [--tag=<tag>]
	 *   wheels packages search <query>
	 *   wheels packages show <name>
	 *   wheels packages add <name>[@<version>] [--force]    ← install verb
	 *   wheels packages update <name> --yes
	 *   wheels packages update --all --yes
	 *   wheels packages remove <name>
	 *   wheels packages registry refresh
	 *   wheels packages registry info
	 */
	public string function packages() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));
		var opts = $packagesArgsToOptions(args);
		var positional = $packagesStripFlags(args);
		var sub = arrayLen(positional) >= 1 ? positional[1] : "list";

		// `--help` / `-h` short-circuits to a deterministic help string the
		// module owns directly. LuCLI's auto-introspected help previously
		// drifted from the real CLI surface — advertising the dead `install`
		// verb that LuCLI itself intercepts (#2713). Owning the text here
		// guarantees `wheels packages help`, `wheels packages --help`, and
		// `wheels packages -h` all reach $packagesHelp().
		//
		// Note: `-h` is consumed by $packagesArgsToOptions (sets opts.help =
		// true) and stripped from positionals by $packagesStripFlags before
		// `sub` is read, so it arrives here as opts.help — never as a
		// positional. No `sub == "-h"` clause is needed.
		if ((opts.help ?: false) || sub == "help") {
			return $packagesHelp();
		}

		switch (sub) {
			case "list":
				var mainCli = new modules.wheels.services.packages.PackagesMainCli();
				return mainCli.list(opts);
			case "search":
				if (arrayLen(positional) < 2) {
					throw(message="search requires a query: wheels packages search <query>");
				}
				opts.query = positional[2];
				var mainCli = new modules.wheels.services.packages.PackagesMainCli();
				return mainCli.search(opts);
			case "show":
				if (arrayLen(positional) < 2) {
					throw(message="show requires a name: wheels packages show <name>");
				}
				opts.name = positional[2];
				var mainCli = new modules.wheels.services.packages.PackagesMainCli();
				return mainCli.show(opts);
			case "install":
				// LuCLI's built-in extension installer intercepts the
				// literal verb `install` on the user-facing CLI surface
				// — same trap that bit `wheels browser install` (renamed
				// to `wheels browser setup` in #2345). But every other
				// caller path reaches this dispatch directly: the
				// stdio MCP server (`wheels mcp wheels`), scripted
				// in-process clients, and the bundle's own spec suite.
				// `PackagesMainCli.install()` has been a transparent
				// alias for `add()` since #2729, so the dispatch layer
				// must match — otherwise `install <name>` silently
				// no-ops on the only paths LuCLI does NOT intercept.
				// Fall through to the `add` branch (same validation,
				// same error shape, same install behavior).
			case "add":
				if (arrayLen(positional) < 2) {
					throw(message="add requires a name: wheels packages add <name>[@<version>]");
				}
				opts.target = positional[2];
				var mainCli = new modules.wheels.services.packages.PackagesMainCli();
				return mainCli.add(opts);
			case "update":
				opts.target = arrayLen(positional) >= 2 ? positional[2] : "";
				var mainCli = new modules.wheels.services.packages.PackagesMainCli();
				return mainCli.update(opts);
			case "remove":
				if (arrayLen(positional) < 2) {
					throw(message="remove requires a name: wheels packages remove <name>");
				}
				opts.target = positional[2];
				var mainCli = new modules.wheels.services.packages.PackagesMainCli();
				return mainCli.remove(opts);
			case "registry":
				if (arrayLen(positional) < 2) {
					throw(message="wheels packages registry requires a verb (refresh or info)");
				}
				var regVerb = positional[2];
				if (!listFindNoCase("refresh,info", regVerb)) {
					throw(message="Unknown wheels packages registry verb: #regVerb#");
				}
				var regCli = new modules.wheels.services.packages.PackagesRegistryCli();
				return invoke(regCli, regVerb, [opts]);
			default:
				throw(message="Unknown packages subcommand: #sub#");
		}
	}

	// Hand-written help for `wheels packages`. Owned by the module rather than
	// auto-derived from picocli introspection because the auto-help drifted
	// from the real CLI surface (#2713 — advertised `install <name> [--force]`
	// even though LuCLI's built-in extension installer intercepts the literal
	// `install` verb before dispatch reaches this module). Same trap that hit
	// `wheels browser install` (renamed to `setup` in #2345).
	private string function $packagesHelp() {
		var nl = chr(10);
		var help = "Usage: wheels packages <subcommand> [options]" & nl;
		help &= "  Install, update, search, and list Wheels packages from the wheels-packages registry." & nl & nl;
		help &= "Subcommands:" & nl;
		help &= "  list [--tag=<tag>]                      List packages (optionally filtered by tag)" & nl;
		help &= "  search <query>                          Search package names, descriptions, and tags" & nl;
		help &= "  show <name>                             Show package details and compatible versions" & nl;
		help &= "  add <name>[@<version>] [--force]        Install a package into vendor/<name>/ (canonical)" & nl;
		help &= "  update <name> --yes                     Update an installed package" & nl;
		help &= "  update --all --yes                      Update every installed package" & nl;
		help &= "  remove <name>                           Delete an installed package from vendor/" & nl;
		help &= "  registry refresh                        Bust the 24-hour registry cache" & nl;
		help &= "  registry info                           Show the registry URL and cache state" & nl;
		help &= "  help, --help, -h                        Show this help" & nl & nl;
		help &= "Note: the install verb is `add`, NOT `install`." & nl;
		help &= "  Typing `wheels packages install <name>` is intercepted by LuCLI's built-in" & nl;
		help &= "  extension installer before dispatch reaches this module, and prints" & nl;
		help &= "  '[INFO] No git or extension dependencies to install' without installing" & nl;
		help &= "  anything. Use `wheels packages add <name>` instead. Same trap that bit" & nl;
		help &= "  `wheels browser install` (renamed to `wheels browser setup` in ##2345)." & nl & nl;
		help &= "Examples:" & nl;
		help &= "  wheels packages list" & nl;
		help &= "  wheels packages search ui" & nl;
		help &= "  wheels packages add wheels-basecoat" & nl;
		help &= "  wheels packages add wheels-basecoat@1.0.1" & nl;
		help &= "  wheels packages update --all --yes" & nl;
		help &= "  wheels packages remove wheels-basecoat" & nl;
		return help;
	}

	private struct function $packagesArgsToOptions(required array args) {
		var opts = {};
		var n = arrayLen(arguments.args);
		var i = 1;
		while (i <= n) {
			var a = arguments.args[i];
			if (a == "--all") {
				opts.all = true;
			} else if (a == "--yes") {
				opts.yes = true;
			} else if (a == "--force") {
				opts.force = true;
			} else if (a == "--help" || a == "-h") {
				opts.help = true;
			} else if (left(a, 6) == "--tag=") {
				opts.tag = mid(a, 7, 99999);
			} else if (a == "--tag" && i < n) {
				opts.tag = arguments.args[i+1];
				i++;
			}
			i++;
		}
		return opts;
	}

	private array function $packagesStripFlags(required array args) {
		var out = [];
		var n = arrayLen(arguments.args);
		var i = 1;
		while (i <= n) {
			var a = arguments.args[i];
			if (left(a, 2) == "--") {
				var booleans = "--all,--yes,--force,--help";
				if (!find("=", a) && !listFindNoCase(booleans, a) && i < n && left(arguments.args[i+1], 2) != "--") {
					i++;
				}
				i++;
				continue;
			}
			if (a == "-h") {
				i++;
				continue;
			}
			arrayAppend(out, a);
			i++;
		}
		return out;
	}

	private array function $deployStripFlags(required array args) {
		var out = [];
		var n = arrayLen(arguments.args);
		var i = 1;
		while (i <= n) {
			var a = arguments.args[i];
			if (left(a, 2) == "--") {
				// Space-style flag with a value? Consume the value too.
				// Boolean flags take no value.
				var booleans = "--dry-run,--force,--confirm";
				if (!find("=", a) && !listFindNoCase(booleans, a) && i < n && left(arguments.args[i+1], 2) != "--") {
					i++; // consume value
				}
				i++;
				continue;
			}
			arrayAppend(out, a);
			i++;
		}
		return out;
	}

	// ─────────────────────────────────────────────────
	//  stats — Code statistics
	// ─────────────────────────────────────────────────

	/**
	 * hint: Show code statistics for your Wheels application
	 */
	public string function stats() {
		var verbose = parseVerboseFlag(structuredArgs(arguments));

		var svc = getService("stats");
		var data = svc.getStats();

		out("Code Statistics", "bold");
		out(repeatString("=", 70));

		// Header
		var fmt = "%-14s %6s %7s %10s %8s %7s";
		out(sprintf(fmt, "Category", "Files", "LOC", "Comments", "Blanks", "Total"));
		out(repeatString("-", 70));

		// Rows
		for (var cat in data.categories) {
			out(sprintf(fmt,
				cat.name,
				cat.files,
				cat.loc,
				cat.comments,
				cat.blanks,
				cat.total
			));
		}

		out(repeatString("-", 70));
		out(sprintf(fmt,
			"Total",
			data.totals.files,
			data.totals.loc,
			data.totals.comments,
			data.totals.blanks,
			data.totals.total
		));
		out("");
		out("Code-to-test ratio: 1:#data.codeToTestRatio#");
		out("Average lines/file: #data.avgLinesPerFile#");

		if (verbose && arrayLen(data.topFiles)) {
			out("");
			out("Top 10 Largest Files:", "bold");
			for (var f in data.topFiles) {
				out("  #f.lines# lines  #f.path#");
			}
		}

		return "";
	}

	// ─────────────────────────────────────────────────
	//  notes — Code annotations
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels notes` arguments. Named-only (no positional), so the legacy
	 * getArgs() arg1-gate dropped --annotations / --custom entirely; ArgSpec
	 * consumes them directly.
	 */
	private struct function parseNotesArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.option(name = "annotations", default = "TODO,FIXME,OPTIMIZE")
			.option(name = "custom", default = "")
			.parse(arguments.coll);
		return { annotations = parsed.annotations, custom = parsed.custom };
	}

	/**
	 * hint: Extract TODO, FIXME, and other annotations from your codebase
	 */
	public string function notes() {
		var opts = parseNotesArgs(structuredArgs(arguments));
		var annotations = opts.annotations;
		var custom = opts.custom;

		var svc = getService("stats");
		var data = svc.getNotes(annotations, custom);

		if (data.total == 0) {
			out("No annotations found.", "green");
			return "";
		}

		for (var aType in data.types) {
			var items = data.annotations[aType];
			if (!arrayLen(items)) continue;

			out("#aType# (#arrayLen(items)#):", "yellow");
			for (var item in items) {
				var desc = len(item.text) ? " -- #item.text#" : "";
				out("  #item.file#:#item.line##desc#");
			}
			out("");
		}

		// Summary line
		var parts = [];
		for (var aType in data.types) {
			var count = arrayLen(data.annotations[aType]);
			if (count) arrayAppend(parts, "#count# #aType#");
		}
		out("Summary: #data.total# annotations (#arrayToList(parts, ', ')#)", "cyan");

		return "";
	}

	// ─────────────────────────────────────────────────
	//  db — Database management
	// ─────────────────────────────────────────────────

	/**
	 * hint: Database management commands (reset, status, version)
	 */
	public string function db() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));

		if (!arrayLen(args)) {
			out("Usage: wheels db <command>", "yellow");
			out("");
			out("Commands:", "bold");
			out("  reset    Run pending migrations and reseed the database");
			out("  status   Show migration status (applied vs pending)");
			out("  version  Show current database schema version");
			out("");
			out("Examples:", "bold");
			out("  wheels db reset");
			out("  wheels db reset --skip-seed");
			out("  wheels db status");
			out("  wheels db status --pending");
			out("  wheels db version --detailed");
			return "";
		}

		var subcommand = lCase(args[1]);

		switch (subcommand) {
			case "reset":
				return dbReset(args);
			case "status":
				return dbStatus(args);
			case "version":
				return dbVersion(args);
			default:
				out("Unknown db command: #subcommand#", "red");
				out("Valid commands: reset, status, version");
				throw(type = "Wheels.InvalidArguments", message = "Unknown db command: #subcommand#");
		}
	}

	// ─────────────────────────────────────────────────
	//  upgrade — Upgrade assistance
	// ─────────────────────────────────────────────────

	/**
	 * Parse `wheels upgrade` arguments. `subcommand` (positional) must be
	 * "check"; `--to=<version>` selects the target. `sawTo` / `sawDryRun` drive
	 * the "did you mean" nudge and match both `--to` and `--to=x` (LuCLI maps a
	 * bare `--to` to to=true and `--to=x` to to=x — either way the key exists).
	 */
	private struct function parseUpgradeArgs(required struct coll) {
		var parsed = new services.ArgSpec()
			.positional(name = "subcommand", default = "")
			.option(name = "to", default = "")
			.parse(arguments.coll);
		return {
			isCheck = lCase(parsed.subcommand) == "check",
			targetVersion = parsed.to,
			sawTo = structKeyExists(arguments.coll, "to"),
			sawDryRun = structKeyExists(arguments.coll, "dry-run")
		};
	}

	/**
	 * hint: Scan your app for breaking changes before upgrading Wheels (read-only)
	 *
	 * This command does NOT perform the upgrade. It only scans the current app
	 * for code paths that will break against a target framework version. The
	 * actual framework swap is performed by your package manager
	 * (`brew upgrade wheels`, `scoop update wheels`, or the equivalent).
	 *
	 * Despite occasional appearances in older help output, `--dry-run` is not
	 * supported — the command is already read-only by design.
	 *
	 * Examples:
	 *   wheels upgrade check                 - scan against the latest stable release
	 *   wheels upgrade check --to=4.0.0      - scan against a specific target version
	 */
	public string function upgrade() {
		var opts = parseUpgradeArgs(structuredArgs(arguments));

		if (!opts.isCheck) {
			var nl = chr(10);
			var help = "Usage: wheels upgrade check [--to=<version>]" & nl
				& nl
				& "Scans your app for breaking changes between Wheels versions." & nl
				& "This command is read-only — it does not modify vendor/wheels/." & nl
				& nl
				& "Options:" & nl
				& "  --to=<version>    Target Wheels version (default: latest stable)" & nl
				& nl
				& "Unsupported flags:" & nl
				& "  --dry-run is not supported — the command is already read-only," & nl
				& "                              so there is no dry-run mode to opt into." & nl
				& nl
				& "To actually install a new Wheels version, run:" & nl
				& "  brew upgrade wheels       (macOS / Homebrew)" & nl
				& "  scoop update wheels       (Windows / Scoop)" & nl;

			// Nudge the two common misfires from the legacy help text toward the
			// right invocation explicitly (detected during parse).
			if (opts.sawDryRun || opts.sawTo) {
				help &= nl & "Did you mean: wheels upgrade check"
					& (opts.sawTo ? " --to=<version>" : "")
					& " ?" & nl;
			}

			out(help, "yellow");
			return help;
		}

		return runUpgradeCheck(opts.targetVersion);
	}

	// ─────────────────────────────────────────────────
	//  browser — Browser testing management
	// ─────────────────────────────────────────────────

	/**
	 * hint: Browser testing commands (setup, test)
	 */
	public string function browser() {
		var args = new services.ArgSpec().toArgv(structuredArgs(arguments));

		if (!arrayLen(args)) {
			out("Usage: wheels browser <command>", "yellow");
			out("");
			out("Commands:", "bold");
			out("  setup    Download Playwright JARs and browser binaries");
			out("  test     Run browser test suite");
			out("");
			out("Examples:", "bold");
			out("  wheels browser setup");
			out("  wheels browser setup --force");
			out("  wheels browser test");
			out("  wheels browser test --verbose");
			return "";
		}

		var subcommand = lCase(args[1]);

		switch (subcommand) {
			// `setup` is the canonical verb. `install` is accepted but warned —
			// LuCLI intercepts `install` as its built-in extension installer
			// before it reaches a module's dispatch, so users typing
			// `wheels browser install` actually invoke the LuCLI built-in and
			// see "Reading lucee.json... No git or extension dependencies to
			// install" instead of the Playwright fetch. The case branch here
			// only fires if the user reaches us via some other path (e.g. an
			// argument vector that bypasses LuCLI's parsing). See issue #2332.
			case "setup":
				return browserInstall(args);
			case "install":
				out("'wheels browser install' is intercepted by LuCLI's built-in", "yellow");
				out("extension installer and won't reach this module. Use:", "yellow");
				out("  wheels browser setup", "bold");
				return "";
			case "test":
				return browserTest(args);
			default:
				out("Unknown browser command: #subcommand#", "red");
				out("Valid commands: setup, test");
				return "";
		}
	}

	// ═════════════════════════════════════════════════
	//  PRIVATE — Implementation details
	// ═════════════════════════════════════════════════

	// ── Code Generation ──────────────────────────────

	private string function generateModel(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate model <Name> [properties...]", "yellow");
			out("  Example: wheels generate model User name email:string active:boolean");
			return "";
		}

		var modelName = capitalize(args[1]);
		var properties = args.len() > 1 ? args.slice(2) : [];

		// Parse properties and associations from args
		var parsed = parseGeneratorArgs(properties);

		// Use CodeGen service with template files
		var codegen = getService("codegen");
		var validation = codegen.validateName(modelName, "model");
		if (!validation.valid) {
			out("Invalid model name: #arrayToList(validation.errors, '; ')#", "red");
			return "";
		}

		var result = codegen.generateModel(
			name = modelName,
			properties = parsed.properties,
			belongsTo = arrayToList(parsed.belongsTo),
			hasMany = arrayToList(parsed.hasMany),
			hasOne = arrayToList(parsed.hasOne)
		);

		if (result.success) {
			printCreated("app/models/#modelName#.cfc");
		} else {
			out(result.error, "red");
			return "";
		}

		// Also generate migration if properties provided
		if (arrayLen(parsed.properties)) {
			var scaffold = getService("scaffold");
			var migrationPath = scaffold.createMigrationWithProperties(modelName, parsed.properties);
			var migrationFileName = listLast(migrationPath, "/\");
			printCreated("app/migrator/migrations/#migrationFileName#");
		}

		return "";
	}

	private string function generateController(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate controller <Name> [actions...]", "yellow");
			out("  Example: wheels generate controller Users index show create");
			return "";
		}

		var controllerName = capitalize(args[1]);
		var actions = args.len() > 1 ? args.slice(2) : [];

		var codegen = getService("codegen");
		var result = codegen.generateController(name = controllerName, actions = actions);

		if (result.success) {
			printCreated("app/controllers/#controllerName#.cfc");
		} else {
			out(result.error, "red");
			return "";
		}

		// Create view files for non-mutation actions
		var viewDir = variables.projectRoot & "/app/views/#lCase(controllerName)#";
		ensureDirectory(viewDir);

		for (var action in actions) {
			if (!listFindNoCase("create,update,delete,destroy", action)) {
				var viewResult = codegen.generateView(name = controllerName, action = action);
				if (viewResult.success) {
					printCreated("app/views/#lCase(controllerName)#/#lCase(action)#.cfm");
				} else {
					// Warn instead of silently skipping — a controller reporting
					// success with no views written is misleading. CLI audit M3.
					out("  skip    app/views/#lCase(controllerName)#/#lCase(action)#.cfm: " & (viewResult.error ?: "generation failed"), "yellow");
				}
			}
		}

		return "";
	}

	private string function generateView(required array args) {
		if (arrayLen(args) < 2) {
			out("Usage: wheels generate view <controller> <action>", "yellow");
			return "";
		}

		var controllerName = args[1];
		var actionName = lCase(args[2]);

		var codegen = getService("codegen");
		var result = codegen.generateView(name = controllerName, action = actionName);

		if (result.success) {
			printCreated("app/views/#lCase(controllerName)#/#actionName#.cfm");
		} else {
			out(result.error, "red");
		}
		return "";
	}

	private string function generateMigration(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate migration <Name>", "yellow");
			out("  Example: wheels generate migration AddEmailToUsers");
			return "";
		}

		var migrationName = args[1];
		var timestamp = getService("helpers").generateMigrationTimestamp();
		var fileName = "#timestamp#_#migrationName#.cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";
		var filePath = migrationDir & "/#fileName#";

		ensureDirectory(migrationDir);

		// Always build the migration inline. The shipped codegen template
		// dbmigrate/blank.txt carries |DBMigrateExtends|/|DBMigrateDescription|
		// tokens that Templates.cfc never substitutes, so on packaged installs
		// (where that template resolves) `generate migration` produced an
		// uncompilable file (literal extends="|DBMigrateExtends|"). The inline
		// builder emits a correct extends="wheels.migrator.Migration" body and
		// was already the path every dev-checkout install used. See CLI audit H4.
		fileWrite(filePath, buildEmptyMigration(migrationName));

		printCreated("app/migrator/migrations/#fileName#");
		return "";
	}

	private string function generateScaffold(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate scaffold <Name> [properties...] [--force]", "yellow");
			out("  Example: wheels generate scaffold Post title body:text publishedAt:datetime");
			return "";
		}

		var modelName = capitalize(args[1]);
		var controllerName = getService("helpers").pluralize(modelName);
		var properties = args.len() > 1 ? args.slice(2) : [];

		// Extract --force from args before parseGeneratorArgs (which doesn't
		// handle flags). Issue #2327: previously --force was silently dropped,
		// so scaffolding over an existing model was impossible from the CLI.
		var force = false;
		var filteredProperties = [];
		for (var a in properties) {
			if (a == "--force") {
				force = true;
			} else {
				arrayAppend(filteredProperties, a);
			}
		}

		out("Scaffolding #modelName#...", "cyan");
		out("");

		var parsed = parseGeneratorArgs(filteredProperties);

		var scaffold = getService("scaffold");
		var results = scaffold.generateScaffold(
			name = modelName,
			properties = parsed.properties,
			belongsTo = arrayToList(parsed.belongsTo),
			hasMany = arrayToList(parsed.hasMany),
			hasOne = arrayToList(parsed.hasOne),
			force = force
		);

		if (results.success) {
			for (var item in results.generated) {
				var relPath = listLast(item.path, "/\");
				printCreated("#item.type#: #relPath#");
			}
			// Issue #2327: scaffold can succeed with skipped artifacts. Surface
			// what was skipped so users know why their existing model wasn't
			// touched and how to force a rewrite if they wanted one.
			for (var note in results.skipped ?: []) {
				out("  skip    #note#", "yellow");
			}

			out("");
			out("Scaffold complete! Next steps:", "green");
			out("  1. Run migrations: wheels migrate latest");
			out("  2. Start server: wheels start");
		} else {
			out("Scaffold failed:", "red");
			for (var err in results.errors) {
				out("  #err#", "red");
			}
		}

		return "";
	}

	private string function generateRoute(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate route <name>", "yellow");
			out("  Example: wheels generate route posts");
			return "";
		}

		var routeName = lCase(args[1]);
		var routesPath = variables.projectRoot & "/config/routes.cfm";

		if (!fileExists(routesPath)) {
			out("config/routes.cfm not found.", "red");
			return "";
		}

		// Check for duplicate before delegating
		var content = fileRead(routesPath);
		var resourceRoute = '.resources("' & routeName & '")';
		if (findNoCase(resourceRoute, content)) {
			out("Route already exists: #resourceRoute#", "yellow");
			return "";
		}
		// Also detect the named-arg form (e.g. .resources(name="posts", only="...")),
		// which updateRoutes() treats as a duplicate. Without this, an existing
		// named-arg route was misreported as "Could not find insertion point". M5.
		var namedArgPattern = "\.resources\s*\([^)]*name\s*=\s*[""']" & routeName & "[""']";
		if (reFindNoCase(namedArgPattern, content)) {
			out("Route already exists: .resources(name=""#routeName#"", ...)", "yellow");
			return "";
		}

		// Delegate to Scaffold service for the actual route insertion
		var scaffold = getService("scaffold");
		var inserted = scaffold.updateRoutes(routeName);

		if (inserted) {
			out("  route   #resourceRoute# added to config/routes.cfm", "green");
		} else {
			out("Could not find insertion point in routes.cfm. Add manually:", "yellow");
			out("  #resourceRoute#");
		}

		return "";
	}

	private string function generateTest(required array args) {
		// Pull --force out of the positional args so it can appear anywhere.
		var force = false;
		var pos = [];
		for (var a in args) { if (a == "--force") { force = true; } else { arrayAppend(pos, a); } }

		if (arrayLen(pos) < 2) {
			out("Usage: wheels generate test <type> <Name> [--force]", "yellow");
			out("  Types: model, controller");
			out("  Example: wheels generate test model User");
			return "";
		}

		var testType = lCase(pos[1]);
		var testName = capitalize(pos[2]);

		if (!listFindNoCase("model,controller", testType)) {
			out("Unknown test type: #testType#. Use 'model' or 'controller'.", "red");
			return "";
		}

		var codegen = getService("codegen");
		var result = codegen.generateTest(type = testType, name = testName, force = force);

		if (result.success) {
			var relPath = listLast(result.path, "/\");
			printCreated(relPath);
		} else {
			out(result.error, "red");
		}

		return "";
	}

	private string function generateProperty(required array args) {
		if (arrayLen(args) < 2) {
			out("Usage: wheels generate property <ModelName> <property:type>", "yellow");
			out("  Example: wheels generate property User email:string");
			return "";
		}

		var modelName = capitalize(args[1]);
		var propArg = args[2];
		var parts = listToArray(propArg, ":");
		var propName = parts[1];
		var propType = arrayLen(parts) > 1 ? parts[2] : "string";

		var tableName = getService("helpers").pluralize(lCase(modelName));
		var timestamp = getService("helpers").generateMigrationTimestamp();
		var migrationName = "Add#capitalize(propName)#To#capitalize(tableName)#";
		var fileName = "#timestamp#_#migrationName#.cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";

		ensureDirectory(migrationDir);

		var colType = mapPropertyType(propType);
		var nl = chr(10);
		var tab = chr(9);
		var content = 'component extends="wheels.migrator.Migration" {' & nl & nl;
		content &= tab & 'function up() {' & nl;
		content &= tab & tab & 'transaction {' & nl;
		content &= tab & tab & tab & 't = changeTable(name="#tableName#");' & nl;
		content &= tab & tab & tab & 't.#colType#(columnNames="#propName#");' & nl;
		content &= tab & tab & tab & 't.change();' & nl;
		content &= tab & tab & '}' & nl;
		content &= tab & '}' & nl & nl;

		content &= tab & 'function down() {' & nl;
		content &= tab & tab & 'transaction {' & nl;
		content &= tab & tab & tab & 'removeColumn(table="#tableName#", columnName="#propName#");' & nl;
		content &= tab & tab & '}' & nl;
		content &= tab & '}' & nl & nl;

		content &= '}' & nl;

		fileWrite(migrationDir & "/" & fileName, content);
		printCreated("app/migrator/migrations/#fileName#");
		out("");
		out("Remember to add validation in app/models/#modelName#.cfc config():", "yellow");
		out('  validatesPresenceOf("#propName#");');

		return "";
	}

	private string function generateApiResource(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate api-resource <Name> [properties...]", "yellow");
			out("  Example: wheels generate api-resource Product name price:decimal sku:string");
			out("");
			out("Generates:");
			out("  Model:      app/models/<Name>.cfc");
			out("  Controller: app/controllers/api/<Names>.cfc (JSON-only, no views)");
			out("  Migration:  app/migrator/migrations/<timestamp>_create_<names>_table.cfc");
			out("  Tests:      tests/specs/models/<Name>Spec.cfc");
			out("              tests/specs/controllers/Api<Names>ControllerSpec.cfc");
			out("  Routes:     .namespace(""api"").resources(name=""<names>"", except=""new,edit"")");
			return "";
		}

		var modelName = capitalize(args[1]);
		var controllerName = getService("helpers").pluralize(modelName);
		var properties = args.len() > 1 ? args.slice(2) : [];

		out("Generating API resource #modelName#...", "cyan");
		out("");

		// Parse properties and associations
		var parsed = parseGeneratorArgs(properties);

		var scaffold = getService("scaffold");
		var results = scaffold.generateApiResource(
			name = modelName,
			properties = parsed.properties,
			belongsTo = arrayToList(parsed.belongsTo),
			hasMany = arrayToList(parsed.hasMany),
			hasOne = arrayToList(parsed.hasOne)
		);

		if (results.success) {
			for (var item in results.generated) {
				var relPath = listLast(item.path, "/\");
				printCreated("#item.type#: #relPath#");
			}

			out("");
			out("API resource complete! Next steps:", "green");
			out("  1. Run migrations: wheels migrate latest");
			out("  2. Start server: wheels start");
			out("  3. Test: curl http://localhost:8080/api/#lCase(controllerName)#.json");
		} else {
			out("API resource generation failed:", "red");
			for (var err in results.errors) {
				out("  #err#", "red");
			}
		}

		return "";
	}

	private string function generateHelper(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate helper <name> [functions...]", "yellow");
			out("  Example: wheels generate helper formatting truncateText formatCurrency");
			return "";
		}

		var helperName = capitalize(args[1]);
		var functions = args.len() > 1 ? args.slice(2) : [];

		// Parse --force flag from functions list
		var force = false;
		var cleanFunctions = [];
		for (var f in functions) {
			if (f == "--force") {
				force = true;
			} else {
				arrayAppend(cleanFunctions, f);
			}
		}

		var codegen = getService("codegen");
		var validation = codegen.validateName(helperName, "helper");
		if (!validation.valid) {
			out("Invalid helper name: #arrayToList(validation.errors, '; ')#", "red");
			return "";
		}

		var result = codegen.generateHelper(
			name = helperName,
			functions = cleanFunctions,
			force = force
		);

		if (result.success) {
			// Derive the actual file name (CodeGen appends "Helper" suffix)
			var fileName = listLast(result.path, "/\");
			printCreated("app/helpers/#fileName#");
		} else {
			out(result.error, "red");
			return "";
		}

		out("");
		out("Helper created! Next steps:", "green");
		out("  1. Edit app/helpers/#fileName# to add your logic");
		out("  2. Include in your controller: new app.helpers.#reReplace(fileName, '\.cfc$', '')#()");
		return "";
	}

	private string function generateSnippets(required array args) {
		var force = false;
		var positional = [];
		for (var arg in args) {
			if (arg == "--force") {
				force = true;
			} else if (left(arg, 2) != "--") {
				arrayAppend(positional, arg);
			}
		}

		// No args or --list: show available snippets
		if (!arrayLen(positional)) {
			return listSnippets();
		}

		var pattern = lCase(positional[1]);

		// "templates" subcommand: copy raw template files (old behavior)
		if (pattern == "templates") {
			return copySnippetTemplates(force);
		}

		// Look up the named snippet pattern
		var snippets = getSnippetRegistry();
		if (!structKeyExists(snippets, pattern)) {
			out("Unknown snippet pattern: #pattern#", "red");
			out("Run 'wheels generate snippets' for available patterns.");
			return "";
		}

		var snippet = snippets[pattern];
		var files = snippet.generate(variables.projectRoot, force);

		out("");
		if (arrayLen(files)) {
			out("#snippet.name# snippet generated (#arrayLen(files)# file(s)):", "green");
			for (var f in files) {
				printCreated(f);
			}
		} else {
			out("All files already exist (use --force to overwrite).", "yellow");
		}

		if (structKeyExists(snippet, "hint") && len(snippet.hint)) {
			out("");
			out(snippet.hint, "cyan");
		}
		return "";
	}

	/**
	 * Generate admin CRUD interface for an existing model
	 */
	private string function generateAdmin(array args = []) {
		if (!arrayLen(arguments.args)) {
			out("Usage: wheels generate admin <modelName> [--force] [--no-routes]", "yellow");
			out("");
			out("Generates an admin controller and views by introspecting an existing model.");
			out("Requires a running server.");
			return "";
		}

		var modelName = capitalize(arguments.args[1]);
		var force = false;
		var noRoutes = false;
		for (var i = 2; i <= arrayLen(arguments.args); i++) {
			if (arguments.args[i] == "--force") force = true;
			if (arguments.args[i] == "--no-routes") noRoutes = true;
		}

		// Write-side guard: admin generation introspects this project's schema
		// over the server, then writes the generated controller/views into cwd.
		// Attaching to a sibling app on a common port would scaffold admin
		// from the WRONG schema into the right project. Refuse the common-port
		// fallback when no project-bound port is configured.
		var serverPort = $requireRunningServer(
			hints = [
				"Admin generation introspects this project's schema — it requires a running server bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			],
			requireProjectConfig = true
		);

		// Introspect the model via the server
		out("Introspecting model: #modelName#...", "cyan");
		try {
			var introspectUrl = "http://localhost:#serverPort#/wheels/cli?command=introspect&model=#modelName#&format=json";
			var response = makeHttpRequest(introspectUrl);
			// parseCliResponse surfaces framework errors via thrown exceptions —
			// issue #2315.
			var modelData = parseCliResponse(response, "Model introspection");
		} catch (any e) {
			out("Error introspecting model: #e.message#", "red");
			return "";
		}

		// Generate admin files
		var svc = getService("admin");
		var result = svc.generateAdmin(modelData=modelData, force=force, noRoutes=noRoutes);

		if (result.success) {
			for (var generated in result.generated) {
				printCreated(generated);
			}
			out("");
			out("Admin interface generated for #modelName#.", "green");
			var adminPath = lCase(getService("helpers").pluralize(modelName));
			out("Visit /admin/#adminPath# after reloading.", "cyan");
		} else {
			for (var err in result.errors) {
				out(err, "red");
			}
		}

		return "";
	}

	/**
	 * List all available snippet patterns
	 */
	private string function listSnippets() {
		out("Usage: wheels generate snippets <pattern> [--force]", "yellow");
		out("");
		out("Available snippet patterns:", "bold");
		out("");
		var snippets = getSnippetRegistry();
		var keys = structKeyArray(snippets);
		arraySort(keys, "textnocase");
		for (var key in keys) {
			var s = snippets[key];
			out("  #key##repeatString(' ', 20 - len(key))##s.description#");
		}
		out("");
		out("Special commands:", "bold");
		out("  templates           Copy raw generator templates to app/snippets/ for customization");
		out("");
		out("Examples:", "bold");
		out("  wheels generate snippets auth");
		out("  wheels generate snippets soft-delete");
		out("  wheels generate snippets api-controller --force");
		out("  wheels generate snippets templates");
		return "";
	}

	/**
	 * Registry of named snippet patterns.
	 * Each entry has: name, description, hint, generate(projectRoot, force) -> array of relative paths
	 */
	private struct function getSnippetRegistry() {
		var snippetDir = getDirectoryFromPath(getCurrentTemplatePath()) & "templates/snippets/";

		return {
			"auth": {
				name: "Authentication",
				description: "Session controller, login view, and auth filter",
				hint: "Add filters(through=""authenticate"") to controllers that need protection.",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var sessionCtrl = fileRead(snippetDir & "auth-sessions-controller.txt");
					var p = writeSnippetFile(projectRoot, "app/controllers/Sessions.cfc", sessionCtrl, force);
					if (len(p)) arrayAppend(created, p);

					var loginView = fileRead(snippetDir & "auth-login-view.txt");
					p = writeSnippetFile(projectRoot, "app/views/sessions/new.cfm", loginView, force);
					if (len(p)) arrayAppend(created, p);

					var authFilter = fileRead(snippetDir & "auth-filter.txt");
					p = writeSnippetFile(projectRoot, "app/snippets/auth-filter.cfm", authFilter, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"soft-delete": {
				name: "Soft Delete",
				description: "Model callbacks for soft delete instead of hard delete",
				hint: "Add this to any model: include(template=""/app/snippets/soft-delete.cfm"").",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "soft-delete-mixin.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/soft-delete.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					var migration = fileRead(snippetDir & "soft-delete-migration.txt");
					p = writeSnippetFile(projectRoot, "app/snippets/soft-delete-migration.cfc", migration, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"api-controller": {
				name: "API Controller",
				description: "JSON API controller with error handling and content negotiation",
				hint: "Rename the component and model references, then add a route: .resources(name=""items"").",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "api-controller.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/api-controller.cfc", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"crud-controller": {
				name: "CRUD Controller",
				description: "Full CRUD controller with flash messages and error handling",
				hint: "Rename the component and model references. Add route: .resources(name=""items"").",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "crud-controller.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/crud-controller.cfc", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"flash-messages": {
				name: "Flash Messages",
				description: "Partial view for displaying flash messages with Bootstrap styling",
				hint: "Include in your layout: ##includePartial(partial=""/shared/flash"")##.",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "flash-messages.txt");
					var p = writeSnippetFile(projectRoot, "app/views/shared/_flash.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"pagination": {
				name: "Pagination",
				description: "Paginated list view with navigation controls",
				hint: "Use with: records = model(""Item"").findAll(page=params.page, perPage=25).",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "pagination-view.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/pagination-view.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"seed-data": {
				name: "Seed Data",
				description: "Database seeding template with seedOnce() examples",
				hint: "Run seeds with: wheels seed.",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "seeds.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/seeds.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					var devContent = fileRead(snippetDir & "seeds-development.txt");
					p = writeSnippetFile(projectRoot, "app/snippets/seeds-development.cfm", devContent, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"mailer": {
				name: "Mailer",
				description: "Email sending with Wheels mailer pattern",
				hint: "Call from controller: new app.mailers.UserMailer().sendWelcome(user).",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "user-mailer.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/user-mailer.cfc", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			}
		};
	}

	/**
	 * Write a snippet file, respecting the force flag.
	 * Returns the relative path if written, empty string if skipped.
	 */
	private string function writeSnippetFile(
		required string projectRoot,
		required string relativePath,
		required string content,
		boolean force = false
	) {
		var fullPath = arguments.projectRoot & "/" & arguments.relativePath;
		if (fileExists(fullPath) && !arguments.force) {
			return "";
		}
		var dir = getDirectoryFromPath(fullPath);
		if (!directoryExists(dir)) {
			directoryCreate(dir, true);
		}
		fileWrite(fullPath, arguments.content);
		return arguments.relativePath;
	}

	/**
	 * Copy raw generator template files to app/snippets/ for customization (original behavior)
	 */
	private string function copySnippetTemplates(boolean force = false) {
		var snippetsDir = variables.projectRoot & "/app/snippets";
		var templates = getService("templates");
		var templateDir = templates.getTemplateDir();

		if (!len(templateDir) || !directoryExists(templateDir)) {
			out("Template directory not found.", "red");
			return "";
		}

		ensureDirectory(snippetsDir);

		var copied = 0;
		var skipped = 0;
		var entries = directoryList(templateDir, false, "name");

		for (var entry in entries) {
			var sourcePath = templateDir & "/" & entry;
			var destPath = snippetsDir & "/" & entry;

			if (directoryExists(sourcePath)) {
				copySnippetDir(sourcePath, destPath, force);
				continue;
			}

			if (fileExists(destPath) && !force) {
				skipped++;
				continue;
			}

			fileCopy(sourcePath, destPath);
			printCreated("app/snippets/#entry#");
			copied++;
		}

		out("");
		if (copied > 0) {
			out("#copied# template(s) copied to app/snippets/", "green");
		}
		if (skipped > 0) {
			out("#skipped# existing file(s) skipped (use --force to overwrite)", "yellow");
		}
		if (copied == 0 && skipped == 0) {
			out("No templates found to copy.", "yellow");
		}

		out("");
		out("Customize templates in app/snippets/ to change generated code.");
		out("Templates in app/snippets/ override defaults for all generators.");
		return "";
	}

	/**
	 * Recursively copy a snippet template subdirectory
	 */
	private void function copySnippetDir(required string source, required string dest, boolean force = false) {
		ensureDirectory(arguments.dest);
		var entries = directoryList(arguments.source, false, "name");
		for (var entry in entries) {
			var sourcePath = arguments.source & "/" & entry;
			var destPath = arguments.dest & "/" & entry;
			if (directoryExists(sourcePath)) {
				copySnippetDir(sourcePath, destPath, arguments.force);
			} else {
				if (!fileExists(destPath) || arguments.force) {
					fileCopy(sourcePath, destPath);
					var relPath = replace(destPath, variables.projectRoot & "/", "");
					printCreated(relPath);
				}
			}
		}
	}

	// ── Migration Execution ──────────────────────────

	private string function runMigration(required string action) {
		var serverPort = $requireRunningServer(
			hints = [
				"Migrations require a running server bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			],
			requireProjectConfig = true
		);

		out("Running migration: #action#...", "cyan");

		var command = "";
		switch (action) {
			case "latest": command = "migrateToLatest"; break;
			case "up":     command = "migrateUp"; break;
			case "down":   command = "migrateDown"; break;
			case "info":   command = "info"; break;
			case "doctor": command = "doctor"; break;
		}

		var migrateUrl = "http://localhost:#serverPort#/wheels/cli?command=#command#&format=json";

		var httpResult = "";
		try {
			httpResult = makeHttpRequest(migrateUrl);
		} catch (any httpErr) {
			throw(
				type    = "MigrationError",
				message = "Migration #action# failed (connection error): #httpErr.message#",
				detail  = httpErr.detail ?: ""
			);
		}

		// parseCliResponse throws Wheels.Cli.CommandFailed on success:false —
		// the previous code silently treated it as success. See issue #2315.
		var result = parseCliResponse(httpResult, "Migration #action#");

		// For `doctor`, switch the output color to yellow when the report
		// signals unhealthy state (orphans or pending migrations). Green
		// on an unhealthy result reads as "everything's fine" when it
		// isn't. Other actions stay green on success.
		var color = "green";
		if (arguments.action == "doctor" && structKeyExists(result, "healthy") && !result.healthy) {
			color = "yellow";
		}

		if (structKeyExists(result, "message") && len(result.message)) {
			out(result.message, color);
		} else {
			out("Migration #action# completed.", color);
		}

		return "";
	}

	private string function runForgetOrPretend(required string command, required array args) {
		// `forget` and `pretend` require an explicit <version> arg plus
		// `--yes` to confirm. Default behavior is to print what would
		// happen and refuse without the flag. See issue #2780.
		var version = "";
		var yes = false;
		for (var i = 2; i <= arrayLen(arguments.args); i++) {
			var a = arguments.args[i];
			if (a == "--yes" || a == "-y") {
				yes = true;
			} else if (!a.startsWith("--")) {
				version = a;
			}
		}

		var verb = arguments.command == "forgetVersion" ? "forget" : "pretend";

		if (!Len(version)) {
			out("Missing required argument: <version>", "red");
			out("Usage:");
			out("  wheels migrate #verb# <version> --yes");
			return "";
		}

		if (!yes) {
			out("This will modify wheels_migrator_versions.", "yellow");
			out("Re-run with --yes to confirm:", "yellow");
			out("  wheels migrate #verb# #version# --yes");
			return "";
		}

		var serverPort = $requireRunningServer(
			hints = [
				"Migration reconciliation requires a running server bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			],
			requireProjectConfig = true
		);

		out("Running #verb# for version #version#...", "cyan");

		// URL-encode version: $sanitiseVersion() on the server side strips
		// non-digits before SQL use (no injection path), but raw URL-special
		// characters (&, =, %) in the CLI argument could still inject
		// spurious query parameters before reaching that point.
		var reconcileUrl = "http://localhost:#serverPort#/wheels/cli?command=#arguments.command#&version=#URLEncodedFormat(version)#&format=json";

		var httpResult = "";
		try {
			httpResult = makeHttpRequest(reconcileUrl);
		} catch (any httpErr) {
			throw(
				type    = "MigrationError",
				message = "#verb# failed (connection error): #httpErr.message#",
				detail  = httpErr.detail ?: ""
			);
		}

		var parsed = isJSON(httpResult) ? deserializeJSON(httpResult) : {success: false, message: "Invalid response"};
		var success = parsed.success ?: false;
		var msg = parsed.message ?: "";

		if (success) {
			out(msg, "green");
		} else {
			out(msg, "red");
		}
		return "";
	}

	private string function runRenameSystemTables(boolean dryRun = false) {
		var serverPort = $requireRunningServer(
			hints = [
				"Renaming system tables requires a running server bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			],
			requireProjectConfig = true
		);

		out(arguments.dryRun ? "Previewing system-table rename..." : "Renaming legacy c_o_r_e_* system tables to wheels_*...", "cyan");

		var renameUrl = "http://localhost:#serverPort#/wheels/cli?command=renameSystemTables&format=json"
			& (arguments.dryRun ? "&dryRun=true" : "");

		var httpResult = "";
		try {
			httpResult = makeHttpRequest(renameUrl);
		} catch (any httpErr) {
			throw(
				type    = "MigrationError",
				message = "Rename failed (connection error): #httpErr.message#",
				detail  = httpErr.detail ?: ""
			);
		}

		var parsed = isJSON(httpResult) ? deserializeJSON(httpResult) : {};
		var success = parsed.success ?: false;
		var message = parsed.message ?: "";
		var renameResult = parsed.renameResult ?: {renamed: [], errors: [], sql: [], skipped: ""};

		if (!success) {
			out("Rename failed.", "red");
			for (var err in (renameResult.errors ?: [])) {
				out("  #err#", "red");
			}
			return "";
		}

		// No-op path: legacy tables not present.
		if (Len(renameResult.skipped ?: "")) {
			out(renameResult.skipped, "yellow");
			return "";
		}

		// Dry-run path: print SQL.
		if (arguments.dryRun) {
			if (ArrayLen(renameResult.sql ?: [])) {
				out("Would execute:");
				for (var sql in renameResult.sql) {
					out("  " & sql, "cyan");
				}
			}
			return "";
		}

		// Success path: print what was renamed.
		out("Renamed:", "green");
		for (var rename in (renameResult.renamed ?: [])) {
			out("  " & rename, "green");
		}
		out("");
		out("Note: the foreign-key constraint name is still `fk_core_level`. Constraint names are scoped to their table and only rename via DROP/CREATE; this is cosmetic and will not affect functionality.", "yellow");

		return "";
	}

	// ── Seed Execution ──────────────────────────────

	private string function runSeed(string mode = "auto", string environment = "") {
		var serverPort = $requireRunningServer(
			hints = [
				"Seeding requires a running server bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			],
			requireProjectConfig = true
		);

		out("Running database seeds...", "cyan");

		var seedUrl = "http://localhost:#serverPort#/wheels/cli?command=dbSeed&format=json&mode=#mode#";
		if (len(environment)) {
			seedUrl &= "&environment=#environment#";
		}

		var httpResult = "";
		try {
			httpResult = makeHttpRequest(seedUrl);
		} catch (any httpErr) {
			throw(
				type    = "SeedError",
				message = "Seeding failed (connection error): #httpErr.message#",
				detail  = httpErr.detail ?: ""
			);
		}

		// parseCliResponse throws Wheels.Cli.CommandFailed on success:false.
		// Previously the result.message check used `result.message` but the
		// framework's outer catch sets `messages` (plural) — see issue #2315.
		var result = parseCliResponse(httpResult, "Seeding");

		if (structKeyExists(result, "totalCreated")) {
			out("Seeded: #result.totalCreated# created, #result.totalSkipped# skipped", "green");
		} else {
			out("Seeding completed.", "green");
		}

		return "";
	}

	// ── DB Commands ─────────────────────────────────

	/**
	 * Reset database: run pending migrations and reseed
	 */
	private string function dbReset(array args = []) {
		var force = false;
		var skipSeed = false;
		for (var arg in arguments.args) {
			if (arg == "--force") force = true;
			if (arg == "--skip-seed") skipSeed = true;
		}

		if (!force) {
			out("This will run pending migrations and reseed the database.", "yellow");
			out("Use --force to confirm: wheels db reset --force", "yellow");
			return "";
		}

		// Step 1: Migrate
		try {
			out("Running migrations...", "cyan");
			runMigration("latest");
		} catch (any e) {
			out("Migration failed: #e.message#", "red");
			return "";
		}

		// Step 2: Seed (unless skipped)
		if (!skipSeed) {
			out("Running seeds...", "cyan");
			runSeed("auto", "");
		}

		out("");
		out("Database reset complete.", "green");
		return "";
	}

	/**
	 * Show migration status
	 */
	private string function dbStatus(array args = []) {
		var pendingOnly = false;
		for (var arg in arguments.args) {
			if (arg == "--pending") pendingOnly = true;
		}

		var serverPort = $requireRunningServer();

		try {
			var statusUrl = "http://localhost:#serverPort#/wheels/cli?command=dbStatus&format=json";
			var response = makeHttpRequest(statusUrl);
			// Use parseCliResponse so a framework success:false surfaces with
			// the canonical `messages` payload instead of leaving the user
			// guessing why the status command "failed". See issue #2315.
			var data = parseCliResponse(response, "Database status");

			out("Migration Status", "bold");
			out(repeatString("=", 70));

			var fmt = "%-16s %-30s %-10s %-19s";
			out(sprintf(fmt, "Version", "Description", "Status", "Applied"));
			out(repeatString("-", 70));

			for (var m in data.migrations) {
				if (pendingOnly && m.status != "pending") continue;

				var statusColor = m.status == "applied" ? "green" : "yellow";
				var appliedAt = structKeyExists(m, "appliedAt") && len(m.appliedAt) ? m.appliedAt : "-";
				out(sprintf(fmt, m.version, left(m.description, 30), m.status, appliedAt), statusColor);
			}

			out("");
			out("Total: #data.summary.total# | Applied: #data.summary.applied# | Pending: #data.summary.pending#", "cyan");

		} catch (any e) {
			out("Error fetching migration status: #e.message#", "red");
		}

		return "";
	}

	/**
	 * Show current database schema version
	 */
	private string function dbVersion(array args = []) {
		var detailed = false;
		for (var arg in arguments.args) {
			if (arg == "--detailed") detailed = true;
		}

		var serverPort = $requireRunningServer();

		try {
			var versionUrl = "http://localhost:#serverPort#/wheels/cli?command=dbVersion&format=json";
			var response = makeHttpRequest(versionUrl);
			// Use parseCliResponse so framework errors surface — issue #2315.
			var data = parseCliResponse(response, "Database version");

			out("Database version: #data.version#", "bold");

			if (detailed) {
				// Also fetch status for extra detail
				var statusUrl = "http://localhost:#serverPort#/wheels/cli?command=dbStatus&format=json";
				var statusResponse = makeHttpRequest(statusUrl);
				var statusData = parseCliResponse(statusResponse, "Database status");

				if (arrayLen(statusData.migrations)) {
					// Find last applied migration
					var lastApplied = "";
					for (var m in statusData.migrations) {
						if (m.status == "applied") lastApplied = m;
					}
					if (isStruct(lastApplied)) {
						var appliedAt = structKeyExists(lastApplied, "appliedAt") && len(lastApplied.appliedAt) ? lastApplied.appliedAt : "unknown";
						out("Last migration:   #lastApplied.description# (applied #appliedAt#)");
					}

					out("Total migrations: #statusData.summary.total#");
					out("Pending:          #statusData.summary.pending#");

					// Show next pending
					if (statusData.summary.pending > 0) {
						for (var m in statusData.migrations) {
							if (m.status == "pending") {
								out("Next:             #m.version# -- #m.description#");
								break;
							}
						}
					}
				}
			}

		} catch (any e) {
			out("Error fetching database version: #e.message#", "red");
		}

		return "";
	}

	// ── Upgrade Check ────────────────────────────────

	/**
	 * Scan app for breaking changes between current and target version.
	 */
	private string function runUpgradeCheck(string targetVersion = "") {
		// Detect current version. Prefer wheels.json (post-rename) and fall back
		// to box.json so apps with pre-rename vendor/wheels/ committed in their
		// repo still work. The fallback can be removed two releases after the
		// wheels.json rename ships in stable.
		var manifestPath = variables.projectRoot & "/vendor/wheels/wheels.json";
		if (!fileExists(manifestPath)) {
			manifestPath = variables.projectRoot & "/vendor/wheels/box.json";
		}
		var currentVersion = "unknown";
		if (fileExists(manifestPath)) {
			try {
				var manifestData = deserializeJSON(fileRead(manifestPath));
				currentVersion = manifestData.version ?: "unknown";
			} catch (any e) {}
		}

		// Determine target version
		var target = arguments.targetVersion;
		if (!len(target)) {
			try {
				var apiUrl = "https://api.github.com/repos/wheels-dev/wheels/releases/latest";
				var response = makeHttpRequest(apiUrl);
				var releaseData = deserializeJSON(response);
				target = replace(releaseData.tag_name, "v", "");
			} catch (any e) {
				out("Could not fetch latest version. Use --to=<version> to specify.", "yellow");
				return "";
			}
		}

		out("Current version: #currentVersion#", "bold");
		out("Target version:  #target#", "bold");
		out("");

		// Compare major versions
		var currentMajor = val(listFirst(currentVersion, "."));
		var targetMajor = val(listFirst(target, "."));
		var sameMajor = (currentMajor == targetMajor);

		if (sameMajor) {
			out("Same major version — no known breaking changes.", "green");
			out("Scanning for opt-in recommendations...", "green");
			out("");
		}

		// Check database. Each entry may set `severity` to either "breaking"
		// (the default — flagged in red, gated by major-version-bump scenarios)
		// or "advisory" (cyan, runs regardless of version-jump — for opt-in
		// convention changes the user can adopt at their convenience).
		var checks = [];

		// 2.x -> 3.x
		if (currentMajor <= 2 && targetMajor >= 3) {
			arrayAppend(checks, {
				description: "Legacy plugin directory",
				pattern: "",
				checkType: "directory",
				path: "app/plugins",
				fix: "Migrate plugins to packages installed under vendor/ (wheels packages add <name>)"
			});
			arrayAppend(checks, {
				description: "Old test base class (wheels.Test)",
				pattern: 'extends\s*=\s*"wheels\.Test"',
				checkType: "grep",
				scanDir: "tests",
				extensions: "cfc",
				fix: 'Change to extends="wheels.WheelsTest"'
			});
		}

		// 3.x -> 4.x
		if (currentMajor <= 3 && targetMajor >= 4) {
			arrayAppend(checks, {
				description: "Legacy plugin directory (deprecated as of 4.0, removed in 5.0)",
				pattern: "",
				checkType: "directory",
				path: "plugins",
				fix: "Migrate plugins to packages installed under vendor/ (wheels packages add <name>)"
			});
			arrayAppend(checks, {
				description: "Old test base class (wheels.Test)",
				pattern: 'extends\s*=\s*"wheels\.Test"',
				checkType: "grep",
				scanDir: "tests",
				extensions: "cfc",
				fix: 'Change to extends="wheels.WheelsTest"'
			});
			arrayAppend(checks, {
				description: "Direct WireBox references",
				pattern: "application\.wirebox",
				checkType: "grep",
				scanDir: "app",
				extensions: "cfc,cfm",
				fix: "Use service() or inject() from the DI container instead"
			});
			// CORS default flip — wildcard "*" → deny-all (#2039). A bare
			// `new wheels.middleware.Cors()` accepts no requests in 4.0.
			arrayAppend(checks, {
				description: "CORS middleware without allowOrigins (deny-all default in 4.0)",
				pattern: "new\s+wheels\.middleware\.Cors\s*\(\s*\)",
				checkType: "grep",
				scanDir: "config",
				extensions: "cfm,cfc",
				fix: 'Pass allowOrigins explicitly: new wheels.middleware.Cors(allowOrigins="https://myapp.com")'
			});
			// RateLimiter hardened defaults (#2024 trustProxy=false, #2088
			// proxyStrategy="last"). Advisory only: the scan flags every
			// RateLimiter invocation regardless of current config, because
			// multi-line argument parsing is out of scope. Users whose
			// config already sets both flags should treat the hit as a
			// reminder to re-verify, not a false positive.
			arrayAppend(checks, {
				description: "RateLimiter middleware — defaults changed in 4.0 (advisory: review config)",
				severity: "advisory",
				pattern: "new\s+wheels\.middleware\.RateLimiter",
				checkType: "grep",
				scanDir: "config",
				extensions: "cfm,cfc",
				fix: 'Advisory check — fires on every RateLimiter usage regardless of current config. 4.0 defaults: trustProxy=false, proxyStrategy="last". If your app sits behind a proxy or load balancer, confirm both flags are set explicitly.'
			});
			// allowEnvironmentSwitchViaUrl defaults to false in production
			// (#2076). Explicit `true` is now a security concern.
			arrayAppend(checks, {
				description: "allowEnvironmentSwitchViaUrl=true (default flipped to false in production)",
				pattern: "allowEnvironmentSwitchViaUrl\s*=\s*true",
				checkType: "grep",
				scanDir: "config",
				extensions: "cfm,cfc",
				fix: "Re-enable only for controlled staging environments. The 4.0 default rejects ?environment=... in production."
			});
			// CSRF key auto-generates when empty (#2054) but cookies rotate
			// on every deploy when that happens. Warn if config/ never sets
			// csrfEncryptionKey.
			arrayAppend(checks, {
				description: "Missing csrfEncryptionKey (CSRF cookies rotate on every deploy)",
				pattern: "csrfEncryptionKey",
				checkType: "grep",
				scanDir: "config",
				extensions: "cfm,cfc",
				absent: true,
				fix: 'Set a stable key: set(csrfEncryptionKey = env("WHEELS_CSRF_KEY")).'
			});
			// `wheels snippets` → `wheels generate snippets` rename (#1852).
			// Scan build / CI scripts; the CLI command is invoked from
			// outside the app's own .cfm/.cfc files.
			arrayAppend(checks, {
				description: "Legacy 'wheels snippets' invocation (renamed to 'wheels generate snippets')",
				pattern: "\bwheels\s+snippets\b",
				checkType: "grep",
				scanTargets: [
					{path: "Makefile"},
					{path: "package.json"},
					{path: ".github/workflows", extensions: "yml,yaml", recurse: true},
					{path: ".", extensions: "sh", recurse: false}
				],
				fix: "Rename to 'wheels generate snippets' in scripts, CI jobs, and IDE integrations."
			});
			// tests/specs/functions/ → tests/specs/functional/ rename (#1872).
			// `pattern` is intentionally empty — `checkType: "directory"` signals on
			// path existence and never reaches the grep loop. Do NOT replace this
			// with a benign regex: `reFindNoCase("", anyString)` matches every line,
			// so a future refactor that unifies the directory and grep branches
			// would silently false-positive on every scanned file otherwise.
			arrayAppend(checks, {
				description: "Legacy tests/specs/functions/ directory (renamed to functional/)",
				pattern: "",
				checkType: "directory",
				path: "tests/specs/functions",
				fix: "Rename to tests/specs/functional/. No code changes required."
			});
			// Vite manifest strictness — viteStrictManifest defaults to true
			// in 4.0 (#2133). Missing manifest entries now throw in
			// production; flag any view that references the helpers so the
			// user knows the default has flipped.
			arrayAppend(checks, {
				description: "Vite asset helpers (viteStrictManifest defaults to true in 4.0)",
				pattern: "viteScriptTag|viteStyleTag|vitePreloadTag",
				checkType: "grep",
				scanDir: "app/views",
				extensions: "cfm,cfc",
				fix: "Missing manifest entries throw Wheels.ViteAssetNotFound in production. Rebuild assets during deploy (npm run build) or set(viteStrictManifest=false) to restore 3.x silent fallback."
			});
			// paginationLinks() deprecation grep (#2714, replacement: paginationNav() per #1930).
			arrayAppend(checks, {
				description: "Deprecated paginationLinks() helper (renamed to paginationNav() in 4.0)",
				pattern: "paginationLinks\s*\(",
				checkType: "grep",
				scanDir: "app/views",
				extensions: "cfm,cfc",
				fix: "Replace paginationLinks() with paginationNav() (the all-in-one nav helper) or compose firstPageLink/previousPageLink/pageNumberLinks/nextPageLink/lastPageLink directly. See https://github.com/wheels-dev/wheels/issues/1930."
			});
		}

		// ─── Advisory entries — run regardless of version-jump ──────────
		// These are opt-in convention recommendations, not breaking changes.
		// They appear in the "Recommended Improvements" section of the
		// scanner output and never fail CI (exit code 0).

		// Suggest opt-in to <name>_id reference columns when t.references()
		// is used and the underscore flag is not yet set. The flag flips
		// the suffix produced by t.references() from `<x>id` to `<x>_id`,
		// matching Wheels model `belongsTo` defaults. See #2781 + #2802.
		//
		// Pre-check the flag across all of config/ before appending — the
		// check-struct schema doesn't support multi-condition AND logic, so
		// emitting the advisory unconditionally would fire on every app that
		// has already opted in (where advisory #2 is the relevant one) and
		// contradict reality. Walk config/ recursively to match advisory #2's
		// `scanDir: "config"` scope — users may set the flag in an
		// environment override file (e.g. config/production/settings.cfm) and
		// reading only config/settings.cfm would miss it (#2808). Comment-
		// strip each file first so a commented-out
		// `// set(useUnderscoreReferenceColumns=true);` doesn't satisfy the
		// guard (Anti-Pattern #14 — same shape as line 970).
		var underscoreFlagAlreadySet = false;
		var configDir = variables.projectRoot & "/config";
		if (directoryExists(configDir)) {
			var configFiles = [];
			for (var ext in ["cfm", "cfc"]) {
				var found = directoryList(configDir, true, "path", "*." & ext);
				for (var f in found) arrayAppend(configFiles, f);
			}
			for (var configFile in configFiles) {
				// `reFindNoCase()` returns the 1-based match position (0 = no
				// match). DO NOT wrap with `len()` — len() coerces the int to
				// a string and measures digit count, so len(0)=1 and len(25)=2
				// are both truthy. Use `> 0` for an unambiguous boolean.
				if (reFindNoCase(
					"useUnderscoreReferenceColumns\s*=\s*true",
					stripCfmlComments(fileRead(configFile))
				) > 0) {
					underscoreFlagAlreadySet = true;
					break;
				}
			}
		}
		if (!underscoreFlagAlreadySet) {
			arrayAppend(checks, {
				description: "t.references() produces legacy `<name>id` columns (opt in to `<name>_id` for `belongsTo` defaults)",
				severity: "advisory",
				pattern: "t\.references\s*\(",
				checkType: "grep",
				scanDir: "app/migrator/migrations",
				extensions: "cfc",
				fix: "Opt into <name>_id naming via `set(useUnderscoreReferenceColumns=true)` in config/settings.cfm. Existing applied migrations are unaffected — only NEW migrations get the new suffix. Apps generated by `wheels new` already opt in by default. See ##2781."
			});
		}

		// Mixed-convention warning: fires when the flag is set, alerting
		// users that legacy migrations (pre-flag) may have left `<x>id`
		// columns in the DB while new migrations will produce `<x>_id`.
		// Informational — the user reads it once and decides if a data
		// migration is needed.
		arrayAppend(checks, {
			description: "useUnderscoreReferenceColumns=true is set — confirm legacy migrations don't conflict",
			severity: "advisory",
			pattern: "useUnderscoreReferenceColumns\s*=\s*true",
			checkType: "grep",
			scanDir: "config",
			extensions: "cfm,cfc",
			fix: "If migrations under app/migrator/migrations/ were applied before this flag was set, the database still has `<name>id` columns. New migrations will create `<name>_id`. For full consistency, write a data migration to rename old reference columns."
		});

		// Run checks. Matched checks land in `issues` (severity=breaking) or
		// `advisories` (severity=advisory); unmatched land in `passed`.
		var issues = [];
		var advisories = [];
		var passed = [];

		for (var check in checks) {
			var severity = structKeyExists(check, "severity") ? check.severity : "breaking";
			var matched = false;
			var matchEntry = {};

			if (check.checkType == "directory") {
				var dirPath = variables.projectRoot & "/" & check.path;
				if (directoryExists(dirPath)) {
					var contents = directoryList(dirPath, false, "name");
					if (arrayLen(contents)) {
						matched = true;
						matchEntry = {description: check.description, fix: check.fix, matches: [check.path & "/"]};
					}
				}
			} else if (check.checkType == "grep") {
				// Build the file set to scan. Checks may use `scanDir` +
				// `extensions` (recursive scan of one directory) and/or
				// `scanTargets` (mixed list of file paths and directory
				// roots — needed by the `wheels snippets` rename check that
				// has to look at Makefile, package.json, .github/workflows/,
				// and top-level *.sh files in one shot).
				var filesToScan = [];

				if (structKeyExists(check, "scanDir") && len(check.scanDir)) {
					var scanPath = variables.projectRoot & "/" & check.scanDir;
					if (directoryExists(scanPath)) {
						for (var ext in listToArray(check.extensions)) {
							var dirFiles = directoryList(scanPath, true, "path", "*." & ext);
							for (var f in dirFiles) arrayAppend(filesToScan, f);
						}
					}
				}

				if (structKeyExists(check, "scanTargets") && isArray(check.scanTargets)) {
					for (var target in check.scanTargets) {
						var targetPath = variables.projectRoot & "/" & target.path;
						if (fileExists(targetPath)) {
							arrayAppend(filesToScan, targetPath);
						} else if (directoryExists(targetPath)) {
							var recurse = structKeyExists(target, "recurse") ? target.recurse : true;
							// Avoid Elvis `?:` on `check.extensions` — Adobe CF
							// throws when the key is absent. The `wheels snippets`
							// check has no top-level `extensions`, so this branch
							// is reached on every Adobe CF run when a target is a
							// directory without its own `extensions` key.
							var exts = structKeyExists(target, "extensions") ? target.extensions
								: (structKeyExists(check, "extensions") ? check.extensions : "");
							for (var ext in listToArray(exts)) {
								var dirFiles2 = directoryList(targetPath, recurse, "path", "*." & ext);
								for (var f in dirFiles2) arrayAppend(filesToScan, f);
							}
						}
					}
				}

				var matches = [];
				for (var filePath in filesToScan) {
					// Strip CFML comments before grepping (Anti-Pattern #14):
					// a commented-out `// t.references(...)` or
					// `/* set(...) */` must not satisfy the pattern. Multi-line
					// block comments collapse and may shift reported line
					// numbers — same tradeoff `stripCfmlComments` callers at
					// lines 970 and 5532 already accept.
					var content = stripCfmlComments(fileRead(filePath));
					var lines = listToArray(content, chr(10), true);
					for (var lineNum = 1; lineNum <= arrayLen(lines); lineNum++) {
						if (reFindNoCase(check.pattern, lines[lineNum])) {
							var relPath = replace(filePath, variables.projectRoot & "/", "");
							arrayAppend(matches, "#relPath#:#lineNum#");
						}
					}
				}

				// `absent: true` inverts the check — warn when the pattern
				// is NOT found anywhere in the scanned set. Used for "you
				// should be setting csrfEncryptionKey somewhere" style
				// checks. If nothing was scannable (e.g. config/ missing),
				// treat as pass to avoid noisy false positives.
				var isAbsent = structKeyExists(check, "absent") && check.absent;
				if (isAbsent) {
					if (arrayLen(filesToScan) && !arrayLen(matches)) {
						matched = true;
						var hint = structKeyExists(check, "scanDir") && len(check.scanDir)
							? check.scanDir & "/ (no occurrences found)"
							: "(no occurrences found)";
						matchEntry = {description: check.description, fix: check.fix, matches: [hint]};
					}
				} else {
					if (arrayLen(matches)) {
						matched = true;
						matchEntry = {description: check.description, fix: check.fix, matches: matches};
					}
				}
			}

			// Bucket the result by severity. Advisories surface as opt-in
			// recommendations alongside (but distinct from) breaking changes.
			if (matched) {
				if (severity == "advisory") {
					arrayAppend(advisories, matchEntry);
				} else {
					arrayAppend(issues, matchEntry);
				}
			} else {
				arrayAppend(passed, check.description);
			}
		}

		// Output — three sections in priority order: Breaking → Recommended → All Clear
		if (arrayLen(issues)) {
			out("Breaking Changes (#arrayLen(issues)# found):", "yellow");
			for (var issue in issues) {
				out("  ! #issue.description#", "yellow");
				for (var match in issue.matches) {
					out("    #match#");
				}
				out("    -> #issue.fix#", "cyan");
				out("");
			}
		}

		if (arrayLen(advisories)) {
			out("Recommended Improvements (#arrayLen(advisories)# found):", "cyan");
			for (var advisory in advisories) {
				out("  ~ #advisory.description#", "cyan");
				for (var match in advisory.matches) {
					out("    #match#");
				}
				// Advisory fix lines are intentionally uncolored so the
				// section header and description carry the cyan accent and
				// opt-in items read lighter than breaking-change fixes
				// (which use cyan on the fix line for stronger emphasis).
				out("    -> #advisory.fix#");
				out("");
			}
		}

		if (arrayLen(passed)) {
			out("All Clear (#arrayLen(passed)# checks):", "green");
			for (var p in passed) {
				out("  + #p#", "green");
			}
		}

		out("");
		out("Upgrade with: brew upgrade wheels");

		return "";
	}

	// ── Test Execution ───────────────────────────────

	private string function runTests(
		string filter = "",
		string reporter = "simple",
		string format = "json",
		boolean verboseOutput = false,
		boolean coreTests = false,
		string db = "sqlite",
		boolean ciMode = false,
		boolean useTestDB = true,
		boolean dbExplicit = false
	) {
		var serverPort = $requireRunningServer([
			"Start one with: wheels start",
			"Or use: bash tools/test-local.sh (auto-manages server)"
		]);

		var testPath = coreTests ? "/wheels/core/tests" : "/wheels/app/tests";

		// Print the suite type with a truthful datasource label. Issue #2489:
		// the previous output echoed `--db` even for app tests where the
		// framework's app-runner ignores `url.db` and uses the user's
		// configured datasource (or `<datasource>_test` when --useTestDB).
		// That misled users into thinking app tests had run against the
		// engine they passed.
		//
		// `--db` is honoured only for `--core` (the framework's matrix self-
		// test, where `wheelstestdb_<db>` is wired up across engines). For
		// app tests, surface the real source-of-truth instead and warn if
		// the user explicitly passed --db.
		if (coreTests) {
			out("Running core tests (#db#)...", "cyan");
		} else {
			var resolvedDataSource = $resolveAppTestDataSource(useTestDB);
			out("Running app tests (#resolvedDataSource#)...", "cyan");
			if (dbExplicit) {
				out("", "yellow");
				out("Warning: --db only applies to --core tests; ignoring for the app suite.", "yellow");
				out("App tests run against the configured app datasource (or", "yellow");
				out("<datasource>_test when --useTestDB is set). To test against a different", "yellow");
				out("engine, point your app's datasource env var at it (or use --core).", "yellow");
				out("See: command-line-tools/wheels-commands/testing##testing-against-different-engines", "yellow");
				out("", "yellow");
			}
		}

		if (len(filter)) {
			// Surface the resolved filter so users see what the auto-prefix
			// (`browser` → `tests.specs.browser`) actually scoped to. Also
			// makes silent server-side fallback visible if anything slips
			// through.
			out("Scope: #filter#", "cyan");
		}

		var testsFailed = false;

		try {
			var testUrl = "http://localhost:#serverPort##testPath#?format=#format#&db=#db#";
			// App tests default to running against the <appname>_test
			// datasource so chapter-6-style manual signups in the dev DB
			// don't bleed into chapter-7 specs. Core tests already pick
			// datasources from url.db so leave them alone.
			if (!coreTests && useTestDB) {
				testUrl &= "&useTestDB=true";
			}
			if (len(filter)) {
				testUrl &= "&directory=#filter#";
			}

			var httpResult = makeHttpRequest(testUrl);

			// Try to parse JSON result
			if (isJSON(httpResult)) {
				var result = deserializeJSON(httpResult);
				var resolvedDir = len(filter)
					? filter
					: (coreTests ? "wheels.tests.specs" : "tests.specs");

				// Reporter dispatch. `--reporter=json` and `--reporter=tap` are
				// the CI-friendly modes; `simple` (default) keeps the colorful
				// human-readable rollup. Without this branch the reporter flag
				// was parsed and passed in but never used (onboarding F12).
				switch (lCase(arguments.reporter)) {
					case "json":
						out(httpResult);
						break;
					case "tap":
						emitTapResults(result);
						break;
					case "simple":
					default:
						displayTestResults(result, verboseOutput, resolvedDir);
				}

				// Record failure so the command can exit non-zero AFTER the output
				// is flushed. Throwing here would be swallowed by the catch below.
				// testing.mdx documents a non-zero exit on failure. CLI audit H6.
				testsFailed = ((result.totalFail ?: 0) + (result.totalError ?: 0)) > 0;
			} else {
				// Could be an HTML error page
				if (reFindNoCase("<html", httpResult)) {
					out("Server returned HTML instead of JSON — possible error page.", "red");
					out("Check server logs or visit the test URL directly.", "yellow");
					verbose(httpResult);
				} else {
					out(httpResult);
				}
			}
		} catch (any e) {
			out("Test execution failed: #e.message#", "red");
		}

		// Exit non-zero when specs failed/errored so CI and shells can detect it.
		// Previously runTests always returned "" → `wheels test` exited 0 even when
		// tests failed, silently green-lighting broken builds. CLI audit H6.
		if (testsFailed) {
			throw(type = "Wheels.TestsFailed", message = "Tests failed — see the report above.");
		}

		return "";
	}

	/**
	 * Emit results in TAP (Test Anything Protocol) v13 format. Used by CI
	 * tooling that consumes a flat list of `ok`/`not ok` lines plus an
	 * optional YAML diagnostic block per failure.
	 *
	 * Spec: https://testanything.org/tap-version-13-specification.html
	 */
	private void function emitTapResults(required any result) {
		if (!isStruct(arguments.result)) {
			out("TAP version 13");
			out("1..0");
			out("##  Bail out! Test runner returned non-struct payload.");
			return;
		}

		// Flatten: walk every spec across every bundle/suite into a sequential
		// list. TAP requires monotonically-numbered tests starting at 1.
		// Mutable state lives on a parent struct so the recursive walker sees
		// it by reference on Adobe CF (closures capture struct refs reliably
		// but plain `var` captures can copy on Adobe — see CLAUDE.md).
		var ctx = {tests: []};
		var walkSuite = function(suite) {
			for (var sp in (suite.specStats ?: [])) {
				arrayAppend(ctx.tests, {
					name: sp.name ?: "(unnamed)",
					status: sp.status ?: "Failed",
					failMessage: sp.failMessage ?: "",
					// failOrigin can be an array of stack-frame structs, not a
					// string. Coerce to a string here so the YAML emitter below
					// (tapEscapeYaml) never receives an array and crashes the
					// whole TAP run on the first failing spec. See CLI audit H6.
					failOrigin: $tapOriginString(sp.failOrigin ?: ""),
					skipped: (sp.status ?: "") == "Skipped"
				});
			}
			// Suite-level errors (e.g. spec-file failed to compile, beforeAll
			// threw) are reported on the suite itself with empty specStats —
			// surface them as a synthetic test so they don't disappear.
			if (
				arrayIsEmpty(suite.specStats ?: [])
				&& listFindNoCase("Failed,Error", suite.status ?: "")
			) {
				arrayAppend(ctx.tests, {
					name: (suite.name ?: "(unnamed suite)") & " (suite-level)",
					status: suite.status,
					failMessage: suite.globalException ?: "",
					failOrigin: "",
					skipped: false
				});
			}
			for (var inner in (suite.suiteStats ?: [])) {
				walkSuite(inner);
			}
		};
		for (var bundle in (arguments.result.bundleStats ?: [])) {
			for (var suite in (bundle.suiteStats ?: [])) {
				walkSuite(suite);
			}
		}

		out("TAP version 13");
		out("1..#arrayLen(ctx.tests)#");
		var i = 0;
		for (var t in ctx.tests) {
			i++;
			var ok = (t.status == "Passed") ? "ok" : "not ok";
			var directive = t.skipped ? " ## SKIP" : "";
			out("#ok# #i# - #t.name##directive#");
			if (t.status != "Passed" && !t.skipped && len(t.failMessage)) {
				// YAML diagnostic block, indented per TAP spec.
				out("  ---");
				out("  message: " & tapEscapeYaml(t.failMessage));
				if (len(t.failOrigin)) {
					out("  origin: " & tapEscapeYaml(t.failOrigin));
				}
				out("  ...");
			}
		}
	}

	/**
	 * Quote a string for safe inclusion in a TAP YAML diagnostic block.
	 * Single-quoted YAML escapes `'` as `''` and forbids unescaped newlines,
	 * so we collapse them to spaces — TAP consumers don't render block scalars.
	 */
	private string function tapEscapeYaml(required string value) {
		var v = replace(arguments.value, chr(13) & chr(10), " ", "all");
		v = replace(v, chr(10), " ", "all");
		v = replace(v, chr(13), " ", "all");
		v = replace(v, "'", "''", "all");
		return "'" & v & "'";
	}

	/**
	 * Coerce a TestBox failOrigin into a single string for the TAP YAML block.
	 * TestBox reports failOrigin as an array of stack-frame structs (Raw_Trace /
	 * template+line), but the TAP emitter needs a scalar — passing the array to
	 * tapEscapeYaml() throws "Cannot cast Array to string" and aborts the run.
	 * See CLI audit H6.
	 */
	private string function $tapOriginString(required any origin) {
		if (isSimpleValue(arguments.origin)) {
			return arguments.origin;
		}
		if (isArray(arguments.origin) && arrayLen(arguments.origin)) {
			var first = arguments.origin[1];
			if (isSimpleValue(first)) {
				return first;
			}
			if (isStruct(first)) {
				if (structKeyExists(first, "Raw_Trace") && len(first.Raw_Trace)) {
					return first.Raw_Trace;
				}
				var tmpl = first.template ?: "";
				if (len(tmpl)) {
					return tmpl & (structKeyExists(first, "line") ? ":" & first.line : "");
				}
			}
		}
		return "";
	}

	private void function displayTestResults(
		required any result,
		boolean verboseOutput = false,
		string testDirectory = ""
	) {
		if (!isStruct(result)) {
			out(serializeJSON(result));
			return;
		}

		// Parse TestBox JSON format
		var totalPass = result.totalPass ?: (result.totalPassed ?: 0);
		var totalFail = result.totalFail ?: (result.totalFailed ?: 0);
		var totalError = result.totalError ?: (result.totalErrors ?: 0);
		var totalDuration = result.totalDuration ?: 0;
		var total = totalPass + totalFail + totalError;

		// Detect specs that failed to compile. TestBox silently skips bundles
		// it can't load, so its "totalPass: 0, totalFail: 0, totalError: 0"
		// reply is indistinguishable from "you have no specs" or "all specs
		// passed an empty run." We probe the disk and warn if the loaded
		// bundle count is lower than the on-disk *Spec.cfc count. See
		// finding #2 in the 2026-04-29 fresh-VM triage.
		var specsFailedToLoad = 0;
		var unloadedSpecPaths = [];
		if (len(arguments.testDirectory)) {
			try {
				var runner = new services.TestRunner(projectRoot = variables.projectRoot);
				var diskCount = runner.countSpecsOnDisk(arguments.testDirectory);
				var loadedCount = (structKeyExists(result, "bundleStats") && isArray(result.bundleStats))
					? arrayLen(result.bundleStats)
					: 0;
				if (diskCount > loadedCount) {
					specsFailedToLoad = diskCount - loadedCount;
					var diskSpecs = runner.listSpecsOnDisk(arguments.testDirectory);
					var loadedNames = {};
					if (loadedCount > 0) {
						for (var b in result.bundleStats) {
							loadedNames[b.name ?: ""] = true;
						}
					}
					for (var p in diskSpecs) {
						if (!structKeyExists(loadedNames, p)) {
							arrayAppend(unloadedSpecPaths, p);
						}
					}
				}
			} catch (any probeErr) {
				// Probe is best-effort — never let it crash the test report.
				verbose("Failed-to-load probe failed: #probeErr.message#");
			}
		}

		if (specsFailedToLoad > 0) {
			out("");
			out("WARN  #specsFailedToLoad# spec file(s) failed to compile and were silently skipped:", "yellow");
			for (var unloaded in unloadedSpecPaths) {
				out("        #unloaded#", "yellow");
			}
			out("        Visit /wheels/app/tests in a browser for the parse-error details.", "yellow");
			out("");
		}

		// Display bundle/suite/spec tree if verbose and bundles exist
		if (arguments.verboseOutput && structKeyExists(result, "bundleStats") && isArray(result.bundleStats)) {
			for (var bundle in result.bundleStats) {
				out("Bundle: #bundle.name ?: 'Unknown'#", "bold");
				if (structKeyExists(bundle, "suiteStats") && isArray(bundle.suiteStats)) {
					for (var suite in bundle.suiteStats) {
						displaySuite(suite, "  ");
					}
				}
			}
			out("");
		}

		// Summary line
		var duration = totalDuration > 0 ? " (#numberFormat(totalDuration / 1000, '0.00')#s)" : "";

		if (totalFail == 0 && totalError == 0) {
			if (specsFailedToLoad > 0) {
				out("#totalPass# passed, #specsFailedToLoad# failed to load#duration#", "yellow");
			} else {
				out("#totalPass# passed#duration#", "green");
			}
		} else {
			var failedToLoadStr = specsFailedToLoad > 0 ? ", #specsFailedToLoad# failed to load" : "";
			out("#totalPass# passed, #totalFail# failed, #totalError# error(s)#failedToLoadStr##duration#", "red");
			out("");

			// Show failure details (skip if verbose already displayed them via displaySuite)
			if (!arguments.verboseOutput) {
				if (structKeyExists(result, "bundleStats") && isArray(result.bundleStats)) {
					for (var bundle in result.bundleStats) {
						if (structKeyExists(bundle, "suiteStats") && isArray(bundle.suiteStats)) {
							displayFailures(bundle.suiteStats);
						}
					}
				}

				// Fallback: check for flat failures array
				if (structKeyExists(result, "failures") && isArray(result.failures)) {
					for (var failure in result.failures) {
						out("  FAIL: #failure.name ?: 'unknown'#", "red");
						if (structKeyExists(failure, "message")) {
							out("    #failure.message#", "yellow");
						}
					}
				}
			}
		}
	}

	private void function displaySuite(required struct suite, string indent = "") {
		out("#indent##suite.name ?: 'Suite'#", "bold");
		if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
			for (var spec in suite.specStats) {
				var status = spec.status ?: "unknown";
				switch (status) {
					case "Passed":
						out("#indent#  [PASS] #spec.name#", "green");
						break;
					case "Failed":
						out("#indent#  [FAIL] #spec.name#", "red");
						if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
							out("#indent#         #spec.failMessage#", "yellow");
						}
						break;
					case "Error":
						out("#indent#  [ERR]  #spec.name#", "red");
						if (structKeyExists(spec, "error") && isStruct(spec.error) && structKeyExists(spec.error, "message")) {
							out("#indent#         #spec.error.message#", "yellow");
						}
						break;
					default:
						out("#indent#  [#uCase(status)#] #spec.name#");
				}
			}
		}
		// Nested suites
		if (structKeyExists(suite, "suiteStats") && isArray(suite.suiteStats)) {
			for (var child in suite.suiteStats) {
				displaySuite(child, indent & "  ");
			}
		}
	}

	private void function displayFailures(required array suites) {
		for (var suite in arguments.suites) {
			if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
				for (var spec in suite.specStats) {
					var status = spec.status ?: "";
					if (status == "Failed" || status == "Error") {
						out("  FAIL: #spec.name ?: 'unknown'#", "red");
						if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
							out("    #spec.failMessage#", "yellow");
						}
						if (structKeyExists(spec, "failOrigin") && isStruct(spec.failOrigin) && structKeyExists(spec.failOrigin, "template")) {
							out("    at #spec.failOrigin.template#:#spec.failOrigin.line ?: '?'#", "yellow");
						}
					}
				}
			}
			// Recurse into nested suites
			if (structKeyExists(suite, "suiteStats") && isArray(suite.suiteStats)) {
				displayFailures(suite.suiteStats);
			}
		}
	}


	// ── New App Scaffolding ──────────────────────────

	private string function scaffoldNewApp(required string appName, struct options = {}) {
		// variables.cwd is already forward-slash-normalized by init(); the
		// concat below stays clean on Windows. $safeDirExists is a final
		// safety net against any cwd that bypasses normalization.
		var targetDir = variables.cwd & "/" & appName;

		if ($safeDirExists(targetDir)) {
			out("Directory already exists: #appName#", "red");
			// Throw so LuCLI exits non-zero instead of silently succeeding and
			// fooling automation (GH #2214). Done before any files are written.
			throw(
				type="Wheels.TargetDirectoryExists",
				message="wheels new #appName#: target directory already exists at #targetDir#"
			);
		}

		// Merge defaults for any missing options
		var opts = {
			port: structKeyExists(options, "port") ? options.port : 8080,
			datasource: structKeyExists(options, "datasource") ? options.datasource : lCase(appName),
			reloadPassword: structKeyExists(options, "reloadPassword") ? options.reloadPassword : generateRandomPassword(),
			luceeAdminPassword: generateRandomPassword(),
			setupH2: structKeyExists(options, "setupH2") ? options.setupH2 : false,
			noSQLite: structKeyExists(options, "noSQLite") ? options.noSQLite : false,
			openBrowser: structKeyExists(options, "openBrowser") ? options.openBrowser : true
		};

		// Resolve the Wheels framework source BEFORE creating any files. A
		// scaffolded app requires vendor/wheels/ to boot, and failing after
		// emitting "create" lines left automation confused (GH #2211). On
		// failure this prints a diagnostic and throws, so the caller sees a
		// non-zero exit code instead of a silent success.
		var wheelsSource = resolveFrameworkSourceOrFail(appName);

		// Open a printCreated() dedup session for the duration of this
		// scaffold. See issue #2311 — the duplicate
		// "create blog/Application.cfc" line was a side-effect of the
		// copyTemplateDir() recursion bug fixed in #2342, but the guard
		// stays here so any future code path that double-emits the same
		// path in one `wheels new` run surfaces as a verbose() diagnostic
		// instead of a confusing user-visible duplicate. Cleanup runs in
		// the finally below so generator commands later in the same
		// process (MCP server, REPL) emit unconditionally.
		variables.$createdPathTracker = {};

		try {

		out("Creating new Wheels application: #appName#...", "cyan");
		out("");

		// Locate the project template directory
		var templateDir = variables.moduleRoot & "templates/app";
		if (!directoryExists(templateDir)) {
			out("Project template not found at: #templateDir#", "red");
			// Indicates a broken install (distribution zip missing templates/app/).
			// Throw so LuCLI exits non-zero — otherwise the partial scaffold from
			// an earlier step would look successful to automation (GH #2214).
			throw(
				type="Wheels.TemplateNotFound",
				message="wheels new #appName#: project template directory not found at #templateDir#"
			);
		}

		// datasourcesBlock: SQLite pair by default; "{}" when --no-sqlite (#2621)
		var context = {
			"appName": appName,
			"datasourceName": opts.datasource,
			"reloadPassword": opts.reloadPassword,
			"luceeAdminPassword": opts.luceeAdminPassword,
			"port": opts.port,
			"shutdownPort": opts.port + 1,
			"openBrowser": opts.openBrowser ? "true" : "false",
			"datasourcesBlock": opts.noSQLite ? "{}" : buildSQLiteDatasourcesBlock(opts.datasource)
		};

		// Copy template directory tree to target, processing placeholders.
		// `rootTargetDir` is passed so recursive calls can compute paths
		// relative to the project root, not the current recursion level —
		// otherwise deeply-nested files print as e.g. `<app>/Model.cfc`
		// instead of `<app>/app/models/Model.cfc`. See issue #2328.
		copyTemplateDir(templateDir, targetDir, appName, context, targetDir);

		// Copy the framework into vendor/wheels/ (source was resolved above).
		copyFrameworkToVendor(wheelsSource, targetDir, appName);

		// Set up embedded database: H2 if explicitly requested, SQLite by default
		if (opts.setupH2) {
			configureH2Database(targetDir, appName, opts.datasource);
		} else if (!opts.noSQLite) {
			configureSQLiteDatabase(targetDir, appName, opts.datasource);
		}

		// Create the default Main controller and index view (not in template
		// because they are app-specific starter content, not framework structure)
		ensureDirectory(targetDir & "/app/views/main");
		var nl = chr(10);
		var tab = chr(9);
		fileWrite(
			targetDir & "/app/controllers/Main.cfc",
			'component extends="Controller" {' & nl & nl & tab & 'function index() {' & nl & tab & tab & '// Default action' & nl & tab & '}' & nl & nl & '}'& nl
		);
		printCreated(appName & "/app/controllers/Main.cfc");

		fileWrite(
			targetDir & "/app/views/main/index.cfm",
			'<h1>Welcome to ' & appName & '</h1>' & nl & '<p>Your Wheels application is running. Edit this file at app/views/main/index.cfm</p>' & nl
		);
		printCreated(appName & "/app/views/main/index.cfm");

		out("");
		out("Application created!", "green");
		out("");
		out("Configuration:", "bold");
		out("  Port:            #opts.port#");
		out("  Datasource:      #opts.datasource#");
		out("  Reload password:      #opts.reloadPassword#");
		out("  Lucee admin password: (see .env — WHEELS_LUCEE_ADMIN_PASSWORD)");
		if (opts.setupH2) {
			out("  Database:        H2 embedded (db/h2/)", "green");
		} else if (!opts.noSQLite) {
			out("  Database:        SQLite (db/development.sqlite)", "green");
		}
		out("");
		out("Next steps:", "bold");
		out("  cd #appName#");
		out("  wheels start");

		// Non-blocking update check. Prints a small hint AFTER the success
		// block if a newer wheels release is available. All errors swallow
		// silently — the user should never be blocked or confused by a
		// failed/slow network check. See services/UpdateChecker.cfc for the
		// channel-aware logic + 24h cache. Wrapped in try/catch as a final
		// belt for any failure mode the service itself doesn't already
		// internalize (e.g., the createObject call throwing).
		try {
			var checker = new services.UpdateChecker();
			var updateResult = checker.check(currentVersion=super.version());
			if (updateResult.hasUpdate) {
				out("");
				out("A newer wheels (#updateResult.channel#) is available: #updateResult.latest# (you have #updateResult.current#)", "yellow");
				out("  Upgrade: #updateResult.upgradeCommand#", "yellow");
			}
		} catch (any e) {
			// Silently swallow — never let an update check delay or break
			// `wheels new`. Log via verbose() so devs can see it with -v.
			try { verbose("Update check failed: " & e.message); } catch (any ignore) {}
		}

		return "";

		} finally {
			// Always close the dedup session so subsequent commands in the
			// same process (long-lived MCP / REPL contexts) emit normally.
			structDelete(variables, "$createdPathTracker");
		}
	}

	/**
	 * Configure H2 embedded database by creating the db directory
	 * and injecting datasource configuration into config/app.cfm.
	 */
	private void function configureH2Database(
		required string targetDir,
		required string appName,
		required string datasourceName
	) {
		var nl = chr(10);
		var tab = chr(9);

		// Create db/h2 directory for H2 data files
		var dbDir = targetDir & "/db/h2";
		ensureDirectory(dbDir);
		printCreated(appName & "/db/h2/");

		// Build H2 datasource configuration for config/app.cfm
		var h2Config = "";
		h2Config &= tab & "// H2 embedded database (configured by wheels new --setup-h2)" & nl;
		h2Config &= tab & 'this.datasources["#datasourceName#"] = {' & nl;
		h2Config &= tab & tab & 'class: "org.h2.Driver",' & nl;
		h2Config &= tab & tab & 'connectionString: "jdbc:h2:file:" & expandPath("../db/h2/#datasourceName#") & ";MODE=MySQL",' & nl;
		h2Config &= tab & tab & 'username: "sa"' & nl;
		h2Config &= tab & "};";

		// Also add a test database datasource
		h2Config &= nl & tab & 'this.datasources["wheelstestdb"] = {' & nl;
		h2Config &= tab & tab & 'class: "org.h2.Driver",' & nl;
		h2Config &= tab & tab & 'connectionString: "jdbc:h2:file:" & expandPath("../db/h2/wheelstestdb") & ";MODE=MySQL",' & nl;
		h2Config &= tab & tab & 'username: "sa"' & nl;
		h2Config &= tab & "};";

		// Inject into config/app.cfm at the CLI-Appends-Here marker
		var appCfmPath = targetDir & "/config/app.cfm";
		if (fileExists(appCfmPath)) {
			var content = fileRead(appCfmPath);
			var marker = tab & "// CLI-Appends-Here";
			if (find(marker, content)) {
				content = replace(content, marker, h2Config & nl & nl & marker, "one");
				fileWrite(appCfmPath, content);
				out("  config  #appName#/config/app.cfm (H2 datasource)", "green");
			}
		}
	}

	/**
	 * Configure SQLite as the zero-config default database by creating the db
	 * directory and injecting datasource configuration into config/app.cfm.
	 * The SQLite JDBC driver is loaded from the standard Lucee classpath
	 * (shipped with the Wheels distribution) rather than via OSGi bundle
	 * resolution, which is currently unreliable on Lucee 7's BundleProvider.
	 */
	private void function configureSQLiteDatabase(
		required string targetDir,
		required string appName,
		required string datasourceName
	) {
		var nl = chr(10);
		var tab = chr(9);

		// Create db directory and empty SQLite files. The template copy already
		// emitted "create <app>/db/" if the template ships an empty db/ dir,
		// so only log creation here when this function actually had to make
		// the directory — avoids the duplicate "create" line. See issue #2328.
		var dbDir = targetDir & "/db";
		var dbDirAlreadyExisted = directoryExists(dbDir);
		ensureDirectory(dbDir);
		fileWrite(dbDir & "/development.sqlite", "");
		fileWrite(dbDir & "/test.sqlite", "");
		if (!dbDirAlreadyExisted) {
			printCreated(appName & "/db/");
		}
		printCreated(appName & "/db/development.sqlite");
		printCreated(appName & "/db/test.sqlite");

		// Build SQLite datasource configuration for config/app.cfm
		var sqliteConfig = "";
		sqliteConfig &= tab & "// SQLite zero-config database (configured by wheels new)" & nl;
		sqliteConfig &= tab & 'this.datasources["#datasourceName#"] = {' & nl;
		sqliteConfig &= tab & tab & 'class: "org.sqlite.JDBC",' & nl;
		sqliteConfig &= tab & tab & 'connectionString: "jdbc:sqlite:" & expandPath("../db/development.sqlite")' & nl;
		sqliteConfig &= tab & "};";

		// Also add a test database datasource
		sqliteConfig &= nl & tab & 'this.datasources["#datasourceName#_test"] = {' & nl;
		sqliteConfig &= tab & tab & 'class: "org.sqlite.JDBC",' & nl;
		sqliteConfig &= tab & tab & 'connectionString: "jdbc:sqlite:" & expandPath("../db/test.sqlite")' & nl;
		sqliteConfig &= tab & "};";

		// Inject into config/app.cfm at the CLI-Appends-Here marker
		var appCfmPath = targetDir & "/config/app.cfm";
		if (fileExists(appCfmPath)) {
			var content = fileRead(appCfmPath);
			var marker = tab & "// CLI-Appends-Here";
			if (find(marker, content)) {
				content = replace(content, marker, sqliteConfig & nl & nl & marker, "one");
				fileWrite(appCfmPath, content);
				out("  config  #appName#/config/app.cfm (SQLite datasource)", "green");
			}
		}
	}

	private string function buildSQLiteDatasourcesBlock(required string datasourceName) {
		var nl = chr(10);
		var pad = "      ";
		var inner = "        ";
		var block = "{" & nl;
		block &= pad & '"#datasourceName#": {' & nl;
		block &= inner & '"class": "org.sqlite.JDBC",' & nl;
		block &= inner & '"database": "#datasourceName#",' & nl;
		block &= inner & '"dbdriver": "Other",' & nl;
		block &= inner & '"dsn": "jdbc:sqlite:{project}/db/development.sqlite",' & nl;
		block &= inner & '"host": "",' & nl;
		block &= inner & '"password": "",' & nl;
		block &= inner & '"username": ""' & nl;
		block &= pad & "}," & nl;
		block &= pad & '"#datasourceName#_test": {' & nl;
		block &= inner & '"class": "org.sqlite.JDBC",' & nl;
		block &= inner & '"database": "#datasourceName#_test",' & nl;
		block &= inner & '"dbdriver": "Other",' & nl;
		block &= inner & '"dsn": "jdbc:sqlite:{project}/db/test.sqlite",' & nl;
		block &= inner & '"host": "",' & nl;
		block &= inner & '"password": "",' & nl;
		block &= inner & '"username": ""' & nl;
		block &= pad & "}" & nl;
		block &= "    }";
		return block;
	}

	/**
	 * Resolve the Wheels framework source or fail fast. Prints a diagnostic
	 * listing every path tried plus a WHEELS_FRAMEWORK_PATH hint, then throws
	 * so LuCLI surfaces a non-zero exit code. Returns the resolved path on
	 * success. Called before any files are created so the caller sees a clean
	 * failure rather than a partial scaffold followed by cleanup (GH #2211).
	 */
	private string function resolveFrameworkSourceOrFail(required string appName) {
		var wheelsSource = resolveFrameworkSource();
		if (len(wheelsSource)) {
			return wheelsSource;
		}

		out("", "red");
		out("Error: Could not locate the Wheels framework source.", "red");
		out("");
		out("A scaffolded app requires vendor/wheels/ to boot. Tried:", "yellow");
		for (var candidate in variables.frameworkSearchPaths ?: []) {
			out("  - #candidate#");
		}
		out("");
		out("If you installed via Homebrew or Chocolatey, the framework source", "yellow");
		out("must be bundled alongside the CLI. If it isn't on disk, the package", "yellow");
		out("is incomplete — please report at https://github.com/wheels-dev/wheels/issues.", "yellow");
		out("");
		out("To fix, any one of these works:", "bold");
		out("  1. Set WHEELS_FRAMEWORK_PATH to point at a vendor/wheels/ directory:");
		out("       WHEELS_FRAMEWORK_PATH=/path/to/vendor/wheels wheels new #appName#");
		out("  2. Run `wheels new` from inside a directory that contains vendor/wheels/");
		out("     (e.g. an existing Wheels project, or a checkout of the wheels repo).");
		out("  3. Download the framework source manually and point at it:");
		out("       ## Pick the wheels-core-<version>.zip for the latest release at:");
		out("       ##   https://github.com/wheels-dev/wheels/releases");
		out("       unzip wheels-core-<version>.zip -d ~/.wheels/modules/wheels/vendor/");
		out("       wheels new #appName#");
		out("");
		out("See: https://guides.wheels.dev/v4-0-0-snapshot/start-here/installing/");

		throw(
			type="Wheels.FrameworkNotFound",
			message="wheels new #appName#: Wheels framework source not found (see output above for search paths and WHEELS_FRAMEWORK_PATH hint)"
		);
	}

	/**
	 * Copy a resolved Wheels framework source into the new application's
	 * vendor/wheels/ directory. The source must already exist — callers should
	 * obtain it via resolveFrameworkSourceOrFail() before any file creation.
	 *
	 * After the raw directory copy, delegates to FrameworkInstaller to rewrite
	 * any unreplaced @build.version@ placeholder in the copied box.json when
	 * the source is a dev checkout of the wheels-dev/wheels monorepo (GH #2279).
	 */
	private void function copyFrameworkToVendor(
		required string wheelsSource,
		required string targetDir,
		required string appName
	) {
		out("Installing Wheels framework from #wheelsSource#...");
		var vendorDir = targetDir & "/vendor/wheels";
		ensureDirectory(vendorDir);
		directoryCopy(wheelsSource, vendorDir, true);
		new services.FrameworkInstaller().rewriteVersionPlaceholder(
			wheelsSource = wheelsSource,
			vendorDir = vendorDir,
			cliVersion = super.version()
		);
		printCreated(appName & "/vendor/wheels/");
	}

	// ─────────────────────────────────────────────────
	//  Datasource bundle staging — fresh-VM F8 fix
	// ─────────────────────────────────────────────────

	/**
	 * Stage the SQLite JDBC driver into the two locations Lucee 7 reads from,
	 * so a fresh `wheels new` SQLite-by-default app can boot, migrate, and
	 * query without manual JAR drops. Idempotent and best-effort.
	 *
	 *   - `<express-root>/lib/ext/` — Tomcat parent classpath. Satisfies
	 *     `Class.forName("org.sqlite.JDBC")` for any caller that uses raw
	 *     JDBC.
	 *
	 *   - `<server-root>/<server-name>/lucee-server/bundles/` — Lucee's OSGi
	 *     bundle store. Required for Lucee's datasource resolver (the path
	 *     that `cfquery` and the Wheels migrator go through). Without this,
	 *     `lib/ext/` alone is not enough — Lucee's bundle loader does not
	 *     fall back to the Tomcat parent classloader for datasource driver
	 *     resolution. See onboarding finding F2.
	 *
	 * The bundled JAR at `cli/lucli/resources/extensions/sqlite/` is the
	 * upstream xerial sqlite-jdbc with a relaxed `Require-Capability` header
	 * (Felix on Java 21 fails on upstream's strict `osgi.ee;version=1.8`
	 * exact-match). See `tools/lucee-extensions/sqlite/build.sh` for the
	 * patch logic.
	 */
	private void function $ensureWheelsBundles() {
		try {
			var stager = new services.BundleStager();
			if (!stager.projectUsesSqliteDatasource(variables.projectRoot)) return;

			var bundleSrc = variables.moduleRoot & "resources/extensions/sqlite/org.xerial.sqlite-jdbc-3.49.1.0.jar";
			if (!fileExists(bundleSrc)) {
				// Dev checkout without the bundle baked in. Skip silently —
				// release tarballs always include it.
				return;
			}

			var lucliHome = $resolveLucliHome();
			if (!len(lucliHome)) return;

			// Two staging targets, both required:
			//
			//   1. lib/ext/ on every Lucee Express install — Tomcat classpath,
			//      where Class.forName("org.sqlite.JDBC") resolves. Mirrors the
			//      brew/chocolatey wrapper's drop strategy.
			//
			//   2. bundles/ on every per-server Lucee context — Lucee 7's
			//      datasource resolver consults its OSGi bundle loader (NOT
			//      the parent Tomcat classloader) when instantiating drivers
			//      for `cfquery`. lib/ext/ alone is not enough: the very first
			//      query against a SQLite datasource fails because Lucee's
			//      bundle resolver can't find the driver, even though
			//      `Class.forName` would. See onboarding finding F2.
			//
			// Both paths are idempotent. Pre-stage runs before LuCLI extracts
			// Express on the very first VM run (so dirs may not exist yet);
			// post-stage runs after, when both dirs are guaranteed to exist.
			stager.stageIntoLibExt(
				bundleSrc = bundleSrc,
				expressRoot = lucliHome & "/express",
				jarFileName = "sqlite-jdbc-3.49.1.0.jar"
			);
			stager.stageIntoServerBundles(
				bundleSrc = bundleSrc,
				serversRoot = lucliHome & "/servers",
				jarFileName = "org.xerial.sqlite-jdbc-3.49.1.0.jar"
			);
		} catch (any e) {
			// Stay out of the way — let LuCLI's server start surface the real
			// error if the bundle was actually needed and we couldn't stage.
		}
	}

	/**
	 * Drop the working rewrite.config template into the project root if the
	 * project doesn't already ship one. Delegates to RewriteConfigInstaller
	 * so the behavior can be unit-tested in isolation.
	 *
	 * Background: LuCLI's bundled-default rewrite.config 404s static assets
	 * for 3.x-conventional directory names like `/miscellaneous/`,
	 * `/javascripts/`, `/stylesheets/`, `/files/`. `wheels new` already
	 * drops the working template; this closes the 3.x → 4.0 upgrade-path
	 * gap. See GH #2626.
	 *
	 * Idempotent and best-effort: a project rewrite.config already in place
	 * is left untouched, and any IO failure is swallowed silently so a
	 * permissions hiccup doesn't block `wheels start`.
	 */
	private void function $ensureProjectRewriteConfig() {
		try {
			var installer = new services.RewriteConfigInstaller();
			var template = variables.moduleRoot & "templates/app/rewrite.config";
			installer.install(
				projectRoot = variables.projectRoot,
				sourceTemplate = template
			);
		} catch (any e) {
			// Don't block `wheels start` on a rewrite.config provisioning
			// hiccup — the user can always drop their own override later.
		}
	}

	/**
	 * True when the given directory has the structural fingerprint of a
	 * Wheels project — currently presence of `config/settings.cfm`, the file
	 * `wheels new` always writes and that no other tool creates. Used by
	 * `start()` and `stop()` to refuse silent fallthrough to LuCLI's `server`
	 * subcommands, which would otherwise register a phantom server context
	 * named after the cwd basename. See onboarding finding F6.
	 *
	 * `box.json` alone is not enough — too many non-Wheels CommandBox
	 * projects ship one — and `Application.cfc` is not enough either since
	 * any CFML codebase has one.
	 */
	private boolean function $isWheelsProjectDir(required string path) {
		if (!len(arguments.path)) return false;
		return fileExists(arguments.path & "/config/settings.cfm");
	}

	/**
	 * Read the HTTP port pinned in the project's lucee.json, or 0 if there is no
	 * lucee.json, no "port" key, or the file can't be parsed. LuCLI writes this
	 * file on first start and honours its port on subsequent starts, so it is the
	 * deterministic port to pre-check for a collision before delegating.
	 */
	private numeric function $readPinnedPort(required string projectRoot) {
		var configFile = arguments.projectRoot & "/lucee.json";
		if (!fileExists(configFile)) return 0;
		try {
			var config = deserializeJSON(fileRead(configFile));
			if (isStruct(config) && structKeyExists(config, "port") && isNumeric(config.port)) {
				return config.port;
			}
		} catch (any e) {
			// Malformed lucee.json — let LuCLI surface its own parse error.
		}
		return 0;
	}

	/**
	 * Wipe the per-server Lucee compiled-class cache so the next request
	 * recompiles every CFC from source. Called from `wheels reload` because
	 * Lucee's default `inspectTemplate=once` setting prevents source-edit
	 * detection — without a physical cache wipe, `?reload=true` only resets
	 * Wheels' application state and edits to models, controllers, and config
	 * keep returning the previously-compiled .class on subsequent requests.
	 * See onboarding finding F5.
	 *
	 * Best-effort: silently swallows per-file failures (a Lucee-locked .class
	 * mid-compile or a Windows file lock) rather than blocking the reload.
	 * The cfclasses directory itself is preserved — Lucee repopulates it on
	 * the next compile.
	 */
	private void function $purgeServerCfclasses() {
		try {
			var lucliHome = $resolveLucliHome();
			if (!len(lucliHome)) return;

			var serverName = $findServerForProject(variables.projectRoot);
			if (!len(serverName)) return;

			var cfclassesDir = lucliHome & "/servers/" & serverName & "/lucee-server/context/cfclasses";
			new services.CfclassesPurger().purge(cfclassesDir);
		} catch (any e) {
			// Don't block reload on cache-purge errors.
		}
	}

	/**
	 * Look up the registered LuCLI server entry whose `.project-path`
	 * matches the given project root. Returns the server name, or empty
	 * string if no match. Used by stop() to detect when `wheels stop`
	 * would be a no-op (not in a registered project dir) so we can offer
	 * the user a list of running servers to target instead.
	 */
	private string function $findServerForProject(required string projectRoot) {
		if (!len(arguments.projectRoot)) return "";
		var lucliHome = $resolveLucliHome();
		if (!len(lucliHome)) return "";
		var serversDir = lucliHome & "/servers";
		if (!directoryExists(serversDir)) return "";

		var canonicalCwd = arguments.projectRoot;
		try {
			canonicalCwd = createObject("java", "java.io.File")
				.init(arguments.projectRoot)
				.getCanonicalPath();
		} catch (any e) {}

		var entries = directoryList(serversDir, false, "name");
		for (var name in entries) {
			var pp = serversDir & "/" & name & "/.project-path";
			if (!fileExists(pp)) continue;
			var registered = trim(fileRead(pp));
			if (len(registered) && registered == canonicalCwd) {
				return name;
			}
		}
		return "";
	}

	/**
	 * Enumerate LuCLI server registry entries that are currently running
	 * (server.pid file present and pid is alive). Returns an array of
	 * {name, port, projectPath} structs. Used by stop()'s no-match
	 * recovery hint. Best-effort — entries we can't read cleanly are
	 * silently skipped.
	 */
	private array function $listRunningWheelsServers() {
		var result = [];
		var lucliHome = $resolveLucliHome();
		if (!len(lucliHome)) return result;
		var serversDir = lucliHome & "/servers";
		if (!directoryExists(serversDir)) return result;

		var entries = directoryList(serversDir, false, "name");
		for (var name in entries) {
			var pidFile = serversDir & "/" & name & "/server.pid";
			if (!fileExists(pidFile)) continue;
			try {
				// LuCLI writes "<pid>:<port>" into server.pid. Split off the
				// pid; ignore the rest (port may be empty / different from
				// the live socket).
				var raw = trim(fileRead(pidFile));
				var pid = listFirst(raw, ":");
				var portFromPid = listLen(raw, ":") > 1 ? listGetAt(raw, 2, ":") : "";
				if (!len(pid) || !isNumeric(pid)) continue;
				if (!$isProcessAlive(pid)) continue;
				var info = { name: name, port: portFromPid, projectPath: "?" };
				var pp = serversDir & "/" & name & "/.project-path";
				if (fileExists(pp)) info.projectPath = trim(fileRead(pp));
				if (!len(info.port)) {
					// Port wasn't in server.pid (older format) — try lucee.json.
					var luceeJson = info.projectPath & "/lucee.json";
					if (fileExists(luceeJson)) {
						try {
							var cfg = deserializeJSON(fileRead(luceeJson));
							if (isStruct(cfg) && structKeyExists(cfg, "port")) info.port = cfg.port;
						} catch (any e) {}
					}
				}
				if (!len(info.port)) info.port = "?";
				arrayAppend(result, info);
			} catch (any e) {}
		}
		return result;
	}

	/**
	 * True if the given POSIX pid is alive. Uses `kill -0` semantics via
	 * Java's ProcessHandle (Java 9+) so we don't shell out.
	 */
	private boolean function $isProcessAlive(required string pid) {
		try {
			var ProcessHandle = createObject("java", "java.lang.ProcessHandle");
			var optional = ProcessHandle.of(javaCast("long", arguments.pid));
			if (optional.isPresent()) {
				return optional.get().isAlive();
			}
		} catch (any e) {}
		return false;
	}

	/**
	 * Scan live JVMs for processes whose `-Dcatalina.base=<lucliHome>/servers/<name>/`
	 * points into this user's LuCLI tree. Used by stop() (onboarding F3) when
	 * neither $findServerForProject nor $listRunningWheelsServers turns up a
	 * match — the registration may have been wiped (`rm -rf ~/.wheels/servers/foo`)
	 * while the underlying java process is still listening on the port. Without
	 * this fallback, `wheels stop` would falsely claim "no server is running."
	 *
	 * Returns an array of `{pid, serverName, registeredPath}` structs. Best-effort
	 * — processes the JVM can't introspect (denied by the OS, missing command
	 * line) are silently skipped.
	 */
	private array function $findStrandedLuceeProcesses() {
		var result = [];
		try {
			var lucliHome = $resolveLucliHome();
			if (!len(lucliHome)) return result;

			// Normalize so the substring match works on Windows backslashes too.
			var serversPrefix = lucliHome & "/servers/";

			var ProcessHandle = createObject("java", "java.lang.ProcessHandle");
			var iter = ProcessHandle.allProcesses().iterator();
			while (iter.hasNext()) {
				try {
					var ph = iter.next();
					var info = ph.info();
					var optCmd = info.commandLine();
					if (!optCmd.isPresent()) continue;
					var cmd = optCmd.get();
					// Match against both "/" and "\" forms — same -D arg, two encodings.
					var marker = "-Dcatalina.base=" & serversPrefix;
					var winMarker = "-Dcatalina.base=" & replace(serversPrefix, "/", "\", "all");
					var hitPos = find(marker, cmd);
					var prefixLen = len(marker);
					if (!hitPos) {
						hitPos = find(winMarker, cmd);
						prefixLen = len(winMarker);
					}
					if (!hitPos) continue;

					var rest = mid(cmd, hitPos + prefixLen, len(cmd));
					// Take everything up to the next whitespace OR path separator that
					// closes the server-name segment.
					var stop = reFind("[\s/\\]", rest);
					var serverName = stop > 0 ? left(rest, stop - 1) : rest;
					if (!len(serverName)) continue;

					arrayAppend(result, {
						pid: ph.pid(),
						serverName: serverName,
						registeredPath: lucliHome & "/servers/" & serverName
					});
				} catch (any e2) {}
			}
		} catch (any e) {}
		return result;
	}

	/**
	 * Resolve the LuCLI home root. Order of resolution:
	 *   1. $LUCLI_HOME if set (e.g. brew wrapper exports $HOME/.wheels).
	 *   2. $HOME/.<lucli.binary.name> — LuCLI auto-roots to ~/.<binary> when
	 *      invoked under a symlinked binary name. `wheels` resolves to
	 *      ~/.wheels/, bare `lucli` resolves to ~/.lucli/.
	 *   3. $HOME/.lucli — final fallback.
	 */
	private string function $resolveLucliHome() {
		var javaSystem = createObject("java", "java.lang.System");
		// 1. Explicit override.
		try {
			var override = javaSystem.getenv("LUCLI_HOME");
			if (!isNull(override) && len(override)) return override;
		} catch (any e) {}
		// 2. Per-binary-name default. LuCLI's bootstrap exports
		//    -Dlucli.binary.name=<name> based on how it was invoked, and
		//    home defaults to ~/.<binary-name>/. So `wheels` invocations
		//    resolve to ~/.wheels/ and bare `lucli` invocations to ~/.lucli/.
		//    Match that resolution exactly so we stage into the same tree
		//    LuCLI itself uses (catalina.base / catalina.home).
		try {
			var userHome = javaSystem.getProperty("user.home");
			if (isNull(userHome) || !len(userHome)) return "";
			try {
				var binaryName = javaSystem.getProperty("lucli.binary.name");
				if (!isNull(binaryName) && len(binaryName)) {
					return userHome & "/." & binaryName;
				}
			} catch (any e) {}
			return userHome & "/.lucli";
		} catch (any e) {}
		return "";
	}

	/**
	 * Resolve the path to a vendor/wheels framework source directory, checking
	 * (in order): the WHEELS_FRAMEWORK_PATH env var, the resolved project
	 * root, and the installed module's own location (e.g. when the LuCLI
	 * module lives inside a wheels checkout at cli/lucli/). Records every
	 * path tried in variables.frameworkSearchPaths so the caller can report
	 * them if nothing is found.
	 */
	private string function resolveFrameworkSource() {
		variables.frameworkSearchPaths = [];

		// 1. Explicit override via environment variable — highest priority.
		//    When the user sets WHEELS_FRAMEWORK_PATH they are giving an
		//    imperative "use this" — if the path doesn't exist, hard-fail
		//    rather than silently falling through to auto-discovery (a stale
		//    or typo'd path could otherwise resolve to a surprising framework
		//    version). See GH #2215.
		var override = "";
		try {
			var javaSystem = createObject("java", "java.lang.System");
			var envValue = javaSystem.getenv("WHEELS_FRAMEWORK_PATH");
			if (!isNull(envValue)) {
				override = envValue;
			}
		} catch (any e) {
			// Env var not accessible in this runtime — treat as unset.
		}
		if (len(trim(override))) {
			arrayAppend(variables.frameworkSearchPaths, override & "  (from $WHEELS_FRAMEWORK_PATH)");
			if ($safeDirExists(override)) {
				return $normalizePath(override);
			}
			throw(
				type="Wheels.FrameworkPathInvalid",
				message="WHEELS_FRAMEWORK_PATH is set to '#override#' but that directory does not exist. Unset the variable to fall back to auto-discovery, or point it at a valid vendor/wheels/ source."
			);
		}

		// 2. Project root (e.g. user ran `wheels new` from inside an existing
		//    Wheels app or a wheels repo checkout).
		if (len(variables.projectRoot)) {
			var projectCandidate = variables.projectRoot & "/vendor/wheels";
			arrayAppend(variables.frameworkSearchPaths, projectCandidate);
			if ($safeDirExists(projectCandidate)) {
				return projectCandidate;
			}
		}

		// 3. Module root — if the LuCLI module itself lives inside a wheels
		//    repo checkout (cli/lucli/), walk up to find vendor/wheels/.
		//    Normalize each canonical path (Windows: backslashes) to
		//    forward slashes so concatenation with "/vendor/wheels" stays
		//    URI-safe — see init().
		if (len(variables.moduleRoot)) {
			var File = createObject("java", "java.io.File");
			var dir = variables.moduleRoot;
			for (var i = 0; i < 6; i++) {
				var candidate = $normalizePath(File.init(dir).getCanonicalPath());
				var frameworkCandidate = candidate & "/vendor/wheels";
				arrayAppend(variables.frameworkSearchPaths, frameworkCandidate);
				if ($safeDirExists(frameworkCandidate)) {
					return frameworkCandidate;
				}
				var parent = File.init(candidate).getParent();
				if (isNull(parent) || parent == candidate) break;
				dir = parent;
			}
		}

		return "";
	}

	/**
	 * Recursively copy a template directory to a target, processing {{variable}}
	 * placeholders in file contents and renaming underscore-prefixed dot files
	 * (e.g. _env -> .env, _gitignore -> .gitignore).
	 */
	private void function copyTemplateDir(
		required string sourceDir,
		required string targetDir,
		required string appName,
		required struct context,
		string rootTargetDir = ""
	) {
		ensureDirectory(arguments.targetDir);

		// `rootTargetDir` is the root of the new app on disk — it stays the
		// same across recursion so `relativePath` is always app-relative,
		// not relative to the current sub-directory. Without this, files
		// emerged from deep recursion (e.g. `<app>/app/models/Model.cfc`)
		// printed as just `<app>/Model.cfc` because the local `targetDir`
		// stripped too much. See issue #2328.
		var rootDir = len(arguments.rootTargetDir) ? arguments.rootTargetDir : arguments.targetDir;

		var entries = directoryList(arguments.sourceDir, false, "query");

		for (var entry in entries) {
			var sourcePath = arguments.sourceDir & "/" & entry.name;
			var targetName = entry.name;

			// Rename _env -> .env, _gitignore -> .gitignore
			if (targetName == "_env") targetName = ".env";
			else if (targetName == "_gitignore") targetName = ".gitignore";

			var targetPath = arguments.targetDir & "/" & targetName;
			var relativePath = arguments.appName & replace(targetPath, rootDir, "");

			if (entry.type == "Dir") {
				ensureDirectory(targetPath);
				printCreated(relativePath & "/");
				// Recurse into subdirectory, carrying rootDir down so
				// per-file relativePaths stay app-relative.
				copyTemplateDir(sourcePath, targetPath, arguments.appName, arguments.context, rootDir);
			} else {
				// .gitkeep files are deliberately preserved as-is — they
				// exist to keep otherwise-empty directories tracked once
				// the user runs `git init && git add -A`. Copy them
				// byte-for-byte (no placeholder processing — they are
				// intentionally empty and have no template syntax).
				// Earlier code skipped them entirely, which defeated their
				// purpose: empty directories vanished on first commit,
				// surprising users who followed the tutorial's chapter 1
				// file tree. See batch B fresh-VM sub-finding (2026-04-29).
				if (entry.name == ".gitkeep") {
					fileCopy(sourcePath, targetPath);
					printCreated(relativePath);
					continue;
				}
				// Read template, process placeholders, write to target
				var content = fileRead(sourcePath);
				content = processPlaceholders(content, arguments.context);
				fileWrite(targetPath, content);
				printCreated(relativePath);
			}
		}
	}

	/**
	 * Replace {{key}} placeholders in content with context values.
	 */
	private string function processPlaceholders(required string content, required struct context) {
		var result = arguments.content;
		for (var key in arguments.context) {
			result = replace(result, "{{#key#}}", arguments.context[key], "all");
		}
		return result;
	}

	// ── Inline Template Fallback ─────────────────────

	private string function buildEmptyMigration(required string migrationName) {
		var nl = chr(10);
		var tab = chr(9);
		var content = "component extends=""wheels.migrator.Migration"" {" & nl & nl;
		content &= tab & "function up() {" & nl;
		content &= tab & tab & "transaction {" & nl;
		content &= tab & tab & tab & "// TODO: Implement migration" & nl;
		content &= tab & tab & "}" & nl;
		content &= tab & "}" & nl & nl;

		content &= tab & "function down() {" & nl;
		content &= tab & tab & "transaction {" & nl;
		content &= tab & tab & tab & "// TODO: Implement rollback" & nl;
		content &= tab & tab & "}" & nl;
		content &= tab & "}" & nl & nl;

		content &= "}" & nl;
		return content;
	}

	// ── Utility Methods ──────────────────────────────

	/**
	 * Parse generator arguments into properties and associations
	 * E.g., ["name", "email:string", "--belongsTo=user", "active:boolean"]
	 */
	private struct function parseGeneratorArgs(required array args) {
		var result = {
			properties: [],
			belongsTo: [],
			hasMany: [],
			hasOne: []
		};

		for (var arg in args) {
			// Named association flags
			if (reFindNoCase("^--belongsTo=", arg)) {
				var rels = listToArray(valueAfterEquals(arg));
				result.belongsTo.append(rels, true);
			} else if (reFindNoCase("^--hasMany=", arg)) {
				var rels = listToArray(valueAfterEquals(arg));
				result.hasMany.append(rels, true);
			} else if (reFindNoCase("^--hasOne=", arg)) {
				var rels = listToArray(valueAfterEquals(arg));
				result.hasOne.append(rels, true);
			} else if (!arg.startsWith("--")) {
				// Property: name, name:type, or name:enum:value1,value2,...
				// Split on the FIRST two colons only — any additional colons
				// (e.g. inside the comma-separated value list) belong in the
				// values segment.
				var parts = listToArray(arg, ":");
				var prop = {
					name: parts[1],
					type: arrayLen(parts) > 1 ? parts[2] : "string"
				};
				if (lCase(prop.type) == "enum" && arrayLen(parts) > 2) {
					// Re-join everything after the second colon so values
					// like "draft,published,archived" land in a single
					// segment. Most cases are arrayLen==3 (no embedded
					// colons), so this is just parts[3] — defensive against
					// pathological inputs.
					var valueSegments = [];
					for (var i = 3; i <= arrayLen(parts); i++) {
						arrayAppend(valueSegments, parts[i]);
					}
					prop.values = arrayToList(valueSegments, ":");
				}
				arrayAppend(result.properties, prop);
			}
		}

		return result;
	}

	/**
	 * Map user-friendly property types to migration column types
	 */
	private string function mapPropertyType(required string type) {
		switch (lCase(type)) {
			case "string": case "varchar": return "string";
			case "text": case "longtext": return "text";
			case "integer": case "int": return "integer";
			case "biginteger": case "bigint": return "bigInteger";
			case "boolean": case "bool": return "boolean";
			case "date": return "date";
			case "datetime": case "timestamp": return "datetime";
			case "time": return "time";
			case "decimal": case "float": case "numeric": return "decimal";
			case "binary": return "binary";
			default: return "string";
		}
	}

	/**
	 * Resolve the Wheels project root from the current working directory.
	 * Walks up from cwd looking for vendor/wheels/ as the marker.
	 */
	private string function resolveProjectRoot(required string cwd) {
		var dir = len(trim(cwd)) ? cwd : ".";
		var File = createObject("java", "java.io.File");

		// Walk up at most 5 levels. Normalize each canonical path to
		// forward slashes before concatenation — see init() for why mixed
		// slashes break Lucee 7 on Windows. $safeDirExists guards against
		// any path that still slips through with a drive-letter scheme.
		for (var i = 0; i < 5; i++) {
			var candidate = $normalizePath(File.init(dir).getCanonicalPath());
			if ($safeDirExists(candidate & "/vendor/wheels")) {
				return candidate;
			}
			// Go up one level
			var parent = File.init(candidate).getParent();
			if (isNull(parent) || parent == candidate) break;
			dir = parent;
		}

		// Fallback: use cwd as-is
		return $normalizePath(
			len(trim(cwd)) ? File.init(cwd).getCanonicalPath() : File.init(".").getCanonicalPath()
		);
	}

	/**
	 * Detect the port of a running Wheels dev server.
	 *
	 * Resolves in priority order: lucee.json `port` field, `.env` PORT
	 * variable, then a hardcoded common-port probe. When
	 * `requireProjectConfig` is true the common-port probe is skipped —
	 * write-side commands (migrate, seed, reconciliation) must only ever
	 * target the server bound to this project's own config, never a
	 * sibling app squatting 8080 (issue #2878).
	 *
	 * `commonPorts` is a test seam — the spec injects a known port to
	 * simulate a sibling app deterministically. Production callers always
	 * get the historical fallback list.
	 *
	 * Kept `private`: LuCLI auto-exposes every public, non-hidden Module
	 * function on the MCP `tools/list` and as a CLI subcommand (see
	 * metadataGetFunctions.cfs + McpCommand BASE_MODULE_INTERNALS +
	 * mcpHiddenTools()), so this internal probe must not be public. The
	 * spec reaches it through TestBox `makePublic()` — see
	 * cli/lucli/tests/specs/services/ServerDetectionSpec.cfc (#2878 review).
	 */
	private any function detectServerPort(
		boolean requireProjectConfig = false,
		array commonPorts = [8080, 60000, 3000, 8500]
	) {
		// 1. Check lucee.json
		var luceeJson = variables.projectRoot & "/lucee.json";
		if (fileExists(luceeJson)) {
			try {
				var config = deserializeJSON(fileRead(luceeJson));
				if (structKeyExists(config, "port") && isPortOpen(config.port)) {
					return config.port;
				}
			} catch (any e) {
				// ignore parse errors
			}
		}

		// 2. Check .env for PORT
		var envFile = variables.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var portMatch = reFindNoCase("PORT\s*=\s*(\d+)", envContent, 1, true);
			if (arrayLen(portMatch.match) > 1 && isNumeric(portMatch.match[2])) {
				var port = val(portMatch.match[2]);
				if (isPortOpen(port)) return port;
			}
		}

		// 3. Refuse the common-port fallback for write-side callers — see
		//    #2878. Without an explicit project-bound port we cannot prove
		//    the server on 8080 belongs to this project, and silently
		//    attaching can run a migration against the wrong database.
		if (arguments.requireProjectConfig) {
			return false;
		}

		// 4. Try common ports (read-side only).
		for (var fallbackPort in arguments.commonPorts) {
			if (isPortOpen(fallbackPort)) return fallbackPort;
		}

		return false;
	}

	/**
	 * Guard for commands that require a live Wheels dev server. Returns the
	 * detected port on success; prints a red diagnostic + any yellow hints
	 * and throws `Wheels.ServerNotRunning` on failure, so LuCLI's Picocli
	 * ExecutionExceptionHandler surfaces a non-zero exit instead of the
	 * previous silent `return ""` (GH #2229).
	 *
	 * `requireProjectConfig=true` switches to the strict server-identity
	 * mode introduced in #2878: write-side commands refuse the common-port
	 * fallback, so a freshly-scaffolded project without lucee.json/.env
	 * port config errors loudly instead of attaching to a sibling app.
	 */
	private numeric function $requireRunningServer(array hints = [], boolean requireProjectConfig = false) {
		var serverPort = detectServerPort(requireProjectConfig = arguments.requireProjectConfig);
		if (serverPort) return serverPort;

		out("No running Wheels server detected.", "red");
		// Fallback hints used only when a caller passes none. Every current
		// write-side caller passes explicit `hints`, so the requireProjectConfig
		// arm below is defensive — it keeps the guidance correct for any future
		// caller that relies on the default.
		var defaultHints = arguments.requireProjectConfig
			? [
				"Write commands refuse to attach to a server not bound to this project.",
				"Set 'port' in lucee.json (or PORT in .env), then start with: wheels start"
			]
			: ["Start one with: wheels start"];
		var hintList = arrayLen(arguments.hints) ? arguments.hints : defaultHints;
		for (var hint in hintList) {
			out(hint, "yellow");
		}
		throw(
			type="Wheels.ServerNotRunning",
			message=arguments.requireProjectConfig
				? "No running Wheels server detected for this project (set 'port' in lucee.json or PORT in .env, then start with: wheels start)"
				: "No running Wheels server detected on any expected port (checked lucee.json, .env, 8080/60000/3000/8500)"
		);
	}

	/**
	 * Detect the reload password from .env or config/settings.cfm
	 */
	private string function detectReloadPassword() {
		// 1. Check .env for WHEELS_RELOAD_PASSWORD (canonical scaffold name) or
		//    the legacy unprefixed RELOAD_PASSWORD. The optional prefix keeps
		//    apps generated before the rename working.
		var envFile = variables.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var pwMatch = reFindNoCase("(?:WHEELS_)?RELOAD_PASSWORD\s*=\s*([^\r\n]+)", envContent, 1, true);
			if (arrayLen(pwMatch.match) > 1 && len(trim(pwMatch.match[2]))) {
				return trim(pwMatch.match[2]);
			}
		}

		// 2. Check config/settings.cfm
		var settingsFile = variables.projectRoot & "/config/settings.cfm";
		if (fileExists(settingsFile)) {
			var settingsContent = fileRead(settingsFile);
			var settingsMatch = reFindNoCase('reloadPassword\s*[=,]\s*"([^"]*)"', settingsContent, 1, true);
			if (arrayLen(settingsMatch.match) > 1) {
				return settingsMatch.match[2];
			}
		}

		return "";
	}

	/**
	 * Resolve the datasource label app tests will actually run against.
	 *
	 * Mirrors `vendor/wheels/tests/app-runner.cfm`'s logic: when `useTestDB`
	 * is true the runner swaps to `<base>_test` if that datasource is
	 * registered, otherwise it falls back to the configured base. We can't
	 * see Lucee's registered-datasources list from this side cheaply, so we
	 * report the optimistic label (`<base>_test`) when useTestDB is on and
	 * the bare base otherwise. Used by `runTests` (#2489) so the CLI's
	 * preamble shows the truth instead of echoing `--db`.
	 *
	 * Detection order matches `detectReloadPassword`: .env first, then
	 * `config/settings.cfm`. Returns "(unknown)" if neither yields a name —
	 * a label, not a fatal error, so the run still proceeds.
	 *
	 * Regex care (also #2489): use \b word-boundaries so `coreTestDataSourceName`
	 * is not picked up as if it were `dataSourceName` (the original reporter
	 * saw `testappdb_test_test` because the previous regex matched the
	 * trailing substring and then doubled the suffix). Strip CFML comments
	 * first so commented-out `set(...)` calls don't poison the lookup —
	 * matches the pattern already used by `info()`.
	 */
	public string function $resolveAppTestDataSource(boolean useTestDB = true) {
		var base = "";

		var envFile = variables.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			// Anchor to start-of-line so an unrelated key whose name happens
			// to end in DATASOURCE_NAME can't match by accident.
			var match = reFindNoCase("(?:^|\n)\s*DATASOURCE_NAME\s*=\s*([^\r\n]+)", envContent, 1, true);
			if (arrayLen(match.match) > 1 && len(trim(match.match[2]))) {
				base = trim(match.match[2]);
			}
		}

		if (!len(base)) {
			var settingsFile = variables.projectRoot & "/config/settings.cfm";
			if (fileExists(settingsFile)) {
				var settingsContent = stripCfmlComments(fileRead(settingsFile));
				var settingsMatch = reFindNoCase('\bdataSourceName\b\s*=\s*"([^"]*)"', settingsContent, 1, true);
				if (arrayLen(settingsMatch.match) > 1 && len(trim(settingsMatch.match[2]))) {
					base = trim(settingsMatch.match[2]);
				}
			}
		}

		if (!len(base)) {
			return "(unknown)";
		}

		if (!arguments.useTestDB) {
			return base;
		}
		// Defensive: never double the suffix. If a user has named their
		// app datasource `myapp_test`, surfacing `myapp_test_test` in the
		// preamble is more confusing than helpful — the runner's own
		// fallback would print the same `myapp_test` we'd return here.
		return reFindNoCase("_test$", base) ? base : base & "_test";
	}

	/**
	 * Check if a port is responding to HTTP requests
	 */
	private boolean function isPortOpen(required numeric port) {
		try {
			var socket = createObject("java", "java.net.Socket");
			socket.init();
			var address = createObject("java", "java.net.InetSocketAddress").init("localhost", javacast("int", port));
			socket.connect(address, javacast("int", 1000));
			socket.close();
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Make an HTTP GET request and return the response body
	 */
	/**
	 * Parse a /wheels/cli? JSON response and surface framework errors.
	 *
	 * The framework's `vendor/wheels/public/views/cli.cfm` endpoint returns
	 * HTTP 200 even when a command fails internally — it sets `success: false`
	 * with the error in `messages` (or `message`). Without surfacing those,
	 * the CLI silently reports "completed" while the underlying op crashed
	 * (e.g. JDBC class not loaded). See issue #2315.
	 *
	 * Behaviour:
	 *   - Returns the parsed struct on `success: true` (or no `success` key).
	 *   - Throws `Wheels.Cli.CommandFailed` with the framework's message
	 *     payload when `success: false`.
	 *   - Throws `Wheels.Cli.UnparseableResponse` when the body isn't JSON
	 *     (typically an HTML error page from a server-side exception).
	 */
	private struct function parseCliResponse(required string httpResult, required string operationLabel) {
		var result = "";
		try {
			result = deserializeJSON(arguments.httpResult);
		} catch (any jsonErr) {
			var detail = reFindNoCase("<html", arguments.httpResult)
				? "Server returned an HTML error page (first 500 chars): " & left(arguments.httpResult, 500)
				: "Raw response (first 500 chars): " & left(arguments.httpResult, 500);
			throw(
				type    = "Wheels.Cli.UnparseableResponse",
				message = "#arguments.operationLabel# returned an unparseable response.",
				detail  = detail
			);
		}

		if (!isStruct(result)) {
			throw(
				type    = "Wheels.Cli.UnparseableResponse",
				message = "#arguments.operationLabel# returned a non-object response.",
				detail  = "Got: " & serializeJSON(result)
			);
		}

		if (structKeyExists(result, "success") && !result.success) {
			var errMsg = "";
			if (structKeyExists(result, "messages") && len(result.messages)) {
				errMsg = result.messages;
			} else if (structKeyExists(result, "message") && len(result.message)) {
				errMsg = result.message;
			} else {
				errMsg = "framework returned success:false with no message";
			}
			throw(
				type    = "Wheels.Cli.CommandFailed",
				message = "#arguments.operationLabel# failed: #errMsg#",
				detail  = serializeJSON(result)
			);
		}

		return result;
	}

	private string function makeHttpRequest(required string requestUrl) {
		var javaUrl = createObject("java", "java.net.URL").init(arguments.requestUrl);
		var conn = javaUrl.openConnection();
		conn.setRequestMethod("GET");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(120000);

		var responseCode = conn.getResponseCode();
		var inputStream = responseCode >= 400 ? conn.getErrorStream() : conn.getInputStream();
		var scanner = createObject("java", "java.util.Scanner").init(inputStream, "UTF-8");
		var response = "";
		while (scanner.hasNextLine()) {
			response &= scanner.nextLine() & chr(10);
		}
		scanner.close();
		return trim(response);
	}

	/**
	 * Make an HTTP POST request with a JSON body and return the response
	 */
	private string function makeHttpPost(required string requestUrl, required string body) {
		var javaUrl = createObject("java", "java.net.URL").init(arguments.requestUrl);
		var conn = javaUrl.openConnection();
		conn.setRequestMethod("POST");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(30000);
		conn.setDoOutput(true);
		conn.setRequestProperty("Content-Type", "application/json");

		// Write request body
		var writer = createObject("java", "java.io.OutputStreamWriter").init(conn.getOutputStream(), "UTF-8");
		writer.write(body);
		writer.flush();
		writer.close();

		// Read response (handle both success and error streams)
		var responseCode = conn.getResponseCode();
		var inputStream = responseCode >= 400 ? conn.getErrorStream() : conn.getInputStream();
		var scanner = createObject("java", "java.util.Scanner").init(inputStream, "UTF-8");
		var response = "";
		while (scanner.hasNextLine()) {
			response &= scanner.nextLine() & chr(10);
		}
		scanner.close();
		return trim(response);
	}

	/**
	 * Get or create a service instance (lazy-loaded with constructor wiring)
	 */
	private any function getService(required string name) {
		if (!structKeyExists(variables.services, name)) {
			switch (name) {
				case "helpers":
					variables.services.helpers = new services.Helpers();
					break;
				case "templates":
					variables.services.templates = new services.Templates(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot,
						moduleRoot = variables.moduleRoot
					);
					break;
				case "codegen":
					variables.services.codegen = new services.CodeGen(
						templateService = getService("templates"),
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "scaffold":
					variables.services.scaffold = new services.Scaffold(
						codeGenService = getService("codegen"),
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "analysis":
					variables.services.analysis = new services.Analysis(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "destroy":
					variables.services.destroy = new services.Destroy(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot,
						moduleRoot = variables.moduleRoot
					);
					break;
				case "doctor":
					variables.services.doctor = new services.Doctor(
						projectRoot = variables.projectRoot,
						installedModuleRoot = variables.moduleRoot
					);
					break;
				case "stats":
					variables.services.stats = new services.Stats(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "admin":
					variables.services.admin = new services.Admin(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot,
						moduleRoot = variables.moduleRoot
					);
					break;
				case "serverRegistry":
					variables.services.serverRegistry = new services.ServerRegistry(
						lucliHome = $resolveLucliHome()
					);
					break;
				case "portProbe":
					variables.services.portProbe = new services.PortProbe();
					break;
				default:
					throw("Unknown service: #name#");
			}
		}
		return variables.services[name];
	}

	/**
	 * Ensure a directory exists, creating it if necessary
	 */
	private void function ensureDirectory(required string path) {
		if (!directoryExists(path)) {
			directoryCreate(path, true);
		}
	}

	/**
	 * Capitalize the first letter of a string
	 */
	private string function capitalize(required string str) {
		return uCase(left(str, 1)) & mid(str, 2, len(str) - 1);
	}

	/**
	 * Print a "create" action line with green formatting.
	 *
	 * When a tracking session is active (started by scaffoldNewApp via
	 * `variables.$createdPathTracker`), duplicate emissions of the same path
	 * are suppressed and surfaced as a verbose() diagnostic instead. This is
	 * defense-in-depth for issue #2311 — the original duplicate
	 * "create blog/Application.cfc" line was a side effect of the
	 * copyTemplateDir() recursion bug fixed in #2342, but if any future
	 * regression re-emits a path twice, users see one cosmetic line rather
	 * than a confusing duplicate. Generator commands (which don't open a
	 * tracking session) emit unconditionally.
	 */
	private void function printCreated(required string path) {
		if (structKeyExists(variables, "$createdPathTracker")) {
			if (structKeyExists(variables.$createdPathTracker, arguments.path)) {
				verbose("printCreated: duplicate emit suppressed for #arguments.path#");
				return;
			}
			variables.$createdPathTracker[arguments.path] = true;
		}
		out("  create  #path#", "green");
	}

	/**
	 * Extract the value after the first '=' in a --key=value argument.
	 * Unlike listRest(arg, "="), this preserves '=' characters in the value.
	 */
	private string function valueAfterEquals(required string arg) {
		var pos = find("=", arg);
		if (pos == 0) return "";
		return mid(arg, pos + 1, len(arg));
	}

	// ── Browser Testing ─────────────────────────────

	private string function browserInstall(array args = []) {
		var force = false;
		var browserName = "chromium";

		for (var i = 2; i <= arrayLen(args); i++) {
			var arg = args[i];
			if (arg == "--force") {
				force = true;
			} else if (reFindNoCase("^--browser=", arg)) {
				browserName = valueAfterEquals(arg);
			}
		}

		var manifestPath = variables.projectRoot & "/vendor/wheels/browser-manifest.json";
		if (!fileExists(manifestPath)) {
			out("browser-manifest.json not found at: #manifestPath#", "red");
			return "";
		}
		var manifest = deserializeJSON(fileRead(manifestPath));

		var installDir = $resolveBrowserInstallDir();
		out("Install directory: #installDir#");
		out("Playwright version: #manifest.playwrightJavaVersion ?: 'unknown'#");
		out("");

		var downloaded = 0;
		var skipped = 0;
		for (var entry in manifest.classpath) {
			var jarPath = installDir & "/lib/" & entry.filename;
			var needsDownload = force;

			if (!fileExists(jarPath)) {
				needsDownload = true;
			} else if (!force) {
				var currentSha = $sha256(jarPath);
				if (currentSha != lCase(entry.sha256)) {
					out("  SHA mismatch: #entry.filename# - re-downloading", "yellow");
					needsDownload = true;
				}
			}

			if (needsDownload) {
				out("  Downloading #entry.filename#...");
				try {
					var parentDir = getDirectoryFromPath(jarPath);
					if (!directoryExists(parentDir)) {
						directoryCreate(parentDir, true);
					}
					cfhttp(
						url=entry.url,
						method="GET",
						getAsBinary="yes",
						timeout=300,
						result="local.httpResponse"
					);
					if (!findNoCase("200", local.httpResponse.statusCode)) {
						out("  FAILED: HTTP #local.httpResponse.statusCode#", "red");
						return "";
					}
					fileWrite(jarPath, local.httpResponse.fileContent);
					var sha = $sha256(jarPath);
					if (sha != lCase(entry.sha256)) {
						out("  FAILED (SHA mismatch)", "red");
						out("    Expected: #lCase(entry.sha256)#", "red");
						out("    Got:      #sha#", "red");
						return "";
					}
					out("  OK: #entry.filename#", "green");
					downloaded++;
				} catch (any e) {
					out("  FAILED: #e.message#", "red");
					return "";
				}
			} else {
				out("  #entry.filename#", "green");
				skipped++;
			}
		}

		out("");
		out("JARs: #downloaded# downloaded, #skipped# up-to-date");
		out("");
		out("Installing #browserName# browser binaries...");

		var classpath = "";
		for (var entry in manifest.classpath) {
			if (len(classpath)) classpath &= ":";
			classpath &= installDir & "/lib/" & entry.filename;
		}

		try {
			cfexecute(
				name="java",
				arguments="-cp #classpath# com.microsoft.playwright.CLI install #browserName#",
				timeout=300,
				variable="local.stdout",
				errorVariable="local.stderr"
			);
			out("Browser install OK", "green");
		} catch (any e) {
			out("Browser install FAILED", "red");
			out(local.stderr ?: e.message, "red");
			return "";
		}

		out("");
		out("Browser testing ready.", "green");
		out("Run: wheels test --filter=browser  (or: wheels browser test)", "green");
		return "";
	}

	private string function browserTest(array args = []) {
		var format = "text";
		var verboseOutput = false;
		// Default to the APP's browser specs (tests/specs/browser/) — not the
		// framework's internal browser specs. Onboarding finding F11 reported
		// `wheels browser test` running 0 tests because it pointed at
		// `wheels.tests.specs.wheelstest`, the framework's own browser-DSL
		// test directory, which contains no app code. Override with
		// `--directory=...` for advanced use.
		var directory = "tests.specs.browser";

		for (var i = 2; i <= arrayLen(args); i++) {
			var arg = args[i];
			if (arg == "--verbose" || arg == "-v") {
				verboseOutput = true;
			} else if (reFindNoCase("^--format=", arg)) {
				format = valueAfterEquals(arg);
			} else if (reFindNoCase("^--directory=", arg)) {
				directory = valueAfterEquals(arg);
			} else if (!arg.startsWith("--")) {
				directory = arg;
			}
		}

		// Pre-flight: verify Playwright JARs
		var manifestPath = variables.projectRoot & "/vendor/wheels/browser-manifest.json";
		if (!fileExists(manifestPath)) {
			out("browser-manifest.json not found at: #manifestPath#", "red");
			return "";
		}
		var manifest = deserializeJSON(fileRead(manifestPath));
		var installDir = $resolveBrowserInstallDir();

		var allInstalled = true;
		var missingJars = [];
		var mismatchedJars = [];
		for (var entry in manifest.classpath) {
			var jarPath = installDir & "/lib/" & entry.filename;
			if (!fileExists(jarPath)) {
				allInstalled = false;
				arrayAppend(missingJars, entry.filename);
			} else if ($sha256(jarPath) != lCase(entry.sha256)) {
				allInstalled = false;
				arrayAppend(mismatchedJars, entry.filename);
			}
		}

		if (!allInstalled) {
			out("Playwright not installed.", "red");
			if (arrayLen(missingJars)) {
				out("Missing: #arrayToList(missingJars, ', ')#", "yellow");
			}
			if (arrayLen(mismatchedJars)) {
				out("SHA mismatch: #arrayToList(mismatchedJars, ', ')#", "yellow");
			}
			out("");
			out("Run: wheels browser setup");
			return "";
		}

		out("Running browser tests...", "cyan");
		out("Directory: #directory#");
		out("");

		var serverPort = $getServerPort();
		// Hit the APP test runner (`/wheels/app/tests`), not the framework's
		// core test runner (`/wheels/core/tests`). The latter only knows
		// about specs under `vendor/wheels/tests/specs/`. Apps live under
		// `tests/specs/`, mounted by the app runner. F11.
		var testUrl = "http://localhost:#serverPort#/wheels/app/tests?db=sqlite&format=json&directory=#directory#";

		try {
			var httpResult = makeHttpRequest(testUrl);
		} catch (any e) {
			out("Failed to reach test runner at: #testUrl#", "red");
			out("Is the server running? Try: wheels start", "yellow");
			return "";
		}

		if (format == "json") {
			out(httpResult);
			return "";
		}

		try {
			var data = deserializeJSON(httpResult);
			var totalPass = data.totalPass ?: 0;
			var totalFail = data.totalFail ?: 0;
			var totalError = data.totalError ?: 0;

			out("Pass: #totalPass#  Fail: #totalFail#  Error: #totalError#");
			out("");

			// Recursive walk so we catch nested suites and surface failures
			// at the suite level (empty specStats but status == Failed/Error)
			// as well as per-spec failures. Playwright failures often error
			// out before any `it` runs — the only artifact is on the suite,
			// which the previous loop ignored. Onboarding F13.
			// Mutable state on a parent struct so closures see it by reference
			// on Adobe CF — see CLAUDE.md cross-engine notes.
			var ctx = {failureCount: 0, verbose: verboseOutput};
			var walkSuite = function(suite) {
				var specs = suite.specStats ?: [];
				for (var sp in specs) {
					if (listFindNoCase("Failed,Error", sp.status ?: "")) {
						ctx.failureCount++;
						out("  #sp.status ?: ''#: #sp.name ?: 'unknown'#", "red");
						var msg = sp.failMessage ?: "";
						if (len(msg)) {
							// Print failMessage by default. Without --verbose
							// truncate to 400 chars (enough to see the
							// assertion + selector context). With --verbose
							// dump the whole thing.
							var shown = ctx.verbose ? msg : left(msg, 400);
							out("    #shown#", "yellow");
							if (!ctx.verbose && len(msg) > 400) {
								out("    (truncated; pass --verbose for full output)", "yellow");
							}
						}
						if (len(sp.failOrigin ?: "")) {
							out("    at: #sp.failOrigin#", "yellow");
						}
					}
				}
				// Suite-level errors (no spec ever ran — e.g. compile error,
				// beforeAll threw, Playwright init blew up).
				if (
					arrayIsEmpty(specs)
					&& listFindNoCase("Failed,Error", suite.status ?: "")
				) {
					ctx.failureCount++;
					out("  #suite.status#: #suite.name ?: '(unnamed suite)'# (suite-level)", "red");
					var sg = suite.globalException ?: "";
					if (len(sg)) {
						var shown = ctx.verbose ? sg : left(sg, 400);
						out("    #shown#", "yellow");
						if (!ctx.verbose && len(sg) > 400) {
							out("    (truncated; pass --verbose for full output)", "yellow");
						}
					}
				}
				for (var inner in (suite.suiteStats ?: [])) {
					walkSuite(inner);
				}
			};
			for (var bundle in (data.bundleStats ?: [])) {
				for (var suite in (bundle.suiteStats ?: [])) {
					walkSuite(suite);
				}
				// Bundle-level error (compile error in spec file).
				if (len(bundle.globalException ?: "")) {
					ctx.failureCount++;
					out("  Bundle error: #bundle.name ?: '(unnamed)'#", "red");
					var bg = bundle.globalException;
					var shown = ctx.verbose ? bg : left(bg, 400);
					out("    #shown#", "yellow");
					if (!ctx.verbose && len(bg) > 400) {
						out("    (truncated; pass --verbose for full output)", "yellow");
					}
				}
			}

			if (totalFail == 0 && totalError == 0) {
				out("All browser tests passed.", "green");
			} else if (ctx.failureCount > 0 && (totalError + totalFail) > 0) {
				out("");
				out("If failure messages above don't show selector/Playwright detail,", "yellow");
				out("the BrowserTest spec may need explicit try/catch around .click() /", "yellow");
				out(".fill() to surface Playwright exceptions into failMessage.", "yellow");
			}
		} catch (any e) {
			out("Failed to parse test results: #e.message#", "red");
			if (verboseOutput) {
				out(left(httpResult ?: "", 500));
			}
		}

		return "";
	}

	private string function $resolveBrowserInstallDir() {
		var envHome = "";
		try {
			envHome = createObject("java", "java.lang.System")
				.getenv("WHEELS_BROWSER_HOME") ?: "";
		} catch (any e) {}
		if (len(trim(envHome))) return envHome;
		var home = createObject("java", "java.lang.System").getProperty("user.home");
		return home & "/.wheels/browser";
	}

	private string function $sha256(required string filePath) {
		var md = createObject("java", "java.security.MessageDigest")
			.getInstance("SHA-256");
		var digest = md.digest(fileReadBinary(arguments.filePath));
		return lCase(
			createObject("java", "java.util.HexFormat").of().formatHex(digest)
		);
	}

	private string function $getServerPort() {
		try {
			if (
				structKeyExists(server, "lucli")
				&& structKeyExists(server.lucli, "port")
			) {
				return server.lucli.port;
			}
		} catch (any e) {}
		return detectServerPort() ?: "8080";
	}

	/**
	 * Simple sprintf-like formatting for fixed-width columns.
	 * Supports %-Ns (left-aligned string) and %Ns (right-aligned string).
	 */
	private string function sprintf(required string format) {
		var result = arguments.format;
		var argIndex = 2;
		// Replace each %... placeholder with the corresponding argument
		while (reFindNoCase("%-?\d+s", result) && argIndex <= structCount(arguments)) {
			var match = reFindNoCase("(%-?)(\d+)s", result, 1, true);
			if (match.pos[1] == 0) break;
			var leftAlign = len(mid(result, match.pos[2], match.len[2])) > 1;
			var width = val(mid(result, match.pos[3], match.len[3]));
			var value = toString(arguments[argIndex]);
			if (leftAlign) {
				value = value & repeatString(" ", max(0, width - len(value)));
			} else {
				value = repeatString(" ", max(0, width - len(value))) & value;
			}
			// Guard: Left(str, 0) throws on Lucee 7 ("parameter 2 cannot be 0")
			var prefix = match.pos[1] > 1 ? left(result, match.pos[1] - 1) : "";
			result = prefix & value & mid(result, match.pos[1] + match.len[1], len(result));
			argIndex++;
		}
		return result;
	}

	/**
	 * Generate a random alphanumeric password for reload protection.
	 */
	private string function generateRandomPassword(numeric length = 16) {
		var chars = "abcdefghijklmnopqrstuvwxyz0123456789";
		var result = "";
		for (var i = 1; i <= arguments.length; i++) {
			result &= mid(chars, randRange(1, len(chars)), 1);
		}
		return result;
	}

	/**
	 * Remove CFML and cfscript comments so static parsers don't pick up
	 * commented-out config calls. Strips:
	 *   - cfscript line comments  // ...
	 *   - cfscript/JS block comments  /* ... *​/
	 *   - CFML tag-style block comments  <!--- ... --->
	 */
	private string function stripCfmlComments(required string source) {
		var result = arguments.source;
		// Tag-style CFML comments. Non-greedy across lines.
		result = reReplace(result, "<!---[\s\S]*?--->", "", "all");
		// /* ... */ block comments. Non-greedy across lines.
		result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
		// // line comments to end of line.
		result = reReplace(result, "//[^\r\n]*", "", "all");
		return result;
	}

}
