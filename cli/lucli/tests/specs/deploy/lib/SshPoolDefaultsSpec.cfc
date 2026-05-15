/**
 * Verifies that an SshPool constructed with defaults sourced from a
 * deploy.yml `ssh:` block actually reflects those values. `$defaults()`
 * exposes the resolved defaults struct so we can assert on it directly
 * without opening a real SSH connection.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("SshPool defaults from deploy.yml", () => {

            it("propagates user, port, and privateKey from the ssh: block", () => {
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-ssh.yml"));
                var s = cfg.ssh();
                var pool = new cli.lucli.services.deploy.lib.SshPool({
                    user: s.user(),
                    port: s.port(),
                    privateKey: s.keys()[1]
                });

                try {
                    var defaults = pool.$defaults();
                    expect(defaults.user).toBe("admin");
                    expect(defaults.port).toBe(2222);
                    expect(defaults.privateKey).toBe("/tmp/deploy_key_fixture");
                } finally {
                    pool.close();
                }
            });

            it("falls back to root@22 when no ssh: block is present", () => {
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
                var s = cfg.ssh();
                var pool = new cli.lucli.services.deploy.lib.SshPool({
                    user: s.user(),
                    port: s.port()
                });

                try {
                    var defaults = pool.$defaults();
                    expect(defaults.user).toBe("root");
                    expect(defaults.port).toBe(22);
                    expect(defaults.privateKey).toBe("");
                } finally {
                    pool.close();
                }
            });

        });
    }
}
