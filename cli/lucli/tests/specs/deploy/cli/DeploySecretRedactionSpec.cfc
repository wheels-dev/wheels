/**
 * Secret values interpolated into env.clear (e.g. a database URL built from
 * ${DB_PASSWORD}) must never be printed: not in dry-run output for deploy,
 * setup or app boot, and not in a remote-failure message. Loading such a
 * config also warns that env.clear values travel on the docker run command
 * line and recommends env.secret.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("Deploy secret redaction", () => {

            var $project = (secretValue) => {
                var root = getTempDirectory() & "wheels-redact-" & createUUID();
                directoryCreate(root & "/config", true, true);
                directoryCreate(root & "/.kamal", true, true);
                fileWrite(root & "/config/deploy.yml",
                    "service: demo" & chr(10)
                    & "image: acme/demo" & chr(10)
                    & "servers:" & chr(10) & "  - 1.2.3.4" & chr(10)
                    & "env:" & chr(10)
                    & "  clear:" & chr(10)
                    & "    DB_URL: postgres://app:${DB_PASSWORD}@db/app" & chr(10)
                    & "    LOG_LEVEL: info" & chr(10));
                // .kamal/secrets is read by bash, so the value is double-quoted as a real file would be.
                fileWrite(root & "/.kamal/secrets", "DB_PASSWORD=""" & secretValue & """" & chr(10));
                return root;
            };

            beforeEach(() => {
                new cli.lucli.services.deploy.lib.SecretRedaction().reset();
            });

            it("keeps an env.clear secret out of deploy --dry-run output", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});
                    var out = dc.deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
                    expect(out).notToInclude("p4ss-word-xyz");
                    expect(out).toInclude("postgres://app:[REDACTED]@db/app");
                    expect(out).toInclude("LOG_LEVEL=info");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("redacts a secret that contains a single quote (shell-escaped on the command line)", () => {
                var root = $project("it's-a-s3cret");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});
                    var out = dc.deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
                    expect(out).notToInclude("s3cret");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("keeps the secret out of setup --dry-run output", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});
                    var out = dc.setup({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
                    expect(out).notToInclude("p4ss-word-xyz");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("keeps the secret out of app boot --dry-run output", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    var app = new cli.lucli.services.deploy.cli.DeployAppCli(new cli.lucli.services.deploy.lib.FakeSshPool());
                    var out = app.boot({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
                    expect(out).notToInclude("p4ss-word-xyz");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("warns at config load when env.clear interpolates a value", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    var loader = new cli.lucli.services.deploy.config.ConfigLoader();
                    loader.load(root & "/config/deploy.yml");
                    var warnings = new cli.lucli.services.deploy.lib.SecretRedaction().warnings();
                    expect(arrayLen(warnings)).toBe(1);
                    expect(warnings[1]).toInclude("env.clear.DB_URL");
                    expect(warnings[1]).toInclude("env.secret");
                    expect(warnings[1]).notToInclude("p4ss-word-xyz");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("prints the env.clear warning in deploy --dry-run output", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});
                    var out = dc.deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
                    expect(out).toInclude("WARNING: env.clear.DB_URL interpolates ${DB_PASSWORD}");
                    expect(out).toInclude("env.secret");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("prints the env.clear warning once in a real deploy's output", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});
                    var out = dc.deploy({configPath: root & "/config/deploy.yml", version: "v1"});
                    expect(out).toInclude("WARNING: env.clear.DB_URL");
                    expect((len(out) - len(replace(out, "WARNING: env.clear.DB_URL", "", "all"))) / len("WARNING: env.clear.DB_URL")).toBe(1);
                    expect(out).notToInclude("p4ss-word-xyz");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("starts every deploy command with an empty secret and warning registry", () => {
                var redaction = new cli.lucli.services.deploy.lib.SecretRedaction();
                redaction.register("leftover-secret-1234");
                redaction.addWarning("left over from an earlier command");
                var helper = new cli.lucli.tests.TestHelper();
                var tempRoot = helper.scaffoldTempProject(expandPath("/"));
                try {
                    directoryCreate(tempRoot & "/vendor/wheels", true, true);
                    var mod = new cli.lucli.Module(cwd = tempRoot);
                    mod.__arguments = ["version", "--configPath=" & expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml")];
                    try {
                        mod.deploy();
                    } catch (any e) {
                        // Only the reset at the start of the command matters here.
                    }
                    expect(redaction.values()).toBe([]);
                    expect(redaction.warnings()).toBe([]);
                } finally {
                    helper.cleanupTempProject(tempRoot);
                }
            });

            it("redacts an accessory env.clear value taken from the process environment", () => {
                // HOME exists in the server's environment and has no .kamal/secrets key,
                // so its value can only come from System.getenv.
                var envValue = createObject("java", "java.lang.System").getenv("HOME");
                var root = getTempDirectory() & "wheels-redact-acc-" & createUUID();
                directoryCreate(root & "/config", true, true);
                directoryCreate(root & "/.kamal", true, true);
                fileWrite(root & "/config/deploy.yml",
                    "service: demo" & chr(10) & "image: acme/demo" & chr(10)
                    & "servers:" & chr(10) & "  - 1.2.3.4" & chr(10)
                    & "accessories:" & chr(10)
                    & "  db:" & chr(10)
                    & "    image: postgres:16" & chr(10)
                    & "    host: 1.2.3.5" & chr(10)
                    & "    env:" & chr(10)
                    & "      clear:" & chr(10)
                    & "        POSTGRES_PASSWORD: ${HOME}" & chr(10));
                fileWrite(root & "/.kamal/secrets", "UNRELATED=placeholder-value" & chr(10));
                try {
                    var acc = new cli.lucli.services.deploy.cli.DeployAccessoryCli(new cli.lucli.services.deploy.lib.FakeSshPool());
                    var out = acc.boot({configPath: root & "/config/deploy.yml", name: "db", dryRun: true});
                    expect(len(envValue)).toBeGTE(4);
                    expect(out).notToInclude(envValue);
                    expect(out).toInclude("WARNING: accessories.db.env.clear.POSTGRES_PASSWORD interpolates ${HOME}");
                    var pool = new cli.lucli.services.deploy.lib.FakeSshPool();
                    expect(pool.$redactSecrets("docker run -e 'POSTGRES_PASSWORD=" & envValue & "'")).notToInclude(envValue);
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("redacts secret-sourced values and prints the warning in deploy config output", () => {
                var root = getTempDirectory() & "wheels-redact-config-" & createUUID();
                directoryCreate(root & "/config", true, true);
                directoryCreate(root & "/.kamal", true, true);
                fileWrite(root & "/config/deploy.yml",
                    "service: demo" & chr(10) & "image: acme/demo" & chr(10)
                    & "servers:" & chr(10) & "  - 1.2.3.4" & chr(10)
                    & "registry:" & chr(10) & "  username: ${REG_USER}" & chr(10)
                    & "env:" & chr(10) & "  clear:" & chr(10)
                    & "    DB_URL: postgres://app:${DB_PASSWORD}@db/app" & chr(10));
                fileWrite(root & "/.kamal/secrets", "REG_USER=""deploy-bot-secret-9""" & chr(10) & "DB_PASSWORD=""p4ss-word-xyz""" & chr(10));
                try {
                    var dc = new cli.lucli.services.deploy.cli.DeployMainCli(
                        new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});
                    var out = dc.config({configPath: root & "/config/deploy.yml"});
                    expect(out).notToInclude("deploy-bot-secret-9");
                    expect(out).toInclude("[REDACTED]");
                    expect(out).toInclude("WARNING: env.clear.DB_URL interpolates ${DB_PASSWORD}");
                    expect(out).toInclude("service: demo");
                } finally {
                    directoryDelete(root, true);
                }
            });

            it("redacts the secret in a remote-failure message without explicit registration", () => {
                var root = $project("p4ss-word-xyz");
                try {
                    new cli.lucli.services.deploy.config.ConfigLoader().load(root & "/config/deploy.yml");
                    var pool = new cli.lucli.services.deploy.lib.FakeSshPool();
                    expect(pool.$redactSecrets("docker run -e 'DB_URL=postgres://app:p4ss-word-xyz@db/app'"))
                        .notToInclude("p4ss-word-xyz");
                } finally {
                    directoryDelete(root, true);
                }
            });
        });
    }
}
