component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployServerCli", () => {

            it("runs the given command on every host", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployServerCli(fake);
                cli.exec({configPath: variables.fixture, cmd: "df -h"});
                var calls = fake.calls();
                expect(arrayLen(calls)).toBe(1);
                expect(calls[1].cmd).toBe("df -h");
            });

            it("honors host filter", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployServerCli(fake);
                cli.exec({configPath: variables.fixture, cmd: "uname -a", host: "1.2.3.4"});
                expect(arrayLen(fake.calls())).toBe(1);
            });

            it("throws when host filter does not match any configured server", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployServerCli(fake);
                expect(() => cli.exec({configPath: variables.fixture, cmd: "x", host: "9.9.9.9"}))
                    .toThrow();
            });

            it("requires the cmd opt", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployServerCli(fake);
                expect(() => cli.exec({configPath: variables.fixture}))
                    .toThrow();
            });

            it("bootstrap emits the docker install one-liner", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployServerCli(fake);
                cli.bootstrap({configPath: variables.fixture});
                var calls = fake.calls();
                expect(calls[1].cmd).toInclude("which docker");
                expect(calls[1].cmd).toInclude("get.docker.com");
            });

            it("dry-run buffers instead of dispatching", () => {
                var fake = new modules.wheels.services.deploy.lib.FakeSshPool();
                var cli = new modules.wheels.services.deploy.cli.DeployServerCli(fake);
                cli.bootstrap({configPath: variables.fixture, dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                expect(arrayToList(cli.dryRunOutput(), chr(10))).toInclude("get.docker.com");
            });
        });
    }
}
