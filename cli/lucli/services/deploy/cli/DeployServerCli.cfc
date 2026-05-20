/**
 * Server subcommand: wheels deploy server <verb>
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/server.rb
 *
 * exec      run a command on every server (or filter via --host)
 * bootstrap install Docker on a fresh host (idempotent)
 */
component {

    public DeployServerCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function exec(required struct opts) {
        if (!len(arguments.opts.cmd ?: "")) {
            throw(type="DeployServerCli.MissingCommand",
                  message="server exec requires a command (opts.cmd)");
        }
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var hosts = $filteredHosts(cfg, arguments.opts.host ?: "");
        $dispatch(hosts, arguments.opts.cmd, dryRun);
        return $renderResult(
            arguments.opts,
            "Ran '" & arguments.opts.cmd & "' on " & arrayLen(hosts) & " host(s): "
                & arrayToList(hosts, ", ")
        );
    }

    public string function bootstrap(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var hosts = $allHosts(cfg);
        var cmd = "which docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh";
        $dispatch(hosts, cmd, dryRun);
        return $renderResult(
            arguments.opts,
            "Bootstrapped Docker on " & arrayLen(hosts) & " host(s): " & arrayToList(hosts, ", ")
        );
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private any function $loadCfg(required struct opts) {
        return variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) for (var h in role.hosts()) arrayAppend(out, h);
        return out;
    }

    private array function $filteredHosts(required any cfg, required string filter) {
        var all = $allHosts(arguments.cfg);
        if (!len(arguments.filter)) return all;
        var filtered = [];
        for (var h in all) if (h == arguments.filter) arrayAppend(filtered, h);
        if (!arrayLen(filtered)) {
            throw(type="DeployServerCli.UnknownHost",
                  message="Host '" & arguments.filter & "' is not in deploy.yml servers");
        }
        return filtered;
    }

    private void function $dispatch(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return;
        }
        // #2696: server-level `exec` and `bootstrap` are strict — a nonzero
        // exit on either is a real failure that CI should see.
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c, {raise: doRaise}); });
    }
}
