component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("ArgSpec Service", () => {

			describe("builder API", () => {

				it("init() returns this for chaining", () => {
					var spec = new cli.lucli.services.ArgSpec();
					expect(isObject(spec)).toBeTrue();
				});

				it("positional() / flag() / option() are chainable", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true)
						.flag(name = "sqlite", default = true)
						.option(name = "datasource", default = "");
					expect(isObject(spec)).toBeTrue();
				});

			});

			describe("parse() — positional binding", () => {

				it("binds arg1, arg2, ... to declared positionals in order", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "appName")
						.positional(name = "templateName");
					var out = spec.parse({arg1: "blog", arg2: "default"});
					expect(out.appName).toBe("blog");
					expect(out.templateName).toBe("default");
				});

				it("throws Wheels.CLI.MissingArgument when a required positional is absent", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true);
					expect(() => {
						spec.parse({});
					}).toThrow("Wheels.CLI.MissingArgument");
				});

				it("uses the declared default when an optional positional is absent", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "templateName", required = false, default = "default");
					var out = spec.parse({});
					expect(out.templateName).toBe("default");
				});

				it("binds positionals across LuCLI numbering gaps (option consumed an index)", () => {
					// `wheels new --port=3000 blog` — LuCLI numbers positionals by
					// global token index, so the name arrives as arg2 with NO arg1.
					// Fixed-index probing bound nothing and the supplied name was
					// silently ignored.
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "appName")
						.option(name = "port", default = 8080, type = "numeric");
					var out = spec.parse({"port": "3000", "arg2": "blog"});
					expect(out.appName).toBe("blog");
					expect(out.port).toBe(3000);
				});

				it("binds multiple gap-numbered positionals in numeric index order", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "first")
						.positional(name = "second");
					var out = spec.parse({"arg2": "a", "arg5": "b", "force": "true"});
					expect(out.first).toBe("a");
					expect(out.second).toBe("b");
				});

				it("satisfies a required positional delivered after a gap", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true);
					var out = spec.parse({"arg3": "blog"});
					expect(out.appName).toBe("blog");
				});

			});

			describe("parse() — flags (the --no-X regression surface)", () => {

				it("applies the declared default when the key is absent", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = true);
					var out = spec.parse({});
					expect(out.sqlite).toBeTrue();
				});

				it("returns true when LuCLI passes the flag as the string 'true'", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = false);
					var out = spec.parse({sqlite: "true"});
					expect(out.sqlite).toBeTrue();
				});

				it("returns false when LuCLI passes the flag as the string 'false' (--no-X round-trip)", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = true);
					var out = spec.parse({sqlite: "false"});
					// This is the #2855 regression surface. argsFromCollection()'s
					// flatten step originally DROPPED "false" values outright; #2856
					// patched that by re-emitting "--no-key". ArgSpec removes the
					// round-trip entirely, so the negation survives structurally.
					expect(out.sqlite).toBeFalse();
				});

				it("coerces a literal boolean false to false (cross-engine safety)", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = true);
					var out = spec.parse({sqlite: false});
					expect(out.sqlite).toBeFalse();
				});

			});

			describe("parse() — options with values", () => {

				it("returns the declared default when the key is absent", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.option(name = "datasource", default = "wheelsapp");
					var out = spec.parse({});
					expect(out.datasource).toBe("wheelsapp");
				});

				it("returns the supplied value as a string by default", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.option(name = "datasource", default = "");
					var out = spec.parse({datasource: "users_db"});
					expect(out.datasource).toBe("users_db");
				});

				it("coerces values when type = 'numeric'", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.option(name = "port", default = 3000, type = "numeric");
					var out = spec.parse({port: "8080"});
					expect(out.port).toBe(8080);
				});

			});

			describe("parse() — unknown keys", () => {

				it("ignores keys in coll that the spec did not declare", () => {
					var spec = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = true);
					var out = spec.parse({sqlite: "false", mystery: "value"});
					expect(out.sqlite).toBeFalse();
					expect(structKeyExists(out, "mystery")).toBeFalse();
				});

			});

			describe("toArgv() — structured collection back to ordered argv (passthrough)", () => {

				it("emits positionals first, in arg1..argN order", () => {
					var argv = new cli.lucli.services.ArgSpec()
						.toArgv({arg1: "scaffold", arg2: "Post", arg3: "title:string"});
					expect(argv[1]).toBe("scaffold");
					expect(argv[2]).toBe("Post");
					expect(argv[3]).toBe("title:string");
				});

				it("re-emits --no-<key> when LuCLI passed <key>=false (issue ##2855 contract)", () => {
					// Named keys are quoted so their case survives the struct
					// literal identically on Lucee/Adobe/BoxLang — toArgv emits
					// the key verbatim, so an unquoted (upper-cased) key would
					// drift cross-engine.
					var argv = new cli.lucli.services.ArgSpec()
						.toArgv({arg1: "User", "routes": "false"});
					expect(argv).toInclude("--no-routes");
				});

				it("emits a bare --<key> for boolean-true flags", () => {
					var argv = new cli.lucli.services.ArgSpec()
						.toArgv({arg1: "myapp", "setup-h2": "true"});
					expect(argv).toInclude("--setup-h2");
				});

				it("emits --<key>=<value> for value options", () => {
					var argv = new cli.lucli.services.ArgSpec()
						.toArgv({arg1: "myapp", "port": "3000"});
					expect(argv).toInclude("--port=3000");
				});

				it("places positionals before named flags (delegation round-trip order)", () => {
					var argv = new cli.lucli.services.ArgSpec()
						.toArgv({arg1: "scaffold", arg2: "Post", "migration": "false"});
					expect(argv[1]).toBe("scaffold");
					expect(argv[2]).toBe("Post");
					expect(argv[3]).toBe("--no-migration");
				});

				it("returns an empty argv for an empty collection", () => {
					expect(new cli.lucli.services.ArgSpec().toArgv({})).toBeEmpty();
				});

				it("does not stop at a numbering gap — positionals after a flag survive", () => {
					// `wheels g scaffold Post --force title:string body:text` arrives
					// as {arg1, arg2, force, arg4, arg5}. The old loop stopped at the
					// missing arg3, so scaffold silently generated the model and
					// migration with no columns while reporting success.
					var argv = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "scaffold",
						"arg2": "Post",
						"force": "true",
						"arg4": "title:string",
						"arg5": "body:text"
					});
					expect(argv[1]).toBe("scaffold");
					expect(argv[2]).toBe("Post");
					expect(argv[3]).toBe("title:string");
					expect(argv[4]).toBe("body:text");
					expect(argv).toInclude("--force");
				});

				it("emits a gap-numbered leading positional (flag before the first positional)", () => {
					// `wheels create --setup-h2 app myapp` style ordering: the flag
					// consumes index 1, so the first positional is arg2.
					var argv = new cli.lucli.services.ArgSpec().toArgv({
						"setup-h2": "true",
						"arg2": "app",
						"arg3": "myapp"
					});
					expect(argv[1]).toBe("app");
					expect(argv[2]).toBe("myapp");
					expect(argv).toInclude("--setup-h2");
				});

				// Issue #3111: CFML `==` boolean-coerces both operands, so
				// "1" == "true" and "0" == "false" are TRUE. `--release=1`
				// arrived as {release: "1"}, got re-emitted as a bare
				// --release flag (value dropped), and the downstream deploy
				// parser then swallowed the next token — --dry-run — as the
				// version, turning a dry run into a live SSH dispatch that
				// hung ~76s against the config stub's placeholder host.
				it("preserves a value of '1' as --key=1, not a bare flag (issue ##3111)", () => {
					var argv = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "app",
						"arg2": "boot",
						"release": "1",
						"dry-run": "true"
					});
					expect(argv).toInclude("--release=1");
					expect(argv).toInclude("--dry-run");
				});

				it("preserves a value of '0' as --key=0, not a --no- negation (issue ##3111)", () => {
					var argv = new cli.lucli.services.ArgSpec().toArgv({"keep": "0"});
					expect(argv).toInclude("--keep=0");
				});

				it("preserves boolean-castable words (yes/no) as values, not flags (issue ##3111)", () => {
					var argv = new cli.lucli.services.ArgSpec().toArgv({"release": "yes", "follow": "no"});
					expect(argv).toInclude("--release=yes");
					expect(argv).toInclude("--follow=no");
				});

				it("still emits a bare flag for a native boolean true (MCP argCollection)", () => {
					var coll = {"arg1": "app"};
					coll["dry-run"] = javaCast("boolean", true);
					var argv = new cli.lucli.services.ArgSpec().toArgv(coll);
					expect(argv).toInclude("--dry-run");
				});

			});

			describe("toInputSchema() — typed MCP tool input schema", () => {

				// #2963 / wave-2 §5.2: MCP tool input schemas. Auto-discovered
				// tools in Module.cfc advertise empty `properties` so MCP
				// clients can't discover parameters. The fix derives the
				// per-tool schema from the same ArgSpec the command already
				// declares (FastMCP / Symfony JsonDescriptor pattern) — one
				// source of truth, no hand-written drift.

				it("returns a JSON-Schema-compatible object envelope", () => {
					var schema = new cli.lucli.services.ArgSpec().toInputSchema();
					expect(schema.type).toBe("object");
					expect(structKeyExists(schema, "properties")).toBeTrue();
					expect(structKeyExists(schema, "required")).toBeTrue();
					// Hostile clients sending an unknown key shouldn't be
					// silently tolerated — match the existing hidden-tool
					// pattern (additionalProperties:false).
					expect(schema.additionalProperties).toBeFalse();
				});

				it("emits one property per declared positional, flag, and option", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true, description = "App folder name")
						.flag(name = "sqlite", default = true, description = "Use SQLite datasource")
						.option(name = "datasource", default = "", description = "Datasource name")
						.toInputSchema();
					expect(structKeyExists(schema.properties, "appName")).toBeTrue();
					expect(structKeyExists(schema.properties, "sqlite")).toBeTrue();
					expect(structKeyExists(schema.properties, "datasource")).toBeTrue();
				});

				it("lists required positionals in the required array", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true)
						.positional(name = "templateName", required = false, default = "default")
						.toInputSchema();
					expect(schema.required).toInclude("appName");
					expect(schema.required).notToInclude("templateName");
				});

				it("maps positional type=string to JSON Schema type 'string'", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true)
						.toInputSchema();
					expect(schema.properties.appName.type).toBe("string");
				});

				it("maps option type=numeric to JSON Schema type 'number'", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.option(name = "port", default = 3000, type = "numeric")
						.toInputSchema();
					expect(schema.properties.port.type).toBe("number");
				});

				it("maps flag to JSON Schema type 'boolean'", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = true)
						.toInputSchema();
					expect(schema.properties.sqlite.type).toBe("boolean");
				});

				it("includes the description on each property when supplied", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.positional(name = "appName", required = true, description = "App folder name")
						.flag(name = "sqlite", default = true, description = "Use SQLite datasource")
						.option(name = "datasource", default = "", description = "Datasource name")
						.toInputSchema();
					expect(schema.properties.appName.description).toBe("App folder name");
					expect(schema.properties.sqlite.description).toBe("Use SQLite datasource");
					expect(schema.properties.datasource.description).toBe("Datasource name");
				});

				it("includes the declared default in each property", () => {
					var schema = new cli.lucli.services.ArgSpec()
						.flag(name = "sqlite", default = true)
						.option(name = "datasource", default = "wheelsapp")
						.toInputSchema();
					expect(schema.properties.sqlite.default).toBeTrue();
					expect(schema.properties.datasource.default).toBe("wheelsapp");
				});

				it("returns an empty schema (no properties, no required) when nothing is declared", () => {
					var schema = new cli.lucli.services.ArgSpec().toInputSchema();
					expect(structIsEmpty(schema.properties)).toBeTrue();
					expect(arrayLen(schema.required)).toBe(0);
				});

			});

		});

	}

}
