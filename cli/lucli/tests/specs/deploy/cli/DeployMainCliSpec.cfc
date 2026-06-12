component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
        variables.proxyFixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-proxy.yml");
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

            // Regression for #3085 — config() loaded the YAML without forwarding
            // opts.destination, so `wheels deploy config --destination=X` printed
            // the un-overlaid base config while every other verb applied the overlay.
            it("config() applies the destination overlay (##3085)", () => {
                var base = getTempFile(getTempDirectory(), "yml");
                fileWrite(
                    base,
                    "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [192.0.2.10]"
                        & "#chr(10)#registry: {username: u, password: [X]}"
                );
                // Yaml.deepMerge replaces arrays whole, so the overlay's servers
                // list fully supersedes the base list — exactly the shape from
                // the issue repro.
                var overlay = new cli.lucli.services.deploy.config.ConfigLoader()
                    .$overlayPathFor(base, "staging");
                fileWrite(overlay, "servers:#chr(10)#  - 192.0.2.99");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool()
                    );
                    var out = dc.config({configPath: base, destination: "staging"});
                    expect(out).toInclude("192.0.2.99");
                    expect(out).notToInclude("192.0.2.10");
                } finally {
                    fileDelete(base);
                    fileDelete(overlay);
                }
            });

            it("config() without a destination dumps the base config unchanged", () => {
                var base = getTempFile(getTempDirectory(), "yml");
                fileWrite(
                    base,
                    "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [192.0.2.10]"
                        & "#chr(10)#registry: {username: u, password: [X]}"
                );
                var overlay = new cli.lucli.services.deploy.config.ConfigLoader()
                    .$overlayPathFor(base, "staging");
                fileWrite(overlay, "servers:#chr(10)#  - 192.0.2.99");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool()
                    );
                    var out = dc.config({configPath: base});
                    expect(out).toInclude("192.0.2.10");
                    expect(out).notToInclude("192.0.2.99");
                } finally {
                    fileDelete(base);
                    fileDelete(overlay);
                }
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

            it("init_stub writes config/deploy.yml, .kamal/secrets, Dockerfile, and .dockerignore to the target cwd", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd, true, true);

                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var msg = localCli.init_stub({cwd: tmpCwd, service: "demo", image: "acme/demo"});

                expect(fileExists(tmpCwd & "/config/deploy.yml")).toBeTrue();
                expect(fileExists(tmpCwd & "/.kamal/secrets")).toBeTrue();
                expect(directoryExists(tmpCwd & "/.kamal/hooks")).toBeTrue();
                expect(fileExists(tmpCwd & "/Dockerfile")).toBeTrue();
                expect(fileExists(tmpCwd & "/.dockerignore")).toBeTrue();
                expect(msg).toInclude("config/deploy.yml");
                expect(msg).toInclude("Dockerfile");

                directoryDelete(tmpCwd, true);
            });

            it("init_stub renders a Lucee 7 multi-stage Dockerfile with the service name in the label", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd, true, true);

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                localCli.init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});

                var df = fileRead(tmpCwd & "/Dockerfile");
                expect(df).toInclude("FROM lucee/lucee:7-tomcat10-jre21");
                expect(df).toInclude("EXPOSE 8080");
                expect(df).toInclude("HEALTHCHECK");
                expect(df).toInclude("myapp");

                var di = fileRead(tmpCwd & "/.dockerignore");
                expect(di).toInclude(".kamal/secrets");
                expect(di).toInclude("vendor/wheels/tests");

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

            it("init_stub refuses to overwrite an existing Dockerfile without force", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd, true, true);
                fileWrite(tmpCwd & "/Dockerfile", "FROM scratch");

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                expect(() => localCli.init_stub({cwd: tmpCwd, service: "x", image: "y/z"}))
                    .toThrow();

                // Existing Dockerfile must be untouched after the abort.
                expect(fileRead(tmpCwd & "/Dockerfile")).toBe("FROM scratch");

                directoryDelete(tmpCwd, true);
            });

            it("init_stub overwrites when force=true", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd & "/config", true, true);
                fileWrite(tmpCwd & "/config/deploy.yml", "old content");
                fileWrite(tmpCwd & "/Dockerfile", "FROM scratch");
                fileWrite(tmpCwd & "/.dockerignore", "## sentinel — pre-existing dockerignore");

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                var summary = localCli.init_stub({cwd: tmpCwd, service: "new", image: "new/web", force: true});
                var yml = fileRead(tmpCwd & "/config/deploy.yml");
                expect(yml).toInclude("service: new");
                var df = fileRead(tmpCwd & "/Dockerfile");
                expect(df).toInclude("FROM lucee/lucee");
                // force=true exercises the `force ||` branch of the dockerignore guard.
                var di = fileRead(tmpCwd & "/.dockerignore");
                expect(di).notToInclude("sentinel");
                expect(summary).toInclude(".dockerignore");
                expect(summary).notToInclude("preserved");

                directoryDelete(tmpCwd, true);
            });

            it("init_stub silently preserves an existing .dockerignore without force", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-init-" & createUUID();
                directoryCreate(tmpCwd, true, true);
                var sentinel = "## sentinel — user's dockerignore must survive";
                fileWrite(tmpCwd & "/.dockerignore", sentinel);

                var localCli = new cli.lucli.services.deploy.cli.DeployMainCli(
                    new cli.lucli.services.deploy.lib.FakeSshPool()
                );
                var summary = localCli.init_stub({cwd: tmpCwd, service: "x", image: "y/z"});

                expect(fileRead(tmpCwd & "/.dockerignore")).toBe(sentinel);
                expect(summary).toInclude("preserved existing .dockerignore");

                directoryDelete(tmpCwd, true);
            });

            // Regression for #2658 — expandPath('/cli/lucli/...') resolved against the running app's mapping root, breaking init inside a generated user app.
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
                expect(fileExists(root & "templates/deploy/init/Dockerfile.mustache")).toBeTrue();
                expect(fileExists(root & "templates/deploy/init/dockerignore.mustache")).toBeTrue();
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

            // Regression tests for issue #2230 — deploy verbs returned a blank string in real (non-dry-run) mode because Module.cfc wrapped the void methods with dryRunOutput(), which is only populated during dry-run. Real deploys must return a visible success summary; dry-run must continue to return the buffered command list.

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

            // Regression suite for #2696 — deploy verbs reported success even when the
            // underlying SSH command on the remote exited nonzero. The fix has SshClient
            // raise Wheels.Deploy.RemoteExecutionFailed on nonzero exits, and the
            // deploy dispatchers opt-in to that strict mode for every non-teardown verb.

            it("deploy throws Wheels.Deploy.RemoteExecutionFailed when docker pull fails on the remote (##2696)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                // Use the same component the production deploy uses to compute the exact pull command.
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
                var pullCmd = builder.pull("v1");
                fake.expect("1.2.3.4", pullCmd, {
                    exitCode: 1, stdout: "",
                    stderr: "Error response from daemon: manifest unknown"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                expect(() => dc.deploy({configPath: variables.fixture, version: "v1"}))
                    .toThrow(type="Wheels.Deploy.RemoteExecutionFailed", regex="exit 1");
            });

            it("setup throws Wheels.Deploy.RemoteExecutionFailed when docker pull fails (alias for deploy) (##2696)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
                fake.expect("1.2.3.4", builder.pull("v1"), {
                    exitCode: 1, stdout: "", stderr: "manifest unknown"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                expect(() => dc.setup({configPath: variables.fixture, version: "v1"}))
                    .toThrow(type="Wheels.Deploy.RemoteExecutionFailed");
            });

            it("the thrown Wheels.Deploy.RemoteExecutionFailed names the host, exit code, and a command summary (##2696)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
                fake.expect("1.2.3.4", builder.pull("v1"), {
                    exitCode: 125, stdout: "",
                    stderr: "denied: requested access to the resource is denied"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                try {
                    dc.deploy({configPath: variables.fixture, version: "v1"});
                    fail("expected deploy to throw");
                } catch (any e) {
                    expect(e.type).toBe("Wheels.Deploy.RemoteExecutionFailed");
                    expect(e.message).toInclude("1.2.3.4");
                    expect(e.message).toInclude("125");
                    expect(e.message).toInclude("docker pull");
                    expect(e.detail).toInclude("denied");
                }
            });

            it("rollback throws on a failing docker start (##2696)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var app = new cli.lucli.services.deploy.commands.AppCommands(cfg);
                var startCmd = app.start(cfg.roles()[1], "v-old");
                fake.expect("1.2.3.4", startCmd, {
                    exitCode: 1, stdout: "", stderr: "No such container: demo-web-v-old"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                expect(() => dc.rollback({configPath: variables.fixture, version: "v-old"}))
                    .toThrow(type="Wheels.Deploy.RemoteExecutionFailed");
            });

            it("remove --confirm tolerates a missing kamal-proxy and still dispatches the remaining teardown steps (##2696)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var proxyCmds = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
                fake.expect("1.2.3.4", proxyCmds.remove(), {
                    exitCode: 1, stdout: "", stderr: "Error: No such container: kamal-proxy"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.remove({configPath: variables.fixture, confirm: true});
                expect(out).toInclude("Removed");
                // After the tolerated proxy step, registry logout must still have been issued.
                var cmds = [];
                for (var c in fake.calls()) arrayAppend(cmds, c.cmd ?: "");
                var sawLogout = false;
                for (var s in cmds) if (findNoCase("docker logout", s)) sawLogout = true;
                expect(sawLogout).toBeTrue();
            });

            it("a failing lock-release in the finally block does not mask the original deploy exception (##2696)", () => {
                // lock.release() runs in the deploy() finally block and must never
                // shadow the original deploy exception. Inject a release failure
                // alongside a pull failure and assert the surfaced exception is the
                // pull one (the original cause), not the release one.
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                fake.expect("1.2.3.4", builder.pull("v1"), {
                    exitCode: 1, stdout: "", stderr: "manifest unknown"
                });
                fake.expect("1.2.3.4", lockCmds.release(), {
                    exitCode: 1, stdout: "", stderr: "rm: cannot remove"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                try {
                    dc.deploy({configPath: variables.fixture, version: "v1"});
                    fail("expected deploy to throw");
                } catch (any e) {
                    // The surfaced error must be the pull failure, NOT the lock release failure.
                    expect(e.type).toBe("Wheels.Deploy.RemoteExecutionFailed");
                    expect(e.message).toInclude("docker pull");
                }
            });

            // Regression suite for #3087 — a failing post-deploy-failure hook used to
            // throw DeployMainCli.HookFailed from inside the deploy catch block,
            // replacing the original deploy error. The hook fires on an already-failed
            // path, so it must be best-effort: run, log a non-zero exit, and let the
            // original exception rethrow.

            it("a failing post-deploy-failure hook does not mask the original deploy error (##3087)", () => {
                var tmpProject = getTempDirectory() & "/wheels-3087-" & createUUID();
                var marker = tmpProject & "/hook-ran.txt";
                directoryCreate(tmpProject & "/.kamal/hooks", true, true);
                // The hook proves it ran (marker file) and then fails.
                fileWrite(
                    tmpProject & "/.kamal/hooks/post-deploy-failure",
                    "##!/usr/bin/env bash" & chr(10)
                        & "echo ran > " & marker & chr(10)
                        & "exit 1"
                );
                fileSetAccessMode(tmpProject & "/.kamal/hooks/post-deploy-failure", "755");

                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
                fake.expect("1.2.3.4", builder.pull("v1"), {
                    exitCode: 1, stdout: "", stderr: "manifest unknown"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake, {projectRoot: tmpProject});
                // savecontent captures the hook log (asserted below) and keeps
                // real-mode hook output out of the test runner's response stream.
                var state = {threw = false, errType = "", errMsg = "", logged = ""};
                savecontent variable="state.logged" {
                    try {
                        dc.deploy({configPath: variables.fixture, version: "v1"});
                    } catch (any e) {
                        state.threw = true;
                        state.errType = e.type;
                        state.errMsg = e.message;
                    }
                }
                // The surfaced error must be the original pull failure,
                // NOT DeployMainCli.HookFailed from the notification hook.
                expect(state.threw).toBeTrue();
                expect(state.errType).toBe("Wheels.Deploy.RemoteExecutionFailed");
                expect(state.errMsg).toInclude("docker pull");
                // ...and the hook's non-zero exit is logged, not thrown.
                expect(state.logged).toInclude("[hook:post-deploy-failure]");
                expect(state.logged).toInclude("exited with code 1");
                directoryDelete(tmpProject, true);
            });

            it("the post-deploy-failure hook still runs (best-effort) before the original error rethrows (##3087)", () => {
                var tmpProject = getTempDirectory() & "/wheels-3087-ran-" & createUUID();
                var marker = tmpProject & "/hook-ran.txt";
                directoryCreate(tmpProject & "/.kamal/hooks", true, true);
                fileWrite(
                    tmpProject & "/.kamal/hooks/post-deploy-failure",
                    "##!/usr/bin/env bash" & chr(10)
                        & "echo ""$KAMAL_ERROR"" > " & marker & chr(10)
                        & "exit 1"
                );
                fileSetAccessMode(tmpProject & "/.kamal/hooks/post-deploy-failure", "755");

                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
                fake.expect("1.2.3.4", builder.pull("v1"), {
                    exitCode: 1, stdout: "", stderr: "manifest unknown"
                });
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake, {projectRoot: tmpProject});
                var state = {threw = false, logged = ""};
                savecontent variable="state.logged" {
                    try {
                        dc.deploy({configPath: variables.fixture, version: "v1"});
                    } catch (any e) {
                        state.threw = true;
                    }
                }
                expect(state.threw).toBeTrue();
                // The hook ran and received KAMAL_ERROR even though it exited non-zero.
                expect(fileExists(marker)).toBeTrue();
                expect(fileRead(marker)).toInclude("exit 1");
                directoryDelete(tmpProject, true);
            });

            // Regression suite for #3089 — deploy()/rollback() hardcoded the
            // kamal-proxy target to <container>:3000, ignoring proxy.app_port
            // (code default 80; `wheels deploy init` scaffolds 8080).

            it("deploy --dry-run builds the kamal-proxy target from proxy.app_port (##3089)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.deploy({
                    configPath: variables.proxyFixture,
                    dryRun: true,
                    version: "v1"
                });
                expect(out).toInclude("--target demo-web-v1:8080");
                expect(out).notToInclude(":3000");
            });

            it("rollback --dry-run builds the kamal-proxy target from proxy.app_port (##3089)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.rollback({
                    configPath: variables.proxyFixture,
                    dryRun: true,
                    version: "v-old"
                });
                expect(out).toInclude("--target demo-web-v-old:8080");
                expect(out).notToInclude(":3000");
            });

            it("deploy --dry-run falls back to app_port default 80 when proxy is unconfigured (##3089)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.deploy({
                    configPath: variables.fixture,
                    dryRun: true,
                    version: "v1"
                });
                expect(out).toInclude("--target demo-web-v1:80");
                expect(out).notToInclude(":3000");
            });

            // env.secret delivery (#2957, Wave 2b) — deploy writes a remote env
            // file (600 perms) per role and references it via --env-file. Secret
            // values travel only over SFTP (uploadString); they never appear in
            // any command string, dry-run line, or exception summary.

            it("deploy writes the env file (600 perms) before docker run and keeps secret values out of argv (##2957)", () => {
                var proj = $makeSecretProject();
                try {
                    var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                    dc.deploy({configPath: proj.config, version: "v1"});

                    var calls = fake.calls();
                    var ensureIdx = 0; var uploadIdx = 0; var relockIdx = 0; var runIdx = 0;
                    for (var i = 1; i <= arrayLen(calls); i++) {
                        var cmd = calls[i].cmd ?: "";
                        if (!ensureIdx && findNoCase("chmod 600", cmd)
                            && find(".kamal/apps/demo/env/roles/web.env", cmd)) ensureIdx = i;
                        if (!uploadIdx && (calls[i].kind ?: "") == "uploadString") uploadIdx = i;
                        // Post-upload re-lock: the SFTP layer may reset perms
                        // (sshj preserve-attributes), so a second chmod 600
                        // must follow the upload (##2957).
                        if (uploadIdx && i > uploadIdx && !relockIdx
                            && findNoCase("chmod 600", cmd)
                            && find(".kamal/apps/demo/env/roles/web.env", cmd)) relockIdx = i;
                        // Match the APP run specifically — the proxy boot
                        // fallback (details() || boot()) also contains a
                        // `docker run --detach`, dispatched before this.
                        if (!runIdx && findNoCase("docker run --detach", cmd)
                            && find("--name demo-web-v1", cmd)) runIdx = i;
                    }
                    // ensure (mkdir+touch+chmod 600) → upload → re-lock
                    // (chmod 600) → docker run, in order.
                    expect(ensureIdx).toBeGT(0);
                    expect(uploadIdx).toBeGT(ensureIdx);
                    expect(relockIdx).toBeGT(uploadIdx);
                    expect(runIdx).toBeGT(relockIdx);

                    // The upload carries the resolved value to the role env file.
                    expect(calls[uploadIdx].remote).toBe(".kamal/apps/demo/env/roles/web.env");
                    expect(calls[uploadIdx].content).toInclude("APP_SECRET=s3cr3t-value-42");

                    // docker run references the env file; the value appears in NO command.
                    expect(calls[runIdx].cmd).toInclude("--env-file .kamal/apps/demo/env/roles/web.env");
                    for (var c in calls) {
                        expect(c.cmd ?: "").notToInclude("s3cr3t-value-42");
                    }
                } finally {
                    directoryDelete(proj.root, true);
                }
            });

            it("deploy --dry-run notes the env-file upload by name only — values never shown (##2957)", () => {
                var proj = $makeSecretProject();
                try {
                    var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                    var out = dc.deploy({configPath: proj.config, version: "v1", dryRun: true});
                    expect(arrayLen(fake.calls())).toBe(0);
                    expect(out).toInclude("chmod 600");
                    expect(out).toInclude(".kamal/apps/demo/env/roles/web.env");
                    expect(out).toInclude("APP_SECRET");
                    expect(out).toInclude("--env-file .kamal/apps/demo/env/roles/web.env");
                    expect(out).notToInclude("s3cr3t-value-42");
                } finally {
                    directoryDelete(proj.root, true);
                }
            });

            it("deploy fails fast with Wheels.Deploy.EnvSecretMissing before any remote call when a secret can't be resolved (##2957)", () => {
                var proj = $makeSecretProject("UNDECLARED_KEY");
                try {
                    var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                    var state = {threw: false, message: ""};
                    try {
                        dc.deploy({configPath: proj.config, version: "v1"});
                    } catch (Wheels.Deploy.EnvSecretMissing e) {
                        state.threw = true;
                        state.message = e.message;
                    }
                    expect(state.threw).toBeTrue();
                    expect(state.message).toInclude("UNDECLARED_KEY");
                    // No lock acquired, nothing dispatched — fail-fast happens locally.
                    expect(arrayLen(fake.calls())).toBe(0);
                } finally {
                    directoryDelete(proj.root, true);
                }
            });

            // Regression for #2671 — git's stderr ("fatal: not a git repository...") used to leak through as the version string.
            it("$gitShortSha() returns 'unknown' when run outside a git repo", () => {
                var nonGitDir = getTempDirectory() & "/wheels-2671-main-" & createUUID();
                directoryCreate(nonGitDir, true, true);
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool()
                    );
                    var sha = dc.$gitShortSha(nonGitDir);
                    expect(sha).toBe("unknown");
                    // Belt-and-braces: explicit no-leak assertions documenting the original bug shape.
                    expect(findNoCase("fatal", sha)).toBe(0);
                    expect(findNoCase("not a git repository", sha)).toBe(0);
                } finally {
                    directoryDelete(nonGitDir, true);
                }
            });
        });
    }

    private boolean function $anyInclude(required array arr, required string needle) {
        for (var s in arguments.arr) if (findNoCase(arguments.needle, s)) return true;
        return false;
    }

    /**
     * Scaffold a temp project with config/deploy.yml declaring env.secret
     * and a .kamal/secrets file resolving APP_SECRET. Pass a different
     * secretName to declare a key the secrets file does NOT resolve.
     */
    private struct function $makeSecretProject(string secretName = "APP_SECRET") {
        var root = getTempDirectory() & "/wheels-2957-envfile-" & createUUID();
        directoryCreate(root & "/config", true, true);
        directoryCreate(root & "/.kamal", true, true);
        fileWrite(
            root & "/config/deploy.yml",
            "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                & "registry: {username: u, password: [REGISTRY_PASSWORD]}#chr(10)#"
                & "env: {clear: {DB_HOST: db.internal}, secret: [" & arguments.secretName & "]}"
        );
        fileWrite(
            root & "/.kamal/secrets",
            "APP_SECRET=s3cr3t-value-42#chr(10)#REGISTRY_PASSWORD=regpw"
        );
        return {root: root, config: root & "/config/deploy.yml"};
    }
}
