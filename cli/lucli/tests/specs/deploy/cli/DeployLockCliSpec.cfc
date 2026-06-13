component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
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
}
