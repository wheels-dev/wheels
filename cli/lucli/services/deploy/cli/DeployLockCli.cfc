/**
 * Lock subcommand (user-facing): wheels deploy lock <verb>
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/lock.rb
 *
 * Exposes LockCommands as ad-hoc verbs for operators. Distinct from the
 * internal lock acquire/release that wraps the main `wheels deploy` flow —
 * those are automatic; these are manual escape hatches.
 */
component {

    public DeployLockCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function acquire(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        var cmd = lock.acquire({
            user: $currentUser(),
            message: arguments.opts.message ?: "manual acquire"
        });
        $dispatchAny($allHosts(cfg), cmd, dryRun);
        return $renderResult(arguments.opts, "Acquired deploy lock for " & cfg.service());
    }

    public string function release(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        // rm -f is idempotent; surfacing a failure here only obscures the
        // operator's intent ("clear the lock if it's there"). #2696.
        $dispatchAny($allHosts(cfg), lock.release(), dryRun, true);
        return $renderResult(arguments.opts, "Released deploy lock for " & cfg.service());
    }

    public string function status(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        // readlink exits nonzero when the lock file is missing — which is
        // exactly what the operator wants to learn from `status`. Treat that
        // as advisory output, not a thrown error. #2696.
        $dispatchAny($allHosts(cfg), lock.status(), dryRun, true);
        return $renderResult(arguments.opts, "Checked deploy lock status for " & cfg.service());
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

    private void function $dispatchAny(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            if (arrayLen(arguments.hosts)) {
                arrayAppend(variables.dryRunBuffer, "[" & arguments.hosts[1] & "] " & arguments.cmd);
            }
            return;
        }
        // Lock ops target just one host (the lock file lives on one path; any host works).
        // #2696: acquire stays strict (contention should surface); release/status tolerate.
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        variables.sshPool.onAny(arguments.hosts, function(ssh, host) { ssh.run(c, {raise: doRaise}); });
    }

    private string function $currentUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
