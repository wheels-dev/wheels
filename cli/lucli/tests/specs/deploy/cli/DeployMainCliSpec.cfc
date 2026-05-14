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

            it("init_stub writes config/deploy.yml and .kamal/secrets to the target cwd", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd, true, true);

                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var msg = localCli.init_stub({cwd: tmpCwd, service: "demo", image: "acme/demo"});

                expect(fileExists(tmpCwd & "/config/deploy.yml")).toBeTrue();
                expect(fileExists(tmpCwd & "/.kamal/secrets")).toBeTrue();
                expect(directoryExists(tmpCwd & "/.kamal/hooks")).toBeTrue();
                expect(msg).toInclude("config/deploy.yml");

                directoryDelete(tmpCwd, true);
            });

            it("init_stub populates the template with service + image names", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd, true, true);

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                localCli.init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});

                var yml = fileRead(tmpCwd & "/config/deploy.yml");
                expect(yml).toInclude("service: myapp");
                expect(yml).toInclude("image: acme/myapp");

                directoryDelete(tmpCwd, true);
            });

            it("init_stub refuses to overwrite an existing config/deploy.yml without force", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd & "/config", true, true);
                fileWrite(tmpCwd & "/config/deploy.yml", "already here");

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                expect(() => localCli.init_stub({cwd: tmpCwd, service: "x", image: "y/z"}))
                    .toThrow();

                directoryDelete(tmpCwd, true);
            });

            it("init_stub overwrites when force=true", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd & "/config", true, true);
                fileWrite(tmpCwd & "/config/deploy.yml", "old content");

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                localCli.init_stub({cwd: tmpCwd, service: "new", image: "new/web", force: true});
                var yml = fileRead(tmpCwd & "/config/deploy.yml");
                expect(yml).toInclude("service: new");

                directoryDelete(tmpCwd, true);
            });

            // Regression for issue #2658: `wheels deploy init` resolved
            // templates via expandPath('/cli/lucli/...'), which uses the
            // running app's mapping root. Inside a generated user app
            // that path doesn't exist. Fix anchors resolution to the CFC
            // location (mirrors JarLoader.cfc).
            it("$cliInstallDir() resolves to the CLI install root, not the running app mapping", () => {
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                var root = dc.$cliInstallDir();

                expect(root).toBeString();
                var normalized = replace(root, "\", "/", "all");
                if (right(normalized, 1) == "/") normalized = left(normalized, len(normalized) - 1);
                expect(reFindNoCase("/cli/lucli$", normalized)).toBeGT(0);

                expect(directoryExists(root & "templates/deploy/init")).toBeTrue();
                expect(fileExists(root & "templates/deploy/init/deploy.yml.mustache")).toBeTrue();
            });

            it("audit dispatches tail of audit log to every host", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.audit({configPath: variables.fixture});
                expect(fake.calls()[1].cmd).toInclude("tail -n 100 /tmp/kamal-audit.log");
            });

            it("audit honors --tail flag", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.audit({configPath: variables.fixture, tail: 25});
                expect(fake.calls()[1].cmd).toInclude("tail -n 25");
            });

            it("docs without section prints the TOC", () => {
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                var out = dc.docs({});
                expect(out).toInclude("Available docs sections");
            });

            it("docs with a valid section prints its content", () => {
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                var out = dc.docs({section: "servers"});
                expect(out).toInclude("servers:");
            });

            it("docs with unknown section throws", () => {
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                expect(() => dc.docs({section: "nonexistent"})).toThrow();
            });

            it("details dispatches app containers + proxy details", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.details({configPath: variables.fixture});
                var cmds = [];
                for (var c in fake.calls()) arrayAppend(cmds, c.cmd ?: "");
                expect($anyInclude(cmds, "docker ps --filter label=service=demo")).toBeTrue();
                expect($anyInclude(cmds, "name=kamal-proxy")).toBeTrue();
            });

            it("remove without --confirm throws", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                expect(() => dc.remove({configPath: variables.fixture})).toThrow();
            });

            it("remove --confirm dispatches broad teardown", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.remove({configPath: variables.fixture, confirm: true});
                var cmds = [];
                for (var c in fake.calls()) arrayAppend(cmds, c.cmd ?: "");
                expect($anyInclude(cmds, "docker ps -a --filter label=service=demo")).toBeTrue();
                expect($anyInclude(cmds, "docker stop kamal-proxy")).toBeTrue();
                expect($anyInclude(cmds, "docker logout")).toBeTrue();
            });

            // Regression tests for issue #2230 — deploy verbs returned a blank
            // string in real (non-dry-run) mode because Module.cfc wrapped the
            // void methods with dryRunOutput(), which is only populated during
            // dry-run. Real deploys must return a visible success summary;
            // dry-run must continue to return the buffered command list.

            it("deploy (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.deploy({configPath: variables.fixture, version: "v1"});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("Deployed");
                expect(out).toInclude("demo");
                expect(out).toInclude("v1");
            });

            it("deploy --dry-run returns the buffered command list", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.deploy({
                    configPath: variables.fixture,
                    dryRun: true,
                    version: "v1"
                });
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("docker pull");
            });

            it("rollback (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.rollback({configPath: variables.fixture, version: "v-old"});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("Rolled back");
                expect(out).toInclude("v-old");
            });

            it("setup (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.setup({configPath: variables.fixture, version: "v1"});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("Deployed");
            });

            it("audit (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.audit({configPath: variables.fixture});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("audit log");
            });

            it("details (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.details({configPath: variables.fixture});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("details");
            });

            it("remove --confirm (real mode) returns a non-empty success summary", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.remove({configPath: variables.fixture, confirm: true});
                expect(len(out)).toBeGT(0);
                expect(out).toInclude("Removed");
                expect(out).toInclude("demo");
            });
        });
    }

    private boolean function $anyInclude(required array arr, required string needle) {
        for (var s in arguments.arr) if (findNoCase(arguments.needle, s)) return true;
        return false;
    }
}
