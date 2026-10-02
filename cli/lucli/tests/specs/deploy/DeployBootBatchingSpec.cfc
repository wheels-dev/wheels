/**
 * #3925: the `boot:` block (Kamal's rolling boot) is applied, not just
 * validated. With `boot:` present, each role's hosts boot in batches of
 * `limit` (a count, or a percentage of the role's hosts) with `wait` seconds
 * between batches. Without it, hosts boot back to back as before.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {

        describe("Boot.batchSize", () => {

            it("uses a plain limit as the batch size", () => {
                expect(new cli.lucli.services.deploy.config.Boot({limit: 2}).batchSize(5)).toBe(2);
            });

            it("treats a percentage as a share of the role's hosts, rounded up", () => {
                expect(new cli.lucli.services.deploy.config.Boot({limit: "40%"}).batchSize(5)).toBe(2);
                expect(new cli.lucli.services.deploy.config.Boot({limit: "10%"}).batchSize(5)).toBe(1);
            });

            it("never goes below one host per batch", () => {
                expect(new cli.lucli.services.deploy.config.Boot({limit: 0}).batchSize(5)).toBe(1);
                expect(new cli.lucli.services.deploy.config.Boot({limit: "0%"}).batchSize(5)).toBe(1);
            });
        });

        describe("deploy applies boot: limit and wait", () => {

            it("pauses `wait` seconds between batches of `limit` hosts in a dry run", () => {
                var out = $dryRunDeploy("boot: {limit: 2, wait: 7}");
                var pauses = $linesMatching(out, "^\[boot\] ");
                expect(arrayLen(pauses)).toBe(2);
                expect(pauses[1]).toInclude("7s");
                // The first pause comes after the second host's app container, before the third's
                // (matched by container name: kamal-proxy's own docker run comes earlier).
                var lines = listToArray(out, chr(10));
                var firstPause = $indexOf(lines, "^\[boot\] ");
                expect($indexOf(lines, "^\[10\.0\.0\.2\] .*demo-web-v1")).toBeLT(firstPause);
                expect($indexOf(lines, "^\[10\.0\.0\.3\] .*demo-web-v1")).toBeGT(firstPause);
            });

            it("sizes batches from a percentage limit", () => {
                expect(arrayLen($linesMatching($dryRunDeploy("boot: {limit: '40%', wait: 3}"), "^\[boot\] "))).toBe(2);
            });

            it("doesn't pause without a boot: block", () => {
                expect(arrayLen($linesMatching($dryRunDeploy(""), "^\[boot\] "))).toBe(0);
            });

            it("sleeps between batches in a real deploy", () => {
                var cfg = $writeConfig("boot: {limit: 2, wait: 7}");
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool());
                prepareMock(dc);
                dc.$("$bootPause");
                dc.$("$runLocal");
                dc.deploy({configPath: cfg, version: "v1", skipPush: true});
                var calls = dc.$callLog().$bootPause;
                expect(arrayLen(calls)).toBe(2);
                expect(calls[1][1]).toBe(7);
            });
        });
    }

    private string function $writeConfig(required string bootYaml) {
        var root = getTempDirectory() & "/wheels-deploy-boot-" & createUUID();
        directoryCreate(root & "/config", true, true);
        fileWrite(
            root & "/config/deploy.yml",
            "service: demo#chr(10)#image: acme/demo#chr(10)#"
                & "servers: [10.0.0.1, 10.0.0.2, 10.0.0.3, 10.0.0.4, 10.0.0.5]#chr(10)#"
                & "registry: {username: u, password: [REGISTRY_PASSWORD]}#chr(10)#"
                & arguments.bootYaml & chr(10)
        );
        return root & "/config/deploy.yml";
    }

    private string function $dryRunDeploy(required string bootYaml) {
        var dc = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool());
        return dc.deploy({configPath: $writeConfig(arguments.bootYaml), version: "v1", dryRun: true, skipPush: true});
    }

    private array function $linesMatching(required string text, required string pattern) {
        var found = [];
        for (var line in listToArray(arguments.text, chr(10))) {
            if (reFind(arguments.pattern, line)) arrayAppend(found, line);
        }
        return found;
    }

    private numeric function $indexOf(required array lines, required string pattern) {
        for (var i = 1; i <= arrayLen(arguments.lines); i++) {
            if (reFind(arguments.pattern, arguments.lines[i])) return i;
        }
        return 0;
    }
}
