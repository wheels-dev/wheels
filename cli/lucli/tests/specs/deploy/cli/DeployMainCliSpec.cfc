component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
    }

    function run() {
        describe("DeployMainCli", () => {
            // WheelsTest BDD only recognizes beforeAll/afterAll at the class
            // level — a fresh fake/cli per `it` is instantiated inline.

            it("version() reports the pinned Kamal version", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                expect(dc.version()).toInclude("kamal 2.4.0");
                expect(dc.version()).toInclude("kamal-proxy v0.8.6");
            });

            it("config() dumps resolved config as YAML", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.config({configPath: variables.fixture});
                expect(out).toInclude("service: demo");
                expect(out).toInclude("image: acme/demo");
            });

            it("deploy --dry-run emits commands without touching SshPool", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.deploy({
                    configPath: variables.fixture,
                    dryRun: true,
                    version: "v1"
                });
                expect(arrayLen(fake.calls())).toBe(0);
            });

            it("deploy (no dry-run) dispatches pull, proxy boot check, app run, proxy deploy in order", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.deploy({
                    configPath: variables.fixture,
                    version: "v1"
                });
                var calls = fake.calls();
                var cmds = [];
                for (var c in calls) arrayAppend(cmds, c.cmd ?: "");
                var pullIdx = 0; var runIdx = 0; var proxyIdx = 0;
                for (var i = 1; i <= arrayLen(cmds); i++) {
                    if (!pullIdx && findNoCase("docker pull", cmds[i])) pullIdx = i;
                    if (!runIdx && findNoCase("docker run --detach", cmds[i])) runIdx = i;
                    if (!proxyIdx && findNoCase("kamal-proxy deploy", cmds[i])) proxyIdx = i;
                }
                expect(pullIdx).toBeGT(0);
                expect(runIdx).toBeGT(pullIdx);
                expect(proxyIdx).toBeGT(runIdx);
            });

            it("rollback requires a version and dispatches start + proxy deploy", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.rollback({
                    configPath: variables.fixture,
                    version: "v-old"
                });
                var calls = fake.calls();
                var cmds = [];
                for (var c in calls) arrayAppend(cmds, c.cmd ?: "");
                var startIdx = 0; var proxyIdx = 0;
                for (var i = 1; i <= arrayLen(cmds); i++) {
                    if (!startIdx && findNoCase("docker start demo-web-v-old", cmds[i])) startIdx = i;
                    if (!proxyIdx && findNoCase("kamal-proxy deploy demo", cmds[i])) proxyIdx = i;
                }
                expect(startIdx).toBeGT(0);
                expect(proxyIdx).toBeGT(startIdx);
            });
        });
    }
}
