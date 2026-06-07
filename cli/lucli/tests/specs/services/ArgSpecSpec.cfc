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

			});

		});

	}

}
