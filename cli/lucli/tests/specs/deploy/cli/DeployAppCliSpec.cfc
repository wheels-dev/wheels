component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployAppCli", () => {

            it("boot emits docker run via SshPool per host", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.boot({configPath: variables.fixture, version: "abc1234"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker run")).toBeTrue();
                expect($anyInclude(cmds, "demo-web-abc1234")).toBeTrue();
            });

            it("stop emits docker stop via SshPool", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.stop({configPath: variables.fixture, version: "v1"});
                expect($anyInclude($cmdsFrom(fake), "docker stop demo-web-v1")).toBeTrue();
            });

            it("start emits docker start via SshPool", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.start({configPath: variables.fixture, version: "v1"});
                expect($anyInclude($cmdsFrom(fake), "docker start demo-web-v1")).toBeTrue();
            });

            it("containers emits docker ps filter", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.containers({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "docker ps")).toBeTrue();
                expect($anyInclude($cmdsFrom(fake), "label=service=demo")).toBeTrue();
            });

            it("logs honors tail and follow opts", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.logs({configPath: variables.fixture, tail: 50, follow: false});
                expect($anyInclude($cmdsFrom(fake), "--tail 50")).toBeTrue();
            });

            it("maintenance creates the marker", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.maintenance({configPath: variables.fixture, version: "v1"});
                expect($anyInclude($cmdsFrom(fake), "touch /tmp/kamal-maintenance-demo")).toBeTrue();
            });

            it("live clears the marker", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.live({configPath: variables.fixture, version: "v1"});
                expect($anyInclude($cmdsFrom(fake), "rm -f /tmp/kamal-maintenance-demo")).toBeTrue();
            });

            it("remove stops and rms the container", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.remove({configPath: variables.fixture, version: "v1"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-web-v1")).toBeTrue();
                expect($anyInclude(cmds, "docker rm demo-web-v1")).toBeTrue();
            });

            it("dry-run buffers output instead of dispatching", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                cli.stop({configPath: variables.fixture, version: "v1", dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker stop");
                expect(out).toInclude("[1.2.3.4]");
            });

            // Regression for issue #2230 — the real-mode path must return a
            // visible success summary, not an empty string.

            it("boot (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                var out = cli.boot({configPath: variables.fixture, version: "v1"});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("Booted");
            });

            it("stop --dry-run returns the buffered command list", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                var out = cli.stop({configPath: variables.fixture, version: "v1", dryRun: true});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("docker stop");
            });
        });
    }

    private array function $cmdsFrom(required any fake) {
        var out = [];
        for (var c in arguments.fake.calls()) arrayAppend(out, c.cmd ?: "");
        return out;
    }

    private boolean function $anyInclude(required array arr, required string needle) {
        for (var s in arguments.arr) if (findNoCase(arguments.needle, s)) return true;
        return false;
    }
}
