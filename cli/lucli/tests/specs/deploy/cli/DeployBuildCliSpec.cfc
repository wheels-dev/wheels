component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployBuildCli", () => {

            it("push --dry-run buffers local build command", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(fake);
                cli.push({configPath: variables.fixture, version: "v1", dryRun: true});
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("[local]");
                expect(out).toInclude("docker buildx build");
                expect(out).toInclude("--push");
                expect(out).toInclude("acme/demo:v1");
                expect(arrayLen(fake.calls())).toBe(0);
            });

            it("pull --dry-run buffers per-host docker pull", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(fake);
                cli.pull({configPath: variables.fixture, version: "v1", dryRun: true});
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("[1.2.3.4] docker pull acme/demo:v1");
            });

            it("deliver combines push and pull", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(fake);
                cli.deliver({configPath: variables.fixture, version: "v1", dryRun: true});
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker buildx build");
                expect(out).toInclude("docker pull acme/demo:v1");
            });

            it("create emits buildx create with the service-scoped builder name", () => {
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                cli.create({configPath: variables.fixture, dryRun: true});
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("[local]");
                expect(out).toInclude("docker buildx create");
                expect(out).toInclude("kamal-demo");
            });

            it("remove emits buildx rm", () => {
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                cli.remove({configPath: variables.fixture, dryRun: true});
                expect(arrayToList(cli.dryRunOutput(), chr(10))).toInclude("docker buildx rm kamal-demo");
            });

            it("details emits buildx inspect", () => {
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                cli.details({configPath: variables.fixture, dryRun: true});
                expect(arrayToList(cli.dryRunOutput(), chr(10))).toInclude("docker buildx inspect kamal-demo");
            });

            it("dev emits a --load build tagged :dirty", () => {
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                cli.dev({configPath: variables.fixture, dryRun: true});
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker buildx build");
                expect(out).toInclude("--load");
                expect(out).toInclude("acme/demo:dirty");
            });

            it("push without explicit version falls back to git short sha", () => {
                var cli = new cli.lucli.services.deploy.cli.DeployBuildCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                cli.push({configPath: variables.fixture, dryRun: true});
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker buildx build");
                expect(out).toInclude("--push");
                // Just assert we got SOMETHING after acme/demo:
                expect(reFind("acme/demo:[^ ]+", out)).toBeGT(0);
            });
        });
    }
}
