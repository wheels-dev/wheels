/**
 * Unit coverage for the ArgSpec migration (issue #2861).
 *
 * These specs exercise Module.cfc's arg-sourcing layer ($structuredArgs /
 * $argvToCollection) and the per-command parse helpers that replaced the
 * hand-rolled token loops. They run against the structured argCollection LuCLI
 * actually hands each command — no server, no command side effects — via
 * ModuleArgvProbe.
 *
 * The behavioral fact they pin: `--no-X` negations and named-only invocations
 * (e.g. `wheels seed --environment=x`, `wheels doctor --verbose`) survive
 * structurally, because ArgSpec consumes the named keys directly instead of the
 * old flatten/re-parse round trip that dropped them.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.probe = new cli.lucli.tests._fixtures.commands.ModuleArgvProbe(
			cwd = expandPath("/")
		);
	}

	function run() {

		describe("argvToCollection — faithful inverse of LuCLI parseArguments", () => {

			it("maps a positional to arg1", () => {
				expect(probe.$argvToCollection(["myapp"]).arg1).toBe("myapp");
			});

			it("maps --no-X to X=false", () => {
				var c = probe.$argvToCollection(["myapp", "--no-sqlite"]);
				expect(c.arg1).toBe("myapp");
				expect(c.sqlite).toBe("false");
			});

			it("maps a bare --X to X=true", () => {
				expect(probe.$argvToCollection(["--setup-h2"])["setup-h2"]).toBe("true");
			});

			it("maps --key=value to key=value (strips leading --)", () => {
				expect(probe.$argvToCollection(["--port=3000"]).port).toBe("3000");
			});

			it("numbers positionals by global arg index, like LuCLI", () => {
				// LuCLI increments its counter for every token, so a flag between
				// two positionals leaves a gap (arg1, arg3) rather than (arg1, arg2).
				var c = probe.$argvToCollection(["first", "--flag", "third"]);
				expect(c.arg1).toBe("first");
				expect(c.flag).toBe("true");
				expect(c.arg3).toBe("third");
			});

			it("returns an empty struct for empty argv", () => {
				expect(probe.$argvToCollection([])).toBeEmpty();
			});

		});

		describe("structuredArgs — sources the collection LuCLI passed, or reconstructs it", () => {

			it("returns the live argumentCollection when the caller supplied one", () => {
				var c = probe.$structuredArgs({arg1: "myapp", sqlite: "false"});
				expect(c.arg1).toBe("myapp");
				expect(c.sqlite).toBe("false");
			});

			it("reconstructs from __arguments when the caller args are empty (create -> new path)", () => {
				var c = probe.$structuredArgs({}, ["myapp", "--no-sqlite"]);
				expect(c.arg1).toBe("myapp");
				expect(c.sqlite).toBe("false");
			});

			it("consumes __arguments once — stale argv must not replay on a later zero-arg call", () => {
				// The stdio MCP server is a persistent process: after a delegating
				// call stashes argv (create/generate app -> new), a later zero-arg
				// tool call (e.g. wheels_test()) must see an EMPTY collection, not
				// a replay of the stale stash.
				var first = probe.$structuredArgs({}, ["blog"]);
				expect(first.arg1).toBe("blog");
				var second = probe.$structuredArgsWithoutReseed({});
				expect(second).toBeEmpty();
			});

		});

		describe("parseNewArgs", () => {

			it("binds the app name positional", () => {
				expect(probe.$parseNewArgs({arg1: "myapp"}).appName).toBe("myapp");
			});

			it("defaults port, datasource, and flags", () => {
				var o = probe.$parseNewArgs({arg1: "myapp"});
				expect(o.port).toBe(8080);
				expect(o.datasource).toBe("");
				expect(o.setupH2).toBeFalse();
				expect(o.noSQLite).toBeFalse();
				expect(o.openBrowser).toBeTrue();
			});

			it("treats --no-sqlite (sqlite=false) as noSQLite=true", () => {
				expect(probe.$parseNewArgs({arg1: "myapp", sqlite: "false"}).noSQLite).toBeTrue();
			});

			it("treats --no-open-browser (open-browser=false) as openBrowser=false", () => {
				expect(probe.$parseNewArgs({arg1: "myapp", "open-browser": "false"}).openBrowser).toBeFalse();
			});

			it("coerces --port to a number", () => {
				expect(probe.$parseNewArgs({arg1: "myapp", port: "3000"}).port).toBe(3000);
			});

			it("reads --datasource and --reload-password", () => {
				var o = probe.$parseNewArgs({arg1: "myapp", datasource: "mydb", "reload-password": "s3cret"});
				expect(o.datasource).toBe("mydb");
				expect(o.reloadPassword).toBe("s3cret");
			});

			it("flags an empty invocation so the command can show usage", () => {
				expect(probe.$parseNewArgs({}).isEmpty).toBeTrue();
				expect(probe.$parseNewArgs({arg1: "myapp"}).isEmpty).toBeFalse();
			});

			it("treats a flags-only invocation as non-empty (errors instead of usage)", () => {
				// `wheels new --no-sqlite` (no app name) arrives as {sqlite:"false"} —
				// non-empty, so isEmpty is false, the usage branch is skipped, and the
				// command throws "app name required". This is a deliberate delta from
				// the old getArgs() arg1-gate, which dropped named-only args and fell
				// through to the usage guide.
				expect(probe.$parseNewArgs({sqlite: "false"}).isEmpty).toBeFalse();
			});

			it("binds the app name across a LuCLI numbering gap (option before the name)", () => {
				// `wheels new --port=3000 blog` — LuCLI numbers positionals by
				// global token index, so the name arrives as arg2 with no arg1.
				// Fixed-index probing ignored the supplied name and threw
				// Wheels.InvalidArguments.
				var o = probe.$parseNewArgs({port: "3000", arg2: "blog"});
				expect(o.appName).toBe("blog");
				expect(o.port).toBe(3000);
			});

			it("binds the app name across a flag-induced gap (--setup-h2 blog)", () => {
				var o = probe.$parseNewArgs({"setup-h2": "true", arg2: "blog"});
				expect(o.appName).toBe("blog");
				expect(o.setupH2).toBeTrue();
			});

		});

		describe("parseSeedArgs (named-only — previously dropped)", () => {

			it("defaults mode=auto and environment=''", () => {
				var o = probe.$parseSeedArgs({});
				expect(o.mode).toBe("auto");
				expect(o.environment).toBe("");
			});

			it("reads --environment", () => {
				expect(probe.$parseSeedArgs({environment: "production"}).environment).toBe("production");
			});

			it("reads --mode", () => {
				expect(probe.$parseSeedArgs({mode: "development"}).mode).toBe("development");
			});

			it("maps --generate to mode=generate", () => {
				expect(probe.$parseSeedArgs({generate: "true"}).mode).toBe("generate");
			});

		});

		describe("parseNotesArgs (named-only — previously dropped)", () => {

			it("defaults annotations and empty custom", () => {
				var o = probe.$parseNotesArgs({});
				expect(o.annotations).toBe("TODO,FIXME,OPTIMIZE");
				expect(o.custom).toBe("");
			});

			it("reads --annotations and --custom", () => {
				var o = probe.$parseNotesArgs({annotations: "HACK,XXX", custom: "REVIEW"});
				expect(o.annotations).toBe("HACK,XXX");
				expect(o.custom).toBe("REVIEW");
			});

		});

		describe("parseAnalyzeArgs", () => {

			it("defaults target=all with hasTarget=false when no positional given", () => {
				var o = probe.$parseAnalyzeArgs({});
				expect(o.target).toBe("all");
				expect(o.hasTarget).toBeFalse();
			});

			it("lower-cases the target positional", () => {
				var o = probe.$parseAnalyzeArgs({arg1: "Models"});
				expect(o.target).toBe("models");
				expect(o.hasTarget).toBeTrue();
			});

		});

		describe("parseVerboseFlag (doctor / stats — named-only fix + -v preserved)", () => {

			it("defaults to false", () => {
				expect(probe.$parseVerboseFlag({})).toBeFalse();
			});

			it("honors --verbose (verbose=true) — previously dropped", () => {
				expect(probe.$parseVerboseFlag({verbose: "true"})).toBeTrue();
			});

			it("still honors -v, which LuCLI delivers as a positional", () => {
				expect(probe.$parseVerboseFlag({arg1: "-v"})).toBeTrue();
			});

		});

		describe("parseUpgradeArgs", () => {

			it("treats a missing/empty invocation as not-check", () => {
				expect(probe.$parseUpgradeArgs({}).isCheck).toBeFalse();
			});

			it("recognizes the check subcommand", () => {
				expect(probe.$parseUpgradeArgs({arg1: "check"}).isCheck).toBeTrue();
			});

			it("reads --to as the target version", () => {
				expect(probe.$parseUpgradeArgs({arg1: "check", to: "4.0.0"}).targetVersion).toBe("4.0.0");
			});

			it("detects the --dry-run and --to misfires for the nudge", () => {
				var o = probe.$parseUpgradeArgs({arg1: "oops", "dry-run": "true", to: "4.0.0"});
				expect(o.sawDryRun).toBeTrue();
				expect(o.sawTo).toBeTrue();
			});

			it("reads --format=json for machine-readable CI output", () => {
				var o = probe.$parseUpgradeArgs({arg1: "check", format: "json"});
				expect(o.format).toBe("json");
				expect(probe.$parseUpgradeArgs({arg1: "check"}).format).toBe("");
			});

		});

		describe("parseDestroyArgs", () => {

			it("reports zero positionals for an empty/usage invocation", () => {
				expect(probe.$parseDestroyArgs({}).positionalCount).toBe(0);
			});

			it("defaults type=resource for a single positional", () => {
				var o = probe.$parseDestroyArgs({arg1: "User"});
				expect(o.name).toBe("User");
				expect(o.type).toBe("resource");
			});

			it("accepts <type> <name> ordering", () => {
				var o = probe.$parseDestroyArgs({arg1: "model", arg2: "Product"});
				expect(o.type).toBe("model");
				expect(o.name).toBe("Product");
			});

			it("accepts the legacy <name> <type> ordering", () => {
				var o = probe.$parseDestroyArgs({arg1: "Product", arg2: "model"});
				expect(o.name).toBe("Product");
				expect(o.type).toBe("model");
			});

			it("reads the --force flag", () => {
				expect(probe.$parseDestroyArgs({arg1: "User", force: "true"}).force).toBeTrue();
			});

			it("keeps the type/name pair intact when --force comes first (LuCLI index gap)", () => {
				// `wheels destroy --force model User` arrives as
				// {force:"true", arg2:"model", arg3:"User"} — no arg1. Gathering
				// positionals by sorted index recovers <type> <name> correctly.
				var o = probe.$parseDestroyArgs({force: "true", arg2: "model", arg3: "User"});
				expect(o.type).toBe("model");
				expect(o.name).toBe("User");
				expect(o.force).toBeTrue();
			});

		});

		describe("parseConsoleArgs (named-only — previously dropped)", () => {

			it("defaults password to empty", () => {
				expect(probe.$parseConsoleArgs({}).password).toBe("");
			});

			it("reads --password=value", () => {
				expect(probe.$parseConsoleArgs({password: "s3cret"}).password).toBe("s3cret");
			});

			it("reads --password with no positional — the latent arg1-gate bug ArgSpec fixes", () => {
				// `wheels console --password=x` arrives as {password:"x"} with no
				// arg1, so the legacy arg1-gated getArgs() dropped it and the console
				// silently fell back to auto-detecting the reload password.
				expect(probe.$parseConsoleArgs({password: "x"}).password).toBe("x");
			});

		});

		describe("parseTestArgs", () => {

			it("defaults reporter=simple, db=sqlite, format=json, flags off, useTestDB on", () => {
				var o = probe.$parseTestArgs({});
				expect(o.filter).toBe("");
				expect(o.reporter).toBe("simple");
				expect(o.db).toBe("sqlite");
				expect(o.format).toBe("json");
				expect(o.verbose).toBeFalse();
				expect(o.ci).toBeFalse();
				expect(o.core).toBeFalse();
				expect(o.useTestDB).toBeTrue();
				expect(o.dbExplicit).toBeFalse();
			});

			it("reads --filter", () => {
				expect(probe.$parseTestArgs({filter: "models"}).filter).toBe("models");
			});

			it("treats --directory as an alias for --filter", () => {
				expect(probe.$parseTestArgs({directory: "controllers"}).filter).toBe("controllers");
			});

			it("uses a bare positional as the filter", () => {
				expect(probe.$parseTestArgs({arg1: "security"}).filter).toBe("security");
			});

			it("maps --core / --ci / --verbose flags", () => {
				var o = probe.$parseTestArgs({core: "true", ci: "true", verbose: "true"});
				expect(o.core).toBeTrue();
				expect(o.ci).toBeTrue();
				expect(o.verbose).toBeTrue();
			});

			it("honors -v delivered as a positional", () => {
				expect(probe.$parseTestArgs({arg1: "-v"}).verbose).toBeTrue();
			});

			it("treats --no-test-db (test-db=false) as useTestDB=false", () => {
				expect(probe.$parseTestArgs({"test-db": "false"}).useTestDB).toBeFalse();
			});

			it("reads --db and marks it explicit", () => {
				var o = probe.$parseTestArgs({db: "mysql"});
				expect(o.db).toBe("mysql");
				expect(o.dbExplicit).toBeTrue();
			});

			it("reads --reporter", () => {
				expect(probe.$parseTestArgs({reporter: "json"}).reporter).toBe("json");
			});

			it("keeps the filter when -v precedes it (LuCLI index gap)", () => {
				// `wheels test -v models` arrives as {arg1:"-v", arg2:"models"}: -v
				// toggles verbose, the remaining positional is the filter.
				var o = probe.$parseTestArgs({arg1: "-v", arg2: "models"});
				expect(o.verbose).toBeTrue();
				expect(o.filter).toBe("models");
			});

		});

	}

}
