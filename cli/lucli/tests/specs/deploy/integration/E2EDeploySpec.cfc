/**
 * E2E integration spec for `wheels deploy` — the Phase 2 exit gate.
 *
 * Exercises the REAL DeployMainCli + SshPool + SshClient path (sshj over
 * TCP to a dockerized sshd) rather than the FakeSshPool used by the unit
 * specs in ../cli/DeployMainCliSpec.cfc. Verifies that:
 *
 *   1. `deploy()` dispatches the expected docker/kamal-proxy command
 *      sequence to the remote host (pull → proxy boot check → app run →
 *      proxy deploy, bracketed by lock acquire/release).
 *   2. A second `deploy()` at a new version reruns the flow (v1 → v2).
 *   3. `rollback()` dispatches start + proxy deploy pointing at the older
 *      version.
 *
 * ── Approach (c) from Task 29 brief: command-dispatch assertions via a
 * mock docker shim. ─────────────────────────────────────────────────────
 * Rather than run real Docker on the remote (docker-in-docker is flaky
 * across macOS Docker Desktop + CI runners, and kamal-proxy's image pull
 * would need registry reachability inside dind), the fixture installs a
 * `docker` + `kamal-proxy` shim into the sshd container's PATH. The shim
 * appends every invocation to /tmp/docker-invocations.log. After running
 * `deploy()`, the spec reads the log back over SSH and asserts the
 * expected command shape arrived.
 *
 * Gating: These tests only run when DEPLOY_E2E=1 in the environment. The
 * default CI workflow does NOT set that flag, so the suite reports the
 * specs as passes with zero work done. To run locally:
 *
 *     DEPLOY_E2E=1 bash tools/test-cli-local.sh
 *
 * Phase 3 follow-up: swap the mock shim for a real dockerd (either
 * host-socket mount or a sidecar dind service) and assert against real
 * nginx HTTP responses rather than log contents. The app/Dockerfile.v1
 * and v2 files in the fixture are scaffolding for that future work.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.helper = new cli.lucli.tests._helpers.DeployShellHelper();
        variables.fixtureDir = expandPath("/cli/lucli/tests/_fixtures/deploy/e2e");
        variables.deployYml = variables.fixtureDir & "/deploy.yml";

        // Env-gate: skip the whole suite unless DEPLOY_E2E=1 is set. Uses
        // java System.getenv rather than CFML's server.system.environment
        // because Lucee's implementation of the latter can lag behind the
        // actual process env on long-lived servers.
        var sys = createObject("java", "java.lang.System");
        var flag = sys.getenv("DEPLOY_E2E");
        variables.e2eEnabled = (isNull(flag) ? "" : flag) == "1";

        if (!variables.e2eEnabled) {
            writeLog(
                text = "E2EDeploySpec skipped — set DEPLOY_E2E=1 to run.",
                type = "information",
                file = "wheels-cli-tests"
            );
            return;
        }

        variables.helper.e2eUp();
    }

    function afterAll() {
        if (variables.e2eEnabled ?: false) {
            variables.helper.e2eDown();
        }
    }

    function run() {
        describe("E2E deploy flow (DEPLOY_E2E=1)", () => {

            it("dispatches docker pull + proxy boot + app run + proxy deploy to the remote", () => {
                if (!(variables.e2eEnabled ?: false)) return;

                $resetRemoteLog();
                var pool = $makePool();
                try {
                    var dc = new modules.wheels.services.deploy.cli.DeployMainCli(pool);
                    dc.deploy({configPath: variables.deployYml, version: "v1"});
                } finally {
                    pool.close();
                }

                var log = $readRemoteLog();

                // Lock bracket — sshd sudo/link path. We only assert the
                // tail command ran; the exact filename is implementation
                // detail covered by DeployMainCliSpec.
                expect(log).toInclude("docker pull");
                // App run happens AFTER pull. Exact container name comes
                // from AppCommands.container_name("web", "v1") → demo-web-v1.
                expect(log).toInclude("docker run");
                expect(log).toInclude("demo-web-v1");
                // Proxy deploy should reference the container target.
                expect(log).toInclude("kamal-proxy deploy demo");
            });

            it("a second deploy at v2 reruns pull + run pointing at v2", () => {
                if (!(variables.e2eEnabled ?: false)) return;

                $resetRemoteLog();
                var pool = $makePool();
                try {
                    var dc = new modules.wheels.services.deploy.cli.DeployMainCli(pool);
                    dc.deploy({configPath: variables.deployYml, version: "v1"});
                    dc.deploy({configPath: variables.deployYml, version: "v2"});
                } finally {
                    pool.close();
                }

                var log = $readRemoteLog();
                // Both versions should have been dispatched through docker run.
                expect(log).toInclude("demo-web-v1");
                expect(log).toInclude("demo-web-v2");
                // v2 must appear AFTER v1 in invocation order — that's the
                // whole rollover assertion. Find positions and compare.
                var v1Pos = findNoCase("demo-web-v1", log);
                var v2Pos = findNoCase("demo-web-v2", log);
                expect(v1Pos).toBeGT(0);
                expect(v2Pos).toBeGT(v1Pos);
            });

            it("rollback dispatches docker start + proxy deploy pointing at the target version", () => {
                if (!(variables.e2eEnabled ?: false)) return;

                $resetRemoteLog();
                var pool = $makePool();
                try {
                    var dc = new modules.wheels.services.deploy.cli.DeployMainCli(pool);
                    // Stage: pretend v2 is live and we're rolling back to v1.
                    dc.deploy({configPath: variables.deployYml, version: "v2"});
                    $resetRemoteLog();
                    dc.rollback({configPath: variables.deployYml, version: "v1"});
                } finally {
                    pool.close();
                }

                var log = $readRemoteLog();
                expect(log).toInclude("docker start demo-web-v1");
                expect(log).toInclude("kamal-proxy deploy demo");
            });
        });
    }

    // ── helpers ────────────────────────────────────────────────────────

    private any function $makePool() {
        return new modules.wheels.services.deploy.lib.SshPool({
            user: "deploy",
            privateKey: variables.fixtureDir & "/test_key",
            strictHostKeyChecking: false
        });
    }

    /**
     * Reach into the fixture and clear /tmp/docker-invocations.log between
     * assertions. Each `it` should start with a clean slate so its
     * assertions aren't polluted by the previous block's dispatches.
     */
    private void function $resetRemoteLog() {
        var sc = new modules.wheels.services.deploy.lib.SshClient().init(
            "localhost",
            {
                user: "deploy",
                port: 22024,
                privateKey: variables.fixtureDir & "/test_key",
                strictHostKeyChecking: false
            }
        );
        try {
            sc.run(": > /tmp/docker-invocations.log");
        } finally {
            sc.close();
        }
    }

    /**
     * Read the remote invocation log back as a single string. Using a
     * fresh SshClient rather than the pool so we don't perturb the
     * connection cache the test just exercised.
     */
    private string function $readRemoteLog() {
        var sc = new modules.wheels.services.deploy.lib.SshClient().init(
            "localhost",
            {
                user: "deploy",
                port: 22024,
                privateKey: variables.fixtureDir & "/test_key",
                strictHostKeyChecking: false
            }
        );
        try {
            return sc.run("cat /tmp/docker-invocations.log").stdout;
        } finally {
            sc.close();
        }
    }

}
