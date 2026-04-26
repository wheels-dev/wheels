component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-accessories.yml");
    }

    function run() {
        describe("DeployAccessoryCli", () => {

            it("boot dispatches docker run on the accessory host", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.boot({configPath: variables.fixture, name: "db"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker run")).toBeTrue();
                expect($anyInclude(cmds, "--name demo-db")).toBeTrue();
                // Host should be the accessory's pinned host, not the app host.
                var hosts = $hostsFrom(fake);
                expect(arrayContains(hosts, "1.2.3.5")).toBeTrue();
            });

            it("reboot chains stop/rm/run", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.reboot({configPath: variables.fixture, name: "db"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker rm demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker run")).toBeTrue();
            });

            it("start dispatches docker start", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.start({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker start demo-db")).toBeTrue();
            });

            it("stop dispatches docker stop", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.stop({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker stop demo-db")).toBeTrue();
            });

            it("restart dispatches docker restart", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.restart({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker restart demo-db")).toBeTrue();
            });

            it("details inspects container", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.details({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker inspect")).toBeTrue();
            });

            it("logs honors tail", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.logs({configPath: variables.fixture, name: "db", tail: 25});
                expect($anyInclude($cmdsFrom(fake), "--tail 25")).toBeTrue();
            });

            it("remove chains stop + rm", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.remove({configPath: variables.fixture, name: "db"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker rm demo-db")).toBeTrue();
            });

            it("name=all fans out over every accessory", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.stop({configPath: variables.fixture, name: "all"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker stop demo-redis")).toBeTrue();
            });

            it("missing name throws DeployAccessoryCli.MissingName", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                var thrown = false;
                try {
                    cli.stop({configPath: variables.fixture});
                } catch ("DeployAccessoryCli.MissingName" e) {
                    thrown = true;
                }
                expect(thrown).toBeTrue();
            });

            it("dry-run buffers output instead of dispatching", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployAccessoryCli(fake);
                cli.stop({configPath: variables.fixture, name: "db", dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker stop demo-db");
            });
        });
    }

    private array function $cmdsFrom(required any fake) {
        var out = [];
        for (var c in arguments.fake.calls()) arrayAppend(out, c.cmd ?: "");
        return out;
    }

    private array function $hostsFrom(required any fake) {
        var out = [];
        for (var c in arguments.fake.calls()) arrayAppend(out, c.host ?: "");
        return out;
    }

    private boolean function $anyInclude(required array arr, required string needle) {
        for (var s in arguments.arr) if (findNoCase(arguments.needle, s)) return true;
        return false;
    }
}
