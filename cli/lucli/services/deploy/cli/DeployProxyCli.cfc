/**
 * Proxy subcommand surface: wheels deploy proxy <verb>
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/proxy.rb
 *
 * The kamal-proxy container is a singleton per host. Every verb iterates
 * ALL hosts in the config (across all roles) and dispatches the same
 * command to each.
 *
 * Accepts an SshPool (real or Fake) in init() for testability. Config is
 * loaded per invocation. Methods honor opts.dryRun — when true, commands
 * are buffered (read via dryRunOutput()) and no network calls happen.
 */
component {

    public DeployProxyCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public void function boot(required struct opts)    { $runOnAllHosts(arguments.opts, "boot"); }
    public void function reboot(required struct opts)  { $runOnAllHosts(arguments.opts, "reboot"); }
    public void function start(required struct opts)   { $runOnAllHosts(arguments.opts, "start"); }
    public void function stop(required struct opts)    { $runOnAllHosts(arguments.opts, "stop"); }
    public void function restart(required struct opts) { $runOnAllHosts(arguments.opts, "restart"); }
    public void function details(required struct opts) { $runOnAllHosts(arguments.opts, "details"); }
    public void function remove(required struct opts)  { $runOnAllHosts(arguments.opts, "remove"); }

    public void function logs(required struct opts) {
        var tail = arguments.opts.tail ?: 100;
        $runOnAllHostsWithArg(arguments.opts, "logs", {tail: tail});
    }

    // ── Private plumbing ───────────────────────────────────────

    private void function $runOnAllHosts(required struct opts, required string method) {
        $runOnAllHostsWithArg(arguments.opts, arguments.method, {});
    }

    private void function $runOnAllHostsWithArg(required struct opts, required string method, required struct methodOpts) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var proxyCmds = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
        var hosts = $allHosts(cfg);
        var cmdStr = structIsEmpty(arguments.methodOpts)
            ? invoke(proxyCmds, arguments.method)
            : invoke(proxyCmds, arguments.method, [arguments.methodOpts]);
        $dispatch(hosts, cmdStr, dryRun);
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) {
            for (var h in role.hosts()) arrayAppend(out, h);
        }
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
