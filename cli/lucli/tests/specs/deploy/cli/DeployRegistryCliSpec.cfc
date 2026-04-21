component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployRegistryCli", () => {

            it("login emits docker login on every host", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.login({configPath: variables.fixture, password: "s3cret"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker login")).toBeTrue();
                expect($anyInclude(cmds, "-u demo")).toBeTrue();
                expect($anyInclude(cmds, "-p s3cret")).toBeTrue();
            });

            it("setup is an alias for login", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.setup({configPath: variables.fixture, password: "s3cret"});
                expect($anyInclude($cmdsFrom(fake), "docker login")).toBeTrue();
            });

            it("logout emits docker logout", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.logout({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "docker logout")).toBeTrue();
            });

            it("remove is an alias for logout", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.remove({configPath: variables.fixture});
                expect($anyInclude($cmdsFrom(fake), "docker logout")).toBeTrue();
            });

            it("dry-run buffers output", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.login({configPath: variables.fixture, password: "x", dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker login");
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
