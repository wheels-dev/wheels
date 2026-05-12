component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployProxyCli", () => {

            it("boot emits proxy boot via SshPool", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.boot({configPath: variables.fixture});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker run")).toBeTrue();
                expect($anyInclude(cmds, "--name kamal-proxy")).toBeTrue();
            });

            it("reboot chains stop/rm/run", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.reboot({configPath: variables.fixture});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop kamal-proxy")).toBeTrue();
                expect($anyInclude(cmds, "docker rm kamal-proxy")).toBeTrue();
                expect($anyInclude(cmds, "docker run")).toBeTrue();
            });

            it("start dispatches docker start", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.start({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "docker start kamal-proxy")).toBeTrue();
            });

            it("stop dispatches docker stop", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.stop({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "docker stop kamal-proxy")).toBeTrue();
            });

            it("restart dispatches docker restart", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.restart({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "docker restart kamal-proxy")).toBeTrue();
            });

            it("details filters ps", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.details({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "name=kamal-proxy")).toBeTrue();
            });

            it("logs honors tail", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.logs({configPath: variables.fixture, tail: 25});
                expect($anyInclude($cmdsFrom(fake), "--tail 25")).toBeTrue();
            });

            it("remove chains stop + rm", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.remove({configPath: variables.fixture});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop kamal-proxy")).toBeTrue();
                expect($anyInclude(cmds, "docker rm kamal-proxy")).toBeTrue();
            });

            it("dry-run buffers output instead of dispatching", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployProxyCli(fake);
                cli.stop({configPath: variables.fixture, dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker stop kamal-proxy");
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
