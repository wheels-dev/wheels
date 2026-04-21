/**
 * Top-level deploy verbs.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/main.rb
 *
 * Accepts an SshPool (real or Fake) in init() for testability. Config is
 * loaded per invocation and passed into each *Commands.cfc. All methods
 * honor opts.dryRun — when true, commands print to writeOutput with a
 * [host] prefix and no network calls happen.
 */
component {

    public DeployMainCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    /**
     * Accumulated dry-run output from the most recent deploy/rollback/etc.
     * Callers that want to show dry-run commands to the user read this
     * after the verb returns. Emitting to a buffer (rather than writeOutput)
     * keeps the test runner's JSON response stream clean.
     */
    public array function dryRunOutput() {
        return variables.dryRunBuffer;
    }

    public string function version() {
        return "wheels-deploy mirrors kamal 2.4.0 / kamal-proxy v0.8.6";
    }

    public string function config(required struct opts) {
        var cfg = variables.loader.load(arguments.opts.configPath);
        var yaml = new cli.lucli.services.deploy.lib.Yaml();
        var rolesMap = $roleHosts(cfg);
        return yaml.dump({
            service: cfg.service(),
            image: cfg.image(),
            servers: rolesMap,
            registry: {
                server: cfg.registry().server(),
                username: cfg.registry().username()
            }
        });
    }

    public void function deploy(required struct opts) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var ver = arguments.opts.version ?: $gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;

        var app = new cli.lucli.services.deploy.commands.AppCommands(cfg);
        var proxy = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
        var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);

        var hosts = $allHosts(cfg);

        $dispatch(hosts, builder.pull(ver), dryRun);
        $dispatch(hosts, proxy.details() & " || " & proxy.boot(), dryRun);

        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                $dispatch([host], app.run(role, ver), dryRun);
                $dispatch(
                    [host],
                    proxy.deploy(role, app.container_name(role, ver) & ":3000"),
                    dryRun
                );
            }
        }
    }

    public void function redeploy(required struct opts) {
        deploy(arguments.opts);
    }

    public void function rollback(required struct opts) {
        arrayClear(variables.dryRunBuffer);
        if (!len(arguments.opts.version ?: "")) {
            throw(
                type = "DeployMainCli.MissingVersion",
                message = "rollback requires a version (pass opts.version)"
            );
        }
        var cfg = variables.loader.load(arguments.opts.configPath);
        var app = new cli.lucli.services.deploy.commands.AppCommands(cfg);
        var proxy = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
        var dryRun = arguments.opts.dryRun ?: false;
        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                $dispatch([host], app.start(role, arguments.opts.version), dryRun);
                $dispatch(
                    [host],
                    proxy.deploy(role, app.container_name(role, arguments.opts.version) & ":3000"),
                    dryRun
                );
            }
        }
    }

    public void function setup(required struct opts) {
        // Phase 2 will add accessory boot; for Phase 1 this equals deploy.
        deploy(arguments.opts);
    }

    public string function init_stub(required struct opts) {
        return "created config/deploy.yml (stub)";
    }

    // ── Private helpers ────────────────────────────────────────────

    private void function $dispatch(
        required array hosts,
        required string cmd,
        required boolean dryRun
    ) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            }
            return;
        }
        // Capture cmd into a local so the closure sees a stable reference
        // (Adobe CF argument-scope closures can be flaky otherwise).
        var c = arguments.cmd;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) {
            ssh.run(c);
        });
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) {
            for (var h in role.hosts()) arrayAppend(out, h);
        }
        return out;
    }

    private struct function $roleHosts(required any cfg) {
        var out = {};
        for (var role in arguments.cfg.roles()) {
            out[role.name()] = role.hosts();
        }
        return out;
    }

    private string function $gitShortSha() {
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder")
                .init(["git", "rev-parse", "--short", "HEAD"]);
            pb.redirectErrorStream(true);
            var proc = pb.start();
            proc.waitFor();
            var reader = createObject("java", "java.io.BufferedReader").init(
                createObject("java", "java.io.InputStreamReader").init(
                    proc.getInputStream(), "UTF-8"
                )
            );
            var sb = createObject("java", "java.lang.StringBuilder").init();
            var line = reader.readLine();
            while (!isNull(line)) {
                sb.append(line);
                line = reader.readLine();
            }
            return trim(sb.toString());
        } catch (any e) {
            return "unknown";
        }
    }

}
