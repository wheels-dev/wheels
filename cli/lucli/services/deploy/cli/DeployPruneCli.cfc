/**
 * Prune subcommand: wheels deploy prune <verb>
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/prune.rb
 */
component {

    public DeployPruneCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function all(required struct opts)        { return $runOnAllHosts(arguments.opts, "all",        "Pruned all (images + containers)"); }
    public string function images(required struct opts)     { return $runOnAllHosts(arguments.opts, "images",     "Pruned images"); }
    public string function containers(required struct opts) { return $runOnAllHosts(arguments.opts, "containers", "Pruned containers"); }

    private string function $runOnAllHosts(required struct opts, required string method, required string verbLabel) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var pruneCmds = new cli.lucli.services.deploy.commands.PruneCommands(cfg);

        var cmdStr = "";
        var keep = arguments.opts.keep ?: 5;
        if (arguments.method == "all" || arguments.method == "containers") {
            cmdStr = invoke(pruneCmds, arguments.method, [keep]);
        } else {
            cmdStr = invoke(pruneCmds, arguments.method);
        }

        var hosts = $allHosts(cfg);
        $dispatch(hosts, cmdStr, dryRun);
        return $renderResult(
            arguments.opts,
            arguments.verbLabel & " on " & arrayLen(hosts) & " host(s) (keep=" & keep & ")"
        );
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) for (var h in role.hosts()) arrayAppend(out, h);
        return out;
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
