/**
 * Accessory subcommand surface: wheels deploy accessory <verb> <name>
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/accessory.rb
 *
 * Accessories are single sidecar containers pinned to a host (or set of
 * hosts). Each verb takes a name positional argument to target a specific
 * accessory, or the literal "all" to fan out over every accessory in the
 * config.
 *
 * Accepts an SshPool (real or Fake) in init() for testability. Config is
 * loaded per invocation. Methods honor opts.dryRun — when true, commands
 * are buffered (read via dryRunOutput()) and no network calls happen.
 */
component {

    public DeployAccessoryCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function boot(required struct opts)     { return $forEach(arguments.opts, "run",     "Booted accessory"); }
    public string function reboot(required struct opts)   { return $forEach(arguments.opts, "reboot",  "Rebooted accessory"); }
    public string function start(required struct opts)    { return $forEach(arguments.opts, "start",   "Started accessory"); }
    public string function stop(required struct opts)     { return $forEach(arguments.opts, "stop",    "Stopped accessory"); }
    public string function restart(required struct opts)  { return $forEach(arguments.opts, "restart", "Restarted accessory"); }
    public string function details(required struct opts)  { return $forEach(arguments.opts, "details", "Collected accessory details"); }
    public string function remove(required struct opts)   { return $forEach(arguments.opts, "remove",  "Removed accessory"); }

    public string function logs(required struct opts) {
        var logOpts = {
            tail: arguments.opts.tail ?: 100,
            follow: arguments.opts.follow ?: false
        };
        return $forEach(arguments.opts, "logs", "Tailed accessory logs", logOpts);
    }

    // ── Private plumbing ───────────────────────────────────────

    private string function $forEach(required struct opts, required string method, required string verbLabel, struct methodOpts = {}) {
        arrayClear(variables.dryRunBuffer);
        if (!len(arguments.opts.name ?: "")) {
            throw(
                type = "DeployAccessoryCli.MissingName",
                message = "accessory verb requires 'name' (or 'all' to fan out)"
            );
        }
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var accCmds = new modules.wheels.services.deploy.commands.AccessoryCommands(cfg);
        var dryRun = arguments.opts.dryRun ?: false;
        var targets = (arguments.opts.name == "all")
            ? cfg.accessories()
            : [cfg.accessory(arguments.opts.name)];
        var names = [];

        for (var acc in targets) {
            var cmd = structIsEmpty(arguments.methodOpts)
                ? invoke(accCmds, arguments.method, [acc])
                : invoke(accCmds, arguments.method, [acc, arguments.methodOpts]);
            $dispatch(acc.hosts(), cmd, dryRun);
            arrayAppend(names, acc.name());
        }

        return $renderResult(
            arguments.opts,
            arguments.verbLabel & " " & arrayToList(names, ", ")
        );
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private void function $dispatch(required array hosts, required string cmd, required boolean dryRun) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return;
        }
        var c = arguments.cmd;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c); });
    }
}
