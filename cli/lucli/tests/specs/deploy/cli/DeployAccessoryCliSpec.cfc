component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-accessories.yml");
    }

    function run() {
        describe("DeployAccessoryCli", () => {

            it("boot dispatches docker run on the accessory host", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.boot({configPath: variables.fixture, name: "db"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker run")).toBeTrue();
                expect($anyInclude(cmds, "--name demo-db")).toBeTrue();
                // Host should be the accessory's pinned host, not the app host.
                var hosts = $hostsFrom(fake);
                expect(arrayContains(hosts, "1.2.3.5")).toBeTrue();
            });

            it("reboot chains stop/rm/run", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.reboot({configPath: variables.fixture, name: "db"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker rm demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker run")).toBeTrue();
            });

            it("start dispatches docker start", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.start({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker start demo-db")).toBeTrue();
            });

            it("stop dispatches docker stop", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.stop({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker stop demo-db")).toBeTrue();
            });

            it("restart dispatches docker restart", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.restart({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker restart demo-db")).toBeTrue();
            });

            it("details inspects container", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.details({configPath: variables.fixture, name: "db"});
                expect($anyInclude($cmdsFrom(fake), "docker inspect")).toBeTrue();
            });

            it("logs honors tail", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.logs({configPath: variables.fixture, name: "db", tail: 25});
                expect($anyInclude($cmdsFrom(fake), "--tail 25")).toBeTrue();
            });

            it("remove chains stop + rm", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.remove({configPath: variables.fixture, name: "db"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker rm demo-db")).toBeTrue();
            });

            it("name=all fans out over every accessory", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.stop({configPath: variables.fixture, name: "all"});
                var cmds = $cmdsFrom(fake);
                expect($anyInclude(cmds, "docker stop demo-db")).toBeTrue();
                expect($anyInclude(cmds, "docker stop demo-redis")).toBeTrue();
            });

            it("missing name throws DeployAccessoryCli.MissingName", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                var thrown = false;
                try {
                    cli.stop({configPath: variables.fixture});
                } catch ("DeployAccessoryCli.MissingName" e) {
                    thrown = true;
                }
                expect(thrown).toBeTrue();
            });

            it("dry-run buffers output instead of dispatching", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                cli.stop({configPath: variables.fixture, name: "db", dryRun: true});
                expect(arrayLen(fake.calls())).toBe(0);
                var out = arrayToList(cli.dryRunOutput(), chr(10));
                expect(out).toInclude("docker stop demo-db");
            });

            // env.secret delivery (#2957, Wave 2b) — accessory boot writes the
            // env file (600 perms) before docker run; values stay out of argv.
            it("boot writes the accessory env file before docker run and keeps secret values out of argv (##2957)", () => {
                var proj = $makeSecretProject();
                try {
                    var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                    var cli = new cli.lucli.services.deploy.cli.DeployAccessoryCli(fake);
                    cli.boot({configPath: proj.config, name: "db"});

                    var calls = fake.calls();
                    var ensureIdx = 0; var uploadIdx = 0; var runIdx = 0;
                    for (var i = 1; i <= arrayLen(calls); i++) {
                        var cmd = calls[i].cmd ?: "";
                        if (!ensureIdx && findNoCase("chmod 600", cmd)
                            && find(".kamal/apps/demo/env/accessories/db.env", cmd)) ensureIdx = i;
                        if (!uploadIdx && (calls[i].kind ?: "") == "uploadString") uploadIdx = i;
                        if (!runIdx && findNoCase("docker run", cmd)) runIdx = i;
                    }
                    expect(ensureIdx).toBeGT(0);
                    expect(uploadIdx).toBeGT(ensureIdx);
                    expect(runIdx).toBeGT(uploadIdx);

                    expect(calls[uploadIdx].remote).toBe(".kamal/apps/demo/env/accessories/db.env");
                    expect(calls[uploadIdx].content).toInclude("POSTGRES_PASSWORD=pgpw-secret-9");
                    expect(calls[uploadIdx].host).toBe("1.2.3.5");
                    expect(calls[runIdx].cmd).toInclude("--env-file .kamal/apps/demo/env/accessories/db.env");
                    for (var c in calls) {
                        expect(c.cmd ?: "").notToInclude("pgpw-secret-9");
                    }
                } finally {
                    directoryDelete(proj.root, true);
                }
            });
        });
    }

    /**
     * Temp project: config/deploy.yml with a postgres accessory declaring
     * env.secret [POSTGRES_PASSWORD], resolved by .kamal/secrets.
     */
    private struct function $makeSecretProject() {
        var root = getTempDirectory() & "/wheels-2957-acc-" & createUUID();
        directoryCreate(root & "/config", true, true);
        directoryCreate(root & "/.kamal", true, true);
        fileWrite(
            root & "/config/deploy.yml",
            "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                & "registry: {username: u, password: [REGISTRY_PASSWORD]}#chr(10)#"
                & "accessories: {db: {image: 'postgres:16', host: 1.2.3.5, "
                & "env: {clear: {POSTGRES_USER: demo}, secret: [POSTGRES_PASSWORD]}}}"
        );
        fileWrite(
            root & "/.kamal/secrets",
            "POSTGRES_PASSWORD=pgpw-secret-9#chr(10)#REGISTRY_PASSWORD=regpw"
        );
        return {root: root, config: root & "/config/deploy.yml"};
    }

    private array function $cmdsFrom(required any fake) {
        var out = [];
        for (var c in arguments.fake.calls()) arrayAppend(out, c.cmd ?: "");
        return out;
    }

    private array function $hostsFrom(required any fake) {
        var out = [];
        for (var c in arguments.fake.calls()) arrayAppend(out, c.host ?: "");
        return out;
    }

    private boolean function $anyInclude(required array arr, required string needle) {
        for (var s in arguments.arr) if (findNoCase(arguments.needle, s)) return true;
        return false;
    }
}
