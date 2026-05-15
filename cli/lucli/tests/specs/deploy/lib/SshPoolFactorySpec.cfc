/**
 * End-to-end coverage for the YAML → defaults → pool wiring. Drives
 * `SshPoolFactory` directly so the fileExists short-circuit, catch
 * swallow on malformed YAML, empty-key guard, and tilde expansion all
 * have explicit regression tests.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("SshPoolFactory.fromConfigPath", () => {

            it("propagates user, port, and the first key (tilde-expanded) from deploy.yml", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                try {
                    fileWrite(tmp,
                        "service: demo" & chr(10) &
                        "image: acme/demo" & chr(10) &
                        "servers: [1.2.3.4]" & chr(10) &
                        "ssh:" & chr(10) &
                        "  user: admin" & chr(10) &
                        "  port: 2222" & chr(10) &
                        "  keys:" & chr(10) &
                        "    - ~/.ssh/deploy_key" & chr(10) &
                        "registry: {username: u, password: [REGISTRY_PASSWORD]}" & chr(10)
                    );
                    var home = createObject("java", "java.lang.System").getProperty("user.home");
                    var pool = new cli.lucli.services.deploy.lib.SshPoolFactory().fromConfigPath(tmp);
                    try {
                        var d = pool.$defaults();
                        expect(d.user).toBe("admin");
                        expect(d.port).toBe(2222);
                        expect(d.privateKey).toBe(home & "/.ssh/deploy_key");
                    } finally {
                        pool.close();
                    }
                } finally {
                    if (fileExists(tmp)) fileDelete(tmp);
                }
            });

            it("falls back to root@22 with no privateKey when the ssh: block is absent", () => {
                var pool = new cli.lucli.services.deploy.lib.SshPoolFactory()
                    .fromConfigPath(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
                try {
                    var d = pool.$defaults();
                    expect(d.user).toBe("root");
                    expect(d.port).toBe(22);
                    expect(d.privateKey).toBe("");
                } finally {
                    pool.close();
                }
            });

            it("returns a defaultless pool when configPath is empty", () => {
                var pool = new cli.lucli.services.deploy.lib.SshPoolFactory().fromConfigPath("");
                try {
                    var d = pool.$defaults();
                    expect(d.user).toBe("root");
                    expect(d.port).toBe(22);
                    expect(d.privateKey).toBe("");
                } finally {
                    pool.close();
                }
            });

            it("returns a defaultless pool when configPath points at a missing file", () => {
                var pool = new cli.lucli.services.deploy.lib.SshPoolFactory()
                    .fromConfigPath(getTempDirectory() & "definitely-not-a-real-file.yml");
                try {
                    var d = pool.$defaults();
                    expect(d.user).toBe("root");
                    expect(d.port).toBe(22);
                } finally {
                    pool.close();
                }
            });

            it("swallows config-load errors so a malformed deploy.yml still yields a pool", () => {
                // missing-service.yml throws DeployConfigError from Validator.
                // The factory must not propagate — the actual deploy verb
                // reloads and reports with proper formatting.
                var pool = new cli.lucli.services.deploy.lib.SshPoolFactory()
                    .fromConfigPath(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/invalid/missing-service.yml"));
                try {
                    var d = pool.$defaults();
                    expect(d.user).toBe("root");
                    expect(d.port).toBe(22);
                } finally {
                    pool.close();
                }
            });

        });

        describe("SshPoolFactory.$defaultsFromConfig", () => {

            it("omits privateKey when the keys array is empty", () => {
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
                var d = new cli.lucli.services.deploy.lib.SshPoolFactory().$defaultsFromConfig(cfg);
                expect(structKeyExists(d, "privateKey")).toBeFalse();
                expect(d.user).toBe("root");
                expect(d.port).toBe(22);
            });

            it("omits privateKey when the first key entry is whitespace-only", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                try {
                    fileWrite(tmp,
                        "service: demo" & chr(10) &
                        "image: acme/demo" & chr(10) &
                        "servers: [1.2.3.4]" & chr(10) &
                        "ssh:" & chr(10) &
                        "  keys:" & chr(10) &
                        "    - '   '" & chr(10) &
                        "registry: {username: u, password: [REGISTRY_PASSWORD]}" & chr(10)
                    );
                    var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(tmp);
                    var d = new cli.lucli.services.deploy.lib.SshPoolFactory().$defaultsFromConfig(cfg);
                    expect(structKeyExists(d, "privateKey")).toBeFalse();
                } finally {
                    if (fileExists(tmp)) fileDelete(tmp);
                }
            });

        });
    }
}
