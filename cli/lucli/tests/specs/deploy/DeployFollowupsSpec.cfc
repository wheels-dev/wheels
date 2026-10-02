/**
 * #3914: `wheels deploy` follow-ups after #3874 — the generated Dockerfile,
 * registry login without a username, missing/empty config errors, proxy
 * sub-key validation, version-less app verbs, and a complete `deploy config`.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {

        describe("deploy init Dockerfile", () => {

            it("doesn't hard-code a datasource name, ships db/, and links the current guides", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-followups-" & createUUID();
                directoryCreate(tmpCwd, true, true);
                new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});
                var df = fileRead(tmpCwd & "/Dockerfile");
                directoryDelete(tmpCwd, true);
                expect(df).notToInclude("WHEELS_DATASOURCE=app");
                expect(df).toInclude("COPY --from=builder /build/db");
                expect(df).notToInclude("snapshot/");
                expect(df).toInclude("https://guides.wheels.dev/");
            });
        });

        describe("deploy init keeps local SQLite data out of the image", () => {

            it("ignores db/ SQLite files and removes any that reach the build", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-followups-" & createUUID();
                directoryCreate(tmpCwd, true, true);
                new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});
                var di = fileRead(tmpCwd & "/.dockerignore");
                var df = fileRead(tmpCwd & "/Dockerfile");
                directoryDelete(tmpCwd, true);
                for (var pattern in ["db/*.sqlite", "db/*.sqlite3", "db/*.db", "db/*-wal"]) {
                    expect(di).toInclude(pattern);
                }
                expect(df).toInclude("rm -f db/*.sqlite db/*.sqlite3 db/*.db");
                // The rm runs in the builder, before the runtime stage copies db/.
                expect(find("rm -f db/*.sqlite", df)).toBeLT(find("COPY --from=builder /build/db", df));
            });
        });

        describe("deploy init on a SQLite app", () => {

            it("says the production database starts empty and how to migrate it", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-followups-" & createUUID();
                directoryCreate(tmpCwd & "/config", true, true);
                fileWrite(tmpCwd & "/config/app.cfm", "this.datasources[""app""] = {class: ""org.sqlite.JDBC""};");
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});
                directoryDelete(tmpCwd, true);
                expect(out).toInclude("uses SQLite");
                expect(out).toInclude("autoMigrateDatabase=true");
            });

            it("says nothing about SQLite for another database", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-followups-" & createUUID();
                directoryCreate(tmpCwd & "/config", true, true);
                fileWrite(tmpCwd & "/config/app.cfm", "this.name = ""x"";");
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});
                directoryDelete(tmpCwd, true);
                expect(out).notToInclude("uses SQLite");
            });
        });

        describe("deploy registry login", () => {

            it("refuses without registry.username instead of running docker login -u ''", () => {
                var cfg = $writeConfig("service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#registry: {password: [REGISTRY_PASSWORD]}");
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var state = {type: "", message: ""};
                try {
                    new cli.lucli.services.deploy.cli.DeployRegistryCli(fake).login({configPath: cfg, password: "pw"});
                } catch (any e) {
                    state.type = e.type;
                    state.message = e.message;
                }
                expect(state.type).toBe("DeployRegistryCli.MissingUsername");
                expect(state.message).toInclude("registry.username");
                expect(arrayLen(fake.calls())).toBe(0);
            });
        });

        describe("deploy config loading", () => {

            it("explains a missing config/deploy.yml", () => {
                var state = {type: "", message: ""};
                try {
                    new cli.lucli.services.deploy.config.ConfigLoader().load(getTempDirectory() & "/no-such-" & createUUID() & "/config/deploy.yml");
                } catch (any e) {
                    state.type = e.type;
                    state.message = e.message;
                }
                expect(state.type).toBe("DeployConfigError");
                expect(state.message).toInclude("wheels deploy init");
            });

            it("explains an empty config/deploy.yml", () => {
                var cfg = $writeConfig("## nothing here yet#chr(10)#");
                var state = {type: "", message: ""};
                try {
                    new cli.lucli.services.deploy.config.ConfigLoader().load(cfg);
                } catch (any e) {
                    state.type = e.type;
                    state.message = e.message;
                }
                expect(state.type).toBe("DeployConfigError");
                expect(state.message).toInclude("empty");
            });
        });

        describe("deploy proxy validation", () => {

            it("rejects an unknown proxy sub-key", () => {
                var message = $validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], proxy: {hots: "app.example.com"}});
                expect(message).toInclude("proxy.hots");
            });

            it("rejects a non-boolean proxy.ssl", () => {
                var message = $validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], proxy: {host: "app.example.com", ssl: "yes-please"}});
                expect(message).toInclude("proxy.ssl");
            });

            it("accepts every documented proxy sub-key", () => {
                var message = $validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], proxy: {
                    host: "app.example.com", ssl: true, app_port: 8888,
                    healthcheck: {path: "/up", timeout: 30}, forward_headers: true, buffering: {requests: true}
                }});
                expect(message).toBe("");
            });
        });

        describe("deploy app verbs without --release", () => {

            it("live, maintenance and details run without a version", () => {
                var fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var app = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                app.live({configPath: fixture});
                app.maintenance({configPath: fixture});
                app.details({configPath: fixture});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "rm -f /tmp/kamal-maintenance-demo")).toBeTrue();
                expect($anyInclude(cmds, "touch /tmp/kamal-maintenance-demo")).toBeTrue();
                expect($anyInclude(cmds, "label=service=demo")).toBeTrue();
            });

            it("asks for --release (not --version) where a version is needed", () => {
                var fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
                var state = {message: ""};
                try {
                    new cli.lucli.services.deploy.cli.DeployAppCli(new cli.lucli.services.deploy.lib.FakeSshPool()).boot({configPath: fixture});
                } catch (DeployAppCli.MissingVersion e) {
                    state.message = e.message;
                }
                expect(state.message).toInclude("--release=");
                expect(state.message).notToInclude("older wrappers");
            });
        });

        describe("deploy config output", () => {

            it("prints proxy, env (secret names only), accessories, ssh and builder", () => {
                var cfg = $writeConfig(
                    "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                    & "registry: {username: u, password: [REGISTRY_PASSWORD]}#chr(10)#"
                    & "proxy: {host: app.example.com, ssl: true, app_port: 8888}#chr(10)#"
                    & "env: {clear: {DB_HOST: db.internal}, secret: [APP_SECRET]}#chr(10)#"
                    & "ssh: {user: deploy}#chr(10)#"
                    & "builder: {arch: amd64}#chr(10)#"
                    & "accessories: {db: {image: 'postgres:16', host: 1.2.3.5, port: 5432}}",
                    "REGISTRY_PASSWORD=pw#chr(10)#APP_SECRET=s"
                );
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool()).config({configPath: cfg});
                expect(out).toInclude("app.example.com");
                expect(out).toInclude("8888");
                expect(out).toInclude("DB_HOST");
                expect(out).toInclude("APP_SECRET");
                expect(out).toInclude("postgres:16");
                expect(out).toInclude("deploy");
                expect(out).toInclude("amd64");
                expect(out).toInclude("REGISTRY_PASSWORD");
            });

            it("never prints a registry.password entry that isn't a key in .kamal/secrets", () => {
                // A punctuated password, a GitHub PAT and an alphanumeric password: the
                // last two look exactly like secret names, so only membership tells them apart.
                for (var literal in ["hunter2!pass", "ghp_A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7r8", "Hunter2Password"]) {
                    var cfg = $writeConfig(
                        "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                        & "registry: {username: u, password: ['#literal#']}",
                        "REGISTRY_PASSWORD=real-pw"
                    );
                    var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool()).config({configPath: cfg});
                    expect(out).notToInclude(literal);
                    expect(out).toInclude("literal value hidden");
                }
            });

            it("shows a registry.password entry that names a key in .kamal/secrets", () => {
                var cfg = $writeConfig(
                    "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                    & "registry: {username: u, password: [REGISTRY_PASSWORD]}",
                    "REGISTRY_PASSWORD=real-pw-value"
                );
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool()).config({configPath: cfg});
                expect(out).toInclude("REGISTRY_PASSWORD");
                expect(out).notToInclude("literal value hidden");
                expect(out).notToInclude("real-pw-value");
            });
        });
    }

    private string function $writeConfig(required string yaml, string secrets = "") {
        var root = getTempDirectory() & "/wheels-deploy-followups-" & createUUID();
        directoryCreate(root & "/config", true, true);
        fileWrite(root & "/config/deploy.yml", arguments.yaml);
        if (len(arguments.secrets)) {
            directoryCreate(root & "/.kamal", true, true);
            fileWrite(root & "/.kamal/secrets", arguments.secrets);
        }
        return root & "/config/deploy.yml";
    }

    /** The DeployConfigError message, or "" when the config validates. */
    private string function $validationError(required struct parsed) {
        var state = {message: ""};
        try {
            new cli.lucli.services.deploy.config.Validator().validate(arguments.parsed, "test.yml");
        } catch (DeployConfigError e) {
            state.message = e.message;
        }
        return state.message;
    }

    private array function $cmdsFrom(required any fake) {
        var out = [];
        for (var c in arguments.fake.calls()) arrayAppend(out, c.cmd ?: "");
        return out;
    }

    private boolean function $anyInclude(required array arr, required string needle) {
        for (var s in arguments.arr) if (findNoCase(arguments.needle, s)) return true;
        return false;
    }
}
