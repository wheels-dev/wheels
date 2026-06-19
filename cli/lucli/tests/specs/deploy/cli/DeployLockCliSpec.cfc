component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
        variables.multiHostFixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/multi-host.yml");
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

            // Regression suite for #2957 DEP-1 — the manual lock verbs used the
            // same first-success-wins $dispatchAny as the deploy flow, so a
            // manual acquire could land on a different host than a concurrent
            // deploy probed, and a manual release could clear only one host of
            // a fleet-wide lock, stranding the rest.

            it("acquire dispatches to every host in order (##2957 DEP-1)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.acquire({configPath: variables.multiHostFixture, message: "surgery"});
                var hosts = [];
                for (var c in fake.calls()) {
                    expect(c.cmd).toInclude("ln -s");
                    arrayAppend(hosts, c.host);
                }
                expect(hosts).toBe(["10.0.0.1", "10.0.0.2"]);
            });

            it("acquire rolls back already-acquired locks when a later host is contended (##2957 DEP-1)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.multiHostFixture);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                var acquireCmd = lockCmds.acquire({user: $envUser(), message: "surgery"});
                fake.expect("10.0.0.2", acquireCmd, {
                    exitCode: 1,
                    stdout: "",
                    stderr: "ln: failed to create symbolic link '/tmp/kamal_deploy_lock_demo': File exists"
                });

                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                var state = {threw = false, errType = "", errMsg = ""};
                try {
                    cli.acquire({configPath: variables.multiHostFixture, message: "surgery"});
                } catch (any e) {
                    state.threw = true;
                    state.errType = e.type;
                    state.errMsg = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.errType).toBe("Wheels.Deploy.LockAcquireFailed");
                expect(state.errMsg).toInclude("10.0.0.2");

                var releaseHosts = [];
                for (var c in fake.calls()) {
                    if (findNoCase("rm -f ", c.cmd ?: "")) arrayAppend(releaseHosts, c.host);
                }
                // Only the acquired host is rolled back — the contended lock
                // on host 2 belongs to someone else.
                expect(releaseHosts).toBe(["10.0.0.1"]);
            });

            it("release fans out to every host (##2957 DEP-1)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.release({configPath: variables.multiHostFixture});
                var hosts = [];
                for (var c in fake.calls()) {
                    expect(c.cmd).toInclude("rm -f /tmp/kamal_deploy_lock_demo");
                    arrayAppend(hosts, c.host);
                }
                expect(hosts).toBe(["10.0.0.1", "10.0.0.2"]);
            });

            it("status fans out to every host (##2957 DEP-1)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                cli.status({configPath: variables.multiHostFixture});
                var hosts = [];
                for (var c in fake.calls()) {
                    expect(c.cmd).toInclude("readlink /tmp/kamal_deploy_lock_demo");
                    arrayAppend(hosts, c.host);
                }
                expect(hosts).toBe(["10.0.0.1", "10.0.0.2"]);
            });

            // Regression suite for the ##2957 review: release/status fanned out
            // via SshPool.onEach, which pre-resolves a connection for EVERY
            // host before running anything — one dead host aborted the whole
            // verb with zero commands executed. That turned the prescribed
            // stale-lock recovery path ("clear a stale lock with 'wheels
            // deploy lock release'") into a dead-end exactly when a host died
            // mid-deploy, the most plausible cause of fleet-wide stale locks.

            it("release skips an unreachable host and still clears the lock on the rest", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                fake.failConnection("10.0.0.1", "Connection refused");
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                var out = cli.release({configPath: variables.multiHostFixture});
                var releaseHosts = [];
                for (var c in fake.calls()) {
                    if (findNoCase("rm -f ", c.cmd ?: "")) arrayAppend(releaseHosts, c.host);
                }
                expect(releaseHosts).toBe(["10.0.0.2"]);
                // The summary names the skipped host so the operator knows the
                // release there is still pending.
                expect(out).toInclude("Released deploy lock");
                expect(out).toInclude("WARNING");
                expect(out).toInclude("10.0.0.1");
                expect(out).toInclude("Connection refused");
            });

            it("status reports an unreachable host as advisory output instead of throwing", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                fake.failConnection("10.0.0.2");
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                var out = cli.status({configPath: variables.multiHostFixture});
                var statusHosts = [];
                for (var c in fake.calls()) {
                    if (findNoCase("readlink ", c.cmd ?: "")) arrayAppend(statusHosts, c.host);
                }
                expect(statusHosts).toBe(["10.0.0.1"]);
                expect(out).toInclude("Checked deploy lock status");
                expect(out).toInclude("WARNING");
                expect(out).toInclude("10.0.0.2");
            });

            it("a transport-dead release still proceeds when the failure is a dead session, not a dead connect", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.multiHostFixture);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                // Host 1's connection is cached-but-dead: the connect succeeds,
                // the rm -f session throws a transport error despite raise=false.
                fake.expect("10.0.0.1", lockCmds.release(), {transportError: "Broken pipe"});
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                var out = cli.release({configPath: variables.multiHostFixture});
                var releaseHosts = [];
                for (var c in fake.calls()) {
                    if (findNoCase("rm -f ", c.cmd ?: "")) arrayAppend(releaseHosts, c.host);
                }
                // Host 1's release was attempted (recorded) before the session
                // died; host 2's still went through.
                expect(releaseHosts).toBe(["10.0.0.1", "10.0.0.2"]);
                expect(out).toInclude("WARNING");
                expect(out).toInclude("10.0.0.1");
            });

            // Regression suite for #2957 (Wave 3, DEP-6a) — `lock status`
            // dropped the ssh.run() result, so the operator never saw who
            // holds the lock (readlink's stdout) in live mode.

            it("status (real mode) surfaces the lock holder from readlink stdout (##2957 DEP-6a)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                fake.expect("1.2.3.4", lockCmds.status(), {
                    exitCode: 0, stdout: "deploy@ci-runner/2026-06-12T10:00:00/deploy v1",
                    stderr: "", durationMs: 0
                });
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                var out = cli.status({configPath: variables.fixture});
                expect(out).toInclude("[1.2.3.4] deploy@ci-runner/2026-06-12T10:00:00/deploy v1");
            });

            it("status (real mode) falls back to stderr when readlink fails (no lock held) (##2957 DEP-6a)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                fake.expect("1.2.3.4", lockCmds.status(), {
                    exitCode: 1, stdout: "",
                    stderr: "readlink: /tmp/kamal_deploy_lock_demo: No such file or directory",
                    durationMs: 0
                });
                var cli = new cli.lucli.services.deploy.cli.DeployLockCli(fake);
                var out = cli.status({configPath: variables.fixture});
                expect(out).toInclude("[1.2.3.4] readlink: /tmp/kamal_deploy_lock_demo: No such file or directory");
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

    // Mirrors DeployLockCli.$currentUser so FakeSshPool expectations match
    // the exact acquire command the verb builds.
    private string function $envUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
