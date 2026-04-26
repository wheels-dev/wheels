component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployLockCli", () => {

            it("acquire emits ln -s at the service-scoped path", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.acquire({configPath: variables.fixture, message: "surgery"});
                var calls = fake.calls();
                expect(arrayLen(calls)).toBe(1);
                expect(calls[1].cmd).toInclude("ln -s");
                expect(calls[1].cmd).toInclude("/tmp/kamal_deploy_lock_demo");
                expect(calls[1].cmd).toInclude("surgery");
            });

            it("acquire defaults message to 'manual acquire' when not provided", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.acquire({configPath: variables.fixture});
                expect(fake.calls()[1].cmd).toInclude("manual acquire");
            });

            it("release emits rm -f at the service-scoped path", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.release({configPath: variables.fixture});
                expect(fake.calls()[1].cmd).toInclude("rm -f /tmp/kamal_deploy_lock_demo");
            });

            it("status emits readlink", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.status({configPath: variables.fixture});
                expect(fake.calls()[1].cmd).toInclude("readlink /tmp/kamal_deploy_lock_demo");
            });

            it("dry-run buffers output instead of dispatching", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.release({configPath: variables.fixture, dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                expect(arrayToList(cli.dryRunOutput(), chr(10))).toInclude("rm -f");
            });
        });
    }
}
