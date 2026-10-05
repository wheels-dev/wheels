/**
 * #4063: `migrate:` in deploy.yml runs the migrations once, on one host.
 *
 * The migrate host (default: the first host of the first role, or
 * migrate.host) boots and cuts over first, with WHEELS_MIGRATE_ON_BOOT=true
 * and a longer health-check timeout. Every other app container, and any
 * container `app boot` starts, gets WHEELS_MIGRATE_ON_BOOT=false. Without
 * the block nothing changes.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {

        describe("Migrate accessor", () => {

            it("is disabled without the block and with migrate: false", () => {
                expect(new cli.lucli.services.deploy.config.Migrate().enabled()).toBeFalse();
                expect(new cli.lucli.services.deploy.config.Migrate(false).enabled()).toBeFalse();
            });

            it("is enabled by migrate: true or a block, with defaults", () => {
                var plain = new cli.lucli.services.deploy.config.Migrate(true);
                expect(plain.enabled()).toBeTrue();
                expect(plain.host()).toBe("");
                expect(plain.timeout()).toBe(300);
                var block = new cli.lucli.services.deploy.config.Migrate({host: " 10.0.0.2 ", timeout: 120});
                expect(block.enabled()).toBeTrue();
                expect(block.host()).toBe("10.0.0.2");
                expect(block.timeout()).toBe(120);
            });
        });

        describe("validation", () => {

            it("accepts true, false and a block", () => {
                for (var yaml in ["migrate: true", "migrate: false", "migrate: {host: 10.0.0.2, timeout: 60}"]) {
                    expect($loadError(yaml)).toBe("", yaml);
                }
            });

            it("refuses unknown keys, a bad timeout and an empty host", () => {
                var unknownKey = $loadError("migrate: {hosts: 10.0.0.2}");
                expect(unknownKey).toInclude("migrate.hosts");
                expect(unknownKey).toInclude("allowed migrate keys: host, timeout");
                expect($loadError("migrate: {timeout: 0}")).toInclude("migrate.timeout must be a positive number");
                expect($loadError("migrate: {host: ''}")).toInclude("migrate.host must be a host name or address");
                expect($loadError("migrate: [10.0.0.2]")).toInclude("migrate must be true, false, or a block");
            });
        });

        describe("deploy without migrate:", () => {

            it("does not set WHEELS_MIGRATE_ON_BOOT anywhere", () => {
                expect($dryRunDeploy("")).notToInclude("WHEELS_MIGRATE_ON_BOOT");
            });
        });

        describe("deploy with migrate:", () => {

            it("migrates on the first host only, with the longer health-check timeout", () => {
                var out = $dryRunDeploy("migrate: true");
                var runs = $linesMatching(out, "docker run .*demo-web-v1");
                expect(arrayLen(runs)).toBe(3);
                expect($lineFor(runs, "10.0.0.1")).toInclude("WHEELS_MIGRATE_ON_BOOT=true");
                expect($lineFor(runs, "10.0.0.2")).toInclude("WHEELS_MIGRATE_ON_BOOT=false");
                expect($lineFor(runs, "10.0.0.3")).toInclude("WHEELS_MIGRATE_ON_BOOT=false");
                var cutovers = $linesMatching(out, "kamal-proxy deploy");
                expect($lineFor(cutovers, "10.0.0.1")).toInclude("--health-check-timeout 300s");
                expect($lineFor(cutovers, "10.0.0.2")).toInclude("--health-check-timeout 30s");
                expect(out).toInclude("migrated the database on 10.0.0.1 for version v1");
            });

            it("boots migrate.host first and gives it the configured timeout", () => {
                var out = $dryRunDeploy("migrate: {host: 10.0.0.3, timeout: 90}");
                var lines = listToArray(out, chr(10));
                expect($indexOf(lines, "^\[10\.0\.0\.3\] .*docker run .*demo-web-v1")).toBeLT($indexOf(lines, "^\[10\.0\.0\.1\] .*docker run .*demo-web-v1"));
                var runs = $linesMatching(out, "docker run .*demo-web-v1");
                expect($lineFor(runs, "10.0.0.3")).toInclude("WHEELS_MIGRATE_ON_BOOT=true");
                expect($lineFor(runs, "10.0.0.1")).toInclude("WHEELS_MIGRATE_ON_BOOT=false");
                expect($lineFor($linesMatching(out, "kamal-proxy deploy"), "10.0.0.3")).toInclude("--health-check-timeout 90s");
            });

            it("deploys the migrate host's role first and keeps worker containers off migrations", () => {
                var out = $dryRunDeploy(
                    "migrate: {host: 10.0.0.2}",
                    "servers: {job: {hosts: [10.0.0.9], cmd: 'run-jobs'}, web: [10.0.0.1, 10.0.0.2]}"
                );
                var lines = listToArray(out, chr(10));
                var migrateRun = $indexOf(lines, "^\[10\.0\.0\.2\] .*docker run .*demo-web-v1");
                expect(migrateRun).toBeLT($indexOf(lines, "^\[10\.0\.0\.9\] .*docker run .*demo-job-v1"));
                expect(migrateRun).toBeLT($indexOf(lines, "^\[10\.0\.0\.1\] .*docker run .*demo-web-v1"));
                expect(lines[migrateRun]).toInclude("WHEELS_MIGRATE_ON_BOOT=true");
                expect($lineFor($linesMatching(out, "docker run .*demo-job-v1"), "10.0.0.9")).toInclude("WHEELS_MIGRATE_ON_BOOT=false");
            });
        });

        describe("refusals", () => {

            it("refuses an app with no proxy-fronted role", () => {
                expect($deployError("migrate: true", "servers: {job: {hosts: [10.0.0.9], cmd: 'run-jobs'}}"))
                    .toInclude("migrate: needs a proxy-fronted role");
            });

            it("refuses a default host whose role is not proxy-fronted", () => {
                expect($deployError("migrate: true", "servers: {job: {hosts: [10.0.0.9], cmd: 'run-jobs'}, web: [10.0.0.1]}"))
                    .toInclude("defaults to the first host of the first role ('job')");
            });

            it("refuses a migrate.host that is not a host of any role", () => {
                expect($deployError("migrate: {host: 10.0.0.42}")).toInclude("migrate.host '10.0.0.42' is not a host of any role");
            });

            it("refuses a migrate.host in a job/worker role", () => {
                expect($deployError("migrate: {host: 10.0.0.9}", "servers: {job: {hosts: [10.0.0.9], cmd: 'run-jobs'}, web: [10.0.0.1]}"))
                    .toInclude("is in the 'job' role, which is not proxy-fronted");
            });
        });

        describe("app boot with migrate:", () => {

            it("never migrates at start", () => {
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var appCli = new cli.lucli.services.deploy.cli.DeployAppCli(fake);
                appCli.boot({configPath: $writeConfig("migrate: true"), version: "v1"});
                var runs = [];
                for (var call in fake.calls()) {
                    if (findNoCase("docker run", call.cmd) && findNoCase("demo-web-v1", call.cmd)) arrayAppend(runs, call.cmd);
                }
                expect(arrayLen(runs)).toBe(3);
                for (var cmd in runs) {
                    expect(cmd).toInclude("WHEELS_MIGRATE_ON_BOOT=false");
                }
            });
        });
    }

    private string function $writeConfig(required string migrateYaml, string serversYaml = "servers: [10.0.0.1, 10.0.0.2, 10.0.0.3]") {
        var root = getTempDirectory() & "/wheels-deploy-migrate-" & createUUID();
        directoryCreate(root & "/config", true, true);
        fileWrite(
            root & "/config/deploy.yml",
            "service: demo#chr(10)#image: acme/demo#chr(10)#"
                & arguments.serversYaml & chr(10)
                & "registry: {username: u, password: [REGISTRY_PASSWORD]}#chr(10)#"
                & arguments.migrateYaml & chr(10)
        );
        return root & "/config/deploy.yml";
    }

    private string function $dryRunDeploy(required string migrateYaml, string serversYaml = "servers: [10.0.0.1, 10.0.0.2, 10.0.0.3]") {
        var dc = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool());
        return dc.deploy({configPath: $writeConfig(arguments.migrateYaml, arguments.serversYaml), version: "v1", dryRun: true, skipPush: true});
    }

    /** The deploy error message, or "" when the dry run succeeds. */
    private string function $deployError(required string migrateYaml, string serversYaml = "servers: [10.0.0.1, 10.0.0.2, 10.0.0.3]") {
        var state = {message = ""};
        try {
            $dryRunDeploy(arguments.migrateYaml, arguments.serversYaml);
        } catch (any e) {
            state.message = e.message;
        }
        return state.message;
    }

    /** The config-load error message, or "" when deploy.yml loads. */
    private string function $loadError(required string migrateYaml) {
        var state = {message = ""};
        try {
            new cli.lucli.services.deploy.config.ConfigLoader().load($writeConfig(arguments.migrateYaml), {});
        } catch (any e) {
            state.message = e.message;
        }
        return state.message;
    }

    private array function $linesMatching(required string text, required string pattern) {
        var found = [];
        for (var line in listToArray(arguments.text, chr(10))) {
            if (reFind(arguments.pattern, line)) arrayAppend(found, line);
        }
        return found;
    }

    private string function $lineFor(required array lines, required string host) {
        for (var line in arguments.lines) {
            if (find("[" & arguments.host & "]", line) == 1) return line;
        }
        return "";
    }

    private numeric function $indexOf(required array lines, required string pattern) {
        for (var i = 1; i <= arrayLen(arguments.lines); i++) {
            if (reFind(arguments.pattern, arguments.lines[i])) return i;
        }
        return 0;
    }
}
