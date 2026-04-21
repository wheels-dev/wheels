component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.testHelper = new cli.lucli.tests.TestHelper();
        variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
        directoryCreate(tempRoot & "/vendor/wheels", true, true);
        variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function afterAll() {
        testHelper.cleanupTempProject(variables.tempRoot);
    }

    function run() {
        describe("Module.deploy() dispatch", () => {

            it("deploy version returns the pinned Kamal version string", () => {
                var out = variables.mod.deploy("version");
                expect(out).toInclude("kamal 2.4.0");
            });

            it("deploy config --configPath returns YAML output", () => {
                var out = variables.mod.deploy(
                    "config",
                    "--configPath=" & variables.fixture
                );
                expect(out).toInclude("service: demo");
            });

            it("deploy --dry-run returns the host-prefixed plan lines", () => {
                var out = variables.mod.deploy(
                    "--dry-run",
                    "--configPath=" & variables.fixture,
                    "--version=v1"
                );
                expect(out).toInclude("[1.2.3.4]");
                expect(out).toInclude("docker pull acme/demo:v1");
            });

            it("deploy rollback <version> dry-run includes start + proxy deploy", () => {
                var out = variables.mod.deploy(
                    "rollback",
                    "v-old",
                    "--dry-run",
                    "--configPath=" & variables.fixture
                );
                expect(out).toInclude("docker start demo-web-v-old");
                expect(out).toInclude("kamal-proxy deploy demo");
            });

            it("deploy rollback without version throws", () => {
                expect(() => variables.mod.deploy(
                    "rollback",
                    "--dry-run",
                    "--configPath=" & variables.fixture
                )).toThrow();
            });
        });
    }
}
