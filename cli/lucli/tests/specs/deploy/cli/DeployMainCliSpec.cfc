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

            it("deploy acquires lock before pulling and releases after", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.deploy({configPath: variables.fixture, version: "v1"});
                var calls = fake.calls();
                var cmds = [];
                for (var c in calls) arrayAppend(cmds, c.cmd ?: "");

                var lockAcquireIdx = 0;
                var pullIdx = 0;
                var lockReleaseIdx = 0;
                for (var i = 1; i <= arrayLen(cmds); i++) {
                    if (!lockAcquireIdx
                        && findNoCase("ln -s ", cmds[i])
                        && findNoCase("kamal_deploy_lock_demo", cmds[i])) lockAcquireIdx = i;
                    if (!pullIdx && findNoCase("docker pull", cmds[i])) pullIdx = i;
                    if (!lockReleaseIdx
                        && findNoCase("rm -f ", cmds[i])
                        && findNoCase("kamal_deploy_lock_demo", cmds[i])) lockReleaseIdx = i;
                }
                expect(lockAcquireIdx).toBeGT(0);
                expect(pullIdx).toBeGT(lockAcquireIdx);
                expect(lockReleaseIdx).toBeGT(pullIdx);
            });

            it("dryRunOutput() includes pre-deploy and post-deploy hook markers when hooks exist", () => {
                var tmpProject = getTempDirectory() & "/wheels-deploy-hooktest-" & createUUID();
                directoryCreate(tmpProject & "/.kamal/hooks", true, true);
                fileWrite(
                    tmpProject & "/.kamal/hooks/pre-deploy",
                    "##!/usr/bin/env bash" & chr(10) & "echo pre"
                );
                fileWrite(
                    tmpProject & "/.kamal/hooks/post-deploy",
                    "##!/usr/bin/env bash" & chr(10) & "echo post"
                );
                fileSetAccessMode(tmpProject & "/.kamal/hooks/pre-deploy", "755");
                fileSetAccessMode(tmpProject & "/.kamal/hooks/post-deploy", "755");

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool(),
                    {projectRoot: tmpProject}
                );
                localCli.deploy({
                    configPath: variables.fixture,
                    version: "v1",
                    dryRun: true
                });
                var out = localCli.dryRunOutput();
                var joined = arrayToList(out, chr(10));

                expect(joined).toInclude("hook pre-deploy");
                expect(joined).toInclude("hook post-deploy");

                directoryDelete(tmpProject, true);
            });

            it("dryRunOutput() omits hook markers when hooks don't exist", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.deploy({
                    configPath: variables.fixture,
                    version: "v1",
                    dryRun: true
                });
                var out = dc.dryRunOutput();
                var joined = arrayToList(out, chr(10));
                expect(findNoCase("hook pre-deploy", joined)).toBe(0);
                expect(findNoCase("hook post-deploy", joined)).toBe(0);
            });
        });
    }
}
