/**
 * Covers cli.lucli.services.deploy.cli.DeployArgsParser, the deploy-only flag
 * parser that Module.cfc::$deployArgsToOptions delegates to.
 *
 * Issue #2674: picocli absorbs the bare --version flag at the LuCLI root, so
 * Kamal's documented `wheels deploy --version=v1.2.3` form blows up before
 * Module.cfc runs. The fix introduces --release as a picocli-safe alias; the
 * brew/scoop wrappers rewrite --version[=val] -> --release[=val] when "deploy"
 * is the first positional. The parser accepts both flags identically.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.parser = new cli.lucli.services.deploy.cli.DeployArgsParser();
    }

    function run() {
        describe("DeployArgsParser", () => {

            it("parses --release=value into opts.version", () => {
                var opts = parser.parse(["--release=v1.2.3"]);
                expect(opts.version).toBe("v1.2.3");
            });

            it("parses '--release value' (space-separated) into opts.version", () => {
                var opts = parser.parse(["--release", "abc1234"]);
                expect(opts.version).toBe("abc1234");
            });

            it("parses --version=value into opts.version (programmatic / wrapper-rewritten path)", () => {
                var opts = parser.parse(["--version=v1.2.3"]);
                expect(opts.version).toBe("v1.2.3");
            });

            it("parses '--version value' (space-separated) into opts.version", () => {
                var opts = parser.parse(["--version", "abc1234"]);
                expect(opts.version).toBe("abc1234");
            });

            it("treats --release and --version as equivalent", () => {
                var a = parser.parse(["--release=v1"]);
                var b = parser.parse(["--version=v1"]);
                expect(a.version).toBe(b.version);
            });

            it("preserves other flags alongside --release", () => {
                var opts = parser.parse([
                    "--release=v1",
                    "--destination=staging",
                    "--dry-run"
                ]);
                expect(opts.version).toBe("v1");
                expect(opts.destination).toBe("staging");
                expect(opts.dryRun).toBeTrue();
            });

            // Documents the pre-existing silent-drop on last-token flags.
            // The behavior is symmetric between --release and --version
            // (same `i < n` guard); freezing it under test guards against
            // an accidental change in either arm.
            it("silently drops --release when no value follows", () => {
                var opts = parser.parse(["--release"]);
                expect(structKeyExists(opts, "version")).toBeFalse();
            });

            it("silently drops --version when no value follows", () => {
                var opts = parser.parse(["--version"]);
                expect(structKeyExists(opts, "version")).toBeFalse();
            });

            // CLI audit H9: --config aliases --configPath; the deploy guides
            // document --config but only --configPath was parsed.
            it("parses --config=value as an alias for configPath", () => {
                var opts = parser.parse(["--config=config/deploy.yml"]);
                expect(opts.configPath).toBe("config/deploy.yml");
            });

            it("parses '--config value' as an alias for configPath", () => {
                var opts = parser.parse(["--config", "deploy.prod.yml"]);
                expect(opts.configPath).toBe("deploy.prod.yml");
            });

            // CLI audit H9: app-filter flags DeployAppCli reads but the parser
            // never populated, so `deploy app boot --role=web` booted all roles.
            it("parses --role into opts.role", () => {
                var opts = parser.parse(["--role=web"]);
                expect(opts.role).toBe("web");
            });

            it("parses '--role value' (space-separated) into opts.role", () => {
                var opts = parser.parse(["--role", "workers"]);
                expect(opts.role).toBe("workers");
            });

            it("parses --container into opts.container", () => {
                var opts = parser.parse(["--container=app-web-v1"]);
                expect(opts.container).toBe("app-web-v1");
            });

            it("parses '--container value' (space-separated) into opts.container", () => {
                var opts = parser.parse(["--container", "app-web-v1"]);
                expect(opts.container).toBe("app-web-v1");
            });

            it("parses --follow as a boolean flag", () => {
                var opts = parser.parse(["--follow"]);
                expect(opts.follow).toBeTrue();
            });
        });
    }
}
