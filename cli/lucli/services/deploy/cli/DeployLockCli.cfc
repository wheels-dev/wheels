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
        // #2957 DEP-6a: surface readlink's output (the lock holder on stdout,
        // or the "No such file" diagnostic on stderr) instead of dropping it.
        var lines = $dispatchAnyCollect($allHosts(cfg), lock.status(), dryRun, true);
        var summary = "Checked deploy lock status for " & cfg.service();
        if (arrayLen(lines)) summary &= chr(10) & arrayToList(lines, chr(10));
        return $renderResult(arguments.opts, summary);
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

    /**
     * Like $dispatchAny, but returns the remote output host-prefixed
     * (`[host] line`). Stdout wins; stderr is the fallback so tolerated
     * failures (allowFail) still surface their diagnostic. #2957 DEP-6a.
     */
    private array function $dispatchAnyCollect(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            if (arrayLen(arguments.hosts)) {
                arrayAppend(variables.dryRunBuffer, "[" & arguments.hosts[1] & "] " & arguments.cmd);
            }
            return [];
        }
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        // Closures can't write outer locals reliably — collect via a shared struct.
        var ctx = {lines: []};
        variables.sshPool.onAny(arguments.hosts, function(ssh, host) {
            var res = ssh.run(c, {raise: doRaise});
            var text = trim(res.stdout ?: "");
            if (!len(text)) text = trim(res.stderr ?: "");
            if (!len(text)) return;
            text = replace(text, chr(13), "", "all");
            for (var line in listToArray(text, chr(10))) {
                arrayAppend(ctx.lines, "[" & host & "] " & line);
            }
        });
        return ctx.lines;
    }

    private string function $currentUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
