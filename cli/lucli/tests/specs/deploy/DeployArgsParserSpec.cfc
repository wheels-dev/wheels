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
        });
    }
}
