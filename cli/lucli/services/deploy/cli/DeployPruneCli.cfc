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

    public void function all(required struct opts)        { $runOnAllHosts(arguments.opts, "all"); }
    public void function images(required struct opts)     { $runOnAllHosts(arguments.opts, "images"); }
    public void function containers(required struct opts) { $runOnAllHosts(arguments.opts, "containers"); }

    private void function $runOnAllHosts(required struct opts, required string method) {
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
