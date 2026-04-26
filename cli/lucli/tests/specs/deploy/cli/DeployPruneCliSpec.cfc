component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployPruneCli", () => {

            it("all dispatches prune-all on every host", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployPruneCli(fake);
                cli.all({configPath: variables.fixture});
                var calls = fake.calls();
                expect(arrayLen(calls)).toBe(1);
                expect(calls[1].cmd).toInclude("docker image prune");
                expect(calls[1].cmd).toInclude("docker ps -a");
            });

            it("images dispatches image-only prune", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployPruneCli(fake);
                cli.images({configPath: variables.fixture});
                expect(fake.calls()[1].cmd).toInclude("docker image prune");
                expect(fake.calls()[1].cmd).notToInclude("docker ps");
            });

            it("containers honors the --keep flag", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployPruneCli(fake);
                cli.containers({configPath: variables.fixture, keep: 3});
                expect(fake.calls()[1].cmd).toInclude("tail -n +4");
            });

            it("containers defaults keep to 5 when not provided", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployPruneCli(fake);
                cli.containers({configPath: variables.fixture});
                expect(fake.calls()[1].cmd).toInclude("tail -n +6");
            });

            it("dry-run buffers output instead of dispatching", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployPruneCli(fake);
                cli.all({configPath: variables.fixture, dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker image prune");
            });
        });
    }
}
