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
                expect($anyInclude(cmds, "--password-stdin")).toBeTrue();
                expect($anyInclude(cmds, "s3cret")).toBeFalse();
            });

            it("login delivers the password via stdin opts, not argv", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.login({configPath: variables.fixture, password: "s3cret"});
                var sawStdin = false;
                for (var c in fake.calls()) {
                    if ((c.opts.stdin ?: "") == "s3cret") {
                        sawStdin = true;
                        expect(c.cmd).notToInclude("s3cret");
                    }
                }
                expect(sawStdin).toBeTrue();
            });

            it("login without a resolvable password fails fast instead of sending an empty secret", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                var state = {threw: false};
                try {
                    cli.login({configPath: variables.fixture});
                } catch (DeployRegistryCli.MissingPassword e) {
                    state.threw = true;
                }
                expect(state.threw).toBeTrue();
                expect(arrayLen(fake.calls())).toBe(0);
            });

            it("a failed login never leaks the password in the exception", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var regCmds = new cli.lucli.services.deploy.commands.RegistryCommands(
                    new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture)
                );
                fake.expect("1.2.3.4", regCmds.login(),
                    {exitCode: 1, stdout: "", stderr: "unauthorized: incorrect username or password"});
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                var state = {threw: false, message: "", detail: ""};
                try {
                    cli.login({configPath: variables.fixture, password: "sup3r-s3cret-pw"});
                } catch (Wheels.Deploy.RemoteExecutionFailed e) {
                    state.threw = true;
                    state.message = e.message;
                    state.detail = e.detail ?: "";
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("docker login");
                expect(state.message).notToInclude("sup3r-s3cret-pw");
                expect(state.detail).notToInclude("sup3r-s3cret-pw");
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

            it("dry-run buffers output and never prints the password", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployRegistryCli(fake);
                cli.login({configPath: variables.fixture, password: "sup3r-s3cret-pw", dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker login");
                expect(out).toInclude("--password-stdin");
                expect(out).notToInclude("sup3r-s3cret-pw");
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
