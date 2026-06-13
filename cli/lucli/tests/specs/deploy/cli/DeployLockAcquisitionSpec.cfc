/**
 * Regression suite for #2957 DEP-1 — the deploy lock was silently bypassable
 * on any multi-host fleet.
 *
 * The old flow acquired the lock via $dispatchAny → SshPool.onAny
 * (first-success-wins, every per-host exception swallowed): contention on
 * host 1 raised, onAny caught it, acquired a fresh lock on host 2, and the
 * concurrent deploy proceeded. Release was also $dispatchAny, so the released
 * host could differ from the acquired host, stranding stale locks.
 *
 * The fixed contract, asserted here via FakeSshPool:
 *   - acquire on EVERY (deduped) host, sequentially, with raise=true;
 *   - on a partial failure, roll back ONLY the already-acquired locks (the
 *     contended host's lock belongs to the other deploy) and abort with
 *     Wheels.Deploy.LockAcquireFailed naming the failing host;
 *   - release fans out to every host the lock was acquired on.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.multiHostFixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/multi-host.yml");
        variables.sharedHostFixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/shared-host.yml");
    }

    function run() {
        describe("deploy lock acquisition is all-or-nothing across the fleet (##2957 DEP-1)", () => {

            it("acquires the lock on every host before pulling and releases it on every host", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.deploy({configPath: variables.multiHostFixture, version: "v1"});

                var calls = fake.calls();
                var acquireHosts = [];
                var releaseHosts = [];
                var lastAcquireIdx = 0;
                var firstPullIdx = 0;
                var firstReleaseIdx = 0;
                for (var i = 1; i <= arrayLen(calls); i++) {
                    var cmd = calls[i].cmd ?: "";
                    if (findNoCase("ln -s ", cmd) && findNoCase("kamal_deploy_lock_demo", cmd)) {
                        arrayAppend(acquireHosts, calls[i].host);
                        lastAcquireIdx = i;
                    }
                    if (findNoCase("rm -f ", cmd) && findNoCase("kamal_deploy_lock_demo", cmd)) {
                        arrayAppend(releaseHosts, calls[i].host);
                        if (!firstReleaseIdx) firstReleaseIdx = i;
                    }
                    if (!firstPullIdx && findNoCase("docker pull", cmd)) firstPullIdx = i;
                }

                // Lock lives on EVERY host so a concurrent deploy collides no
                // matter which host it tries first.
                expect(acquireHosts).toBe(["10.0.0.1", "10.0.0.2"]);
                // Release targets the same hosts the lock was acquired on (DEP-1b).
                expect(releaseHosts).toBe(["10.0.0.1", "10.0.0.2"]);
                // Bracketing: every acquire precedes the pull; release follows it.
                expect(firstPullIdx).toBeGT(lastAcquireIdx);
                expect(firstReleaseIdx).toBeGT(firstPullIdx);
            });

            it("rolls back already-acquired locks and aborts when a later host's acquire fails", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.multiHostFixture);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                var acquireCmd = lockCmds.acquire({user: $envUser(), message: "deploy v1"});
                // Host 2 is contended — another deploy holds the lock there.
                fake.expect("10.0.0.2", acquireCmd, {
                    exitCode: 1,
                    stdout: "",
                    stderr: "ln: failed to create symbolic link '/tmp/kamal_deploy_lock_demo': File exists"
                });

                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var state = {threw = false, errType = "", errMsg = "", errDetail = ""};
                try {
                    dc.deploy({configPath: variables.multiHostFixture, version: "v1"});
                } catch (any e) {
                    state.threw = true;
                    state.errType = e.type;
                    state.errMsg = e.message;
                    state.errDetail = e.detail ?: "";
                }

                expect(state.threw).toBeTrue();
                expect(state.errType).toBe("Wheels.Deploy.LockAcquireFailed");
                // The per-host error is surfaced, not swallowed.
                expect(state.errMsg).toInclude("10.0.0.2");
                expect(state.errDetail).toInclude("File exists");

                // The deploy body never started.
                var sawPull = false;
                var releaseHosts = [];
                for (var c in fake.calls()) {
                    var cmd = c.cmd ?: "";
                    if (findNoCase("docker pull", cmd)) sawPull = true;
                    if (findNoCase("rm -f ", cmd) && findNoCase("kamal_deploy_lock_demo", cmd)) {
                        arrayAppend(releaseHosts, c.host);
                    }
                }
                expect(sawPull).toBeFalse();
                // Rollback released ONLY the lock we acquired on host 1 — the
                // contended lock on host 2 belongs to the other deploy and
                // must never be removed.
                expect(releaseHosts).toBe(["10.0.0.1"]);
            });

            it("a contended first host aborts with no rollback releases and no deploy body", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.multiHostFixture);
                var lockCmds = new cli.lucli.services.deploy.commands.LockCommands(cfg);
                var acquireCmd = lockCmds.acquire({user: $envUser(), message: "deploy v1"});
                fake.expect("10.0.0.1", acquireCmd, {
                    exitCode: 1,
                    stdout: "",
                    stderr: "ln: failed to create symbolic link '/tmp/kamal_deploy_lock_demo': File exists"
                });

                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var state = {threw = false, errType = ""};
                try {
                    dc.deploy({configPath: variables.multiHostFixture, version: "v1"});
                } catch (any e) {
                    state.threw = true;
                    state.errType = e.type;
                }
                expect(state.threw).toBeTrue();
                expect(state.errType).toBe("Wheels.Deploy.LockAcquireFailed");

                // Nothing was acquired, so nothing may be released — and the
                // acquire on host 2 must never have been attempted.
                for (var c in fake.calls()) {
                    var cmd = c.cmd ?: "";
                    expect(findNoCase("rm -f ", cmd)).toBe(0);
                    expect(findNoCase("docker pull", cmd)).toBe(0);
                    if (findNoCase("ln -s ", cmd)) {
                        expect(c.host).toBe("10.0.0.1");
                    }
                }
            });

            it("locks a host serving multiple roles only once (no self-contention)", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                dc.deploy({configPath: variables.sharedHostFixture, version: "v1"});

                var acquires = [];
                for (var c in fake.calls()) {
                    var cmd = c.cmd ?: "";
                    if (findNoCase("ln -s ", cmd) && findNoCase("kamal_deploy_lock_demo", cmd)) {
                        arrayAppend(acquires, c.host);
                    }
                }
                // 10.0.0.5 serves both the web and job roles; acquiring twice
                // would fail the second ln -s and deadlock the deploy on itself.
                expect(acquires).toBe(["10.0.0.5"]);
            });

            it("dry-run renders the lock acquire per host without touching the pool", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake);
                var out = dc.deploy({
                    configPath: variables.multiHostFixture,
                    version: "v1",
                    dryRun: true
                });
                expect(arrayLen(fake.calls())).toBe(0);
                expect(out).toInclude("[10.0.0.1] ln -s");
                expect(out).toInclude("[10.0.0.2] ln -s");
                expect(out).toInclude("[10.0.0.1] rm -f");
                expect(out).toInclude("[10.0.0.2] rm -f");
            });
        });
    }

    // Mirrors DeployMainCli.$currentUser so FakeSshPool expectations match
    // the exact acquire command the deploy flow builds.
    private string function $envUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
