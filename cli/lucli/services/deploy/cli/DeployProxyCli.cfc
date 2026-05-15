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
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function boot(required struct opts)    { return $runOnAllHosts(arguments.opts, "boot",    "Booted kamal-proxy"); }
    public string function reboot(required struct opts)  { return $runOnAllHosts(arguments.opts, "reboot",  "Rebooted kamal-proxy"); }
    public string function start(required struct opts)   { return $runOnAllHosts(arguments.opts, "start",   "Started kamal-proxy"); }
    public string function stop(required struct opts)    { return $runOnAllHosts(arguments.opts, "stop",    "Stopped kamal-proxy"); }
    public string function restart(required struct opts) { return $runOnAllHosts(arguments.opts, "restart", "Restarted kamal-proxy"); }
    public string function details(required struct opts) { return $runOnAllHosts(arguments.opts, "details", "Collected kamal-proxy details"); }
    public string function remove(required struct opts)  { return $runOnAllHosts(arguments.opts, "remove",  "Removed kamal-proxy"); }

    public string function logs(required struct opts) {
        var tail = arguments.opts.tail ?: 100;
        var n = $runOnAllHostsWithArg(arguments.opts, "logs", {tail: tail});
        return $renderResult(arguments.opts, "Tailed kamal-proxy logs on " & n & " host(s)");
    }

    // ── Private plumbing ───────────────────────────────────────

    private string function $runOnAllHosts(required struct opts, required string method, required string verbLabel) {
        var n = $runOnAllHostsWithArg(arguments.opts, arguments.method, {});
        return $renderResult(arguments.opts, arguments.verbLabel & " on " & n & " host(s)");
    }

    private numeric function $runOnAllHostsWithArg(required struct opts, required string method, required struct methodOpts) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var proxyCmds = new modules.wheels.services.deploy.commands.ProxyCommands(cfg);
        var hosts = $allHosts(cfg);
        var cmdStr = structIsEmpty(arguments.methodOpts)
            ? invoke(proxyCmds, arguments.method)
            : invoke(proxyCmds, arguments.method, [arguments.methodOpts]);
        // `remove` and `stop` are idempotent teardown verbs — a missing
        // kamal-proxy container should not be a hard error. Everything else
        // (boot, start, restart, details, logs, reboot) is strict by default.
        var idempotentTeardown = (arguments.method == "remove" || arguments.method == "stop");
        $dispatch(hosts, cmdStr, dryRun, idempotentTeardown);
        return arrayLen(hosts);
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) {
            for (var h in role.hosts()) arrayAppend(out, h);
        }
        return out;
    }

    private void function $dispatch(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return;
        }
        // #2696: raise defaults to true; only the explicit idempotent teardowns
        // (remove, stop) tolerate a nonzero exit.
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c, {raise: doRaise}); });
    }
}
