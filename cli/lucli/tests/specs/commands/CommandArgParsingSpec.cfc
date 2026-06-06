/**
 * Unit coverage for the ArgSpec migration (issue #2861).
 *
 * These specs exercise Module.cfc's arg-sourcing layer ($structuredArgs /
 * $argvToCollection) and the per-command parse helpers that replaced the
 * hand-rolled getArgs() token loops. They run against the structured
 * argCollection LuCLI actually hands each command — no server, no command
 * side effects — via ModuleArgvProbe.
 *
 * Two behavioral facts they pin:
 *   1. The legacy getArgs() arg1-gate silently dropped named-only invocations
 *      (e.g. `wheels seed --environment=x`, `wheels doctor --verbose`) because
 *      those collections carry no positional arg1. ArgSpec consumes the named
 *      keys directly, so the migration fixes that latent drop.
 *   2. `--no-X` negations survive structurally (no flatten/re-parse round trip).
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

		});

		describe("regression: legacy getArgs() dropped named-only invocations", () => {

			it("returns [] for a named-only collection (no arg1) — the latent bug ArgSpec fixes", () => {
				// `wheels seed --environment=x` / `wheels doctor --verbose` arrive as
				// {environment:"x"} / {verbose:"true"} with no arg1, so the arg1-gated
				// getArgs() fell through to the empty __arguments fallback.
				expect(probe.$getArgs({verbose: "true"}, [])).toBeEmpty();
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

			it("flags a missing/empty invocation as not-check", () => {
				var o = probe.$parseUpgradeArgs({});
				expect(o.isCheck).toBeFalse();
				expect(o.hasArgs).toBeFalse();
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

	}

}
