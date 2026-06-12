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
        // The deploy flow holds the lock on EVERY host (##2957 DEP-1), so a
        // manual acquire must match — locking a single host would let a
        // concurrent deploy that probes another host proceed.
        $acquireLockAllOrNothing($uniqueHosts($allHosts(cfg)), cmd, lock, dryRun);
        return $renderResult(arguments.opts, "Acquired deploy lock for " & cfg.service());
    }

    public string function release(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        // rm -f is idempotent; surfacing a failure here only obscures the
        // operator's intent ("clear the lock if it's there"). #2696.
        // Fan out to every host — the lock lives fleet-wide (##2957 DEP-1),
        // so clearing one host would strand stale locks on the rest.
        $dispatch($uniqueHosts($allHosts(cfg)), lock.release(), dryRun, true);
        return $renderResult(arguments.opts, "Released deploy lock for " & cfg.service());
    }

    public string function status(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        // readlink exits nonzero when the lock file is missing — which is
        // exactly what the operator wants to learn from `status`. Treat that
        // as advisory output, not a thrown error. #2696. Checked on every
        // host since the lock lives fleet-wide (##2957 DEP-1).
        $dispatch($uniqueHosts($allHosts(cfg)), lock.status(), dryRun, true);
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

    /**
     * All-or-nothing lock acquisition across every host, in config order,
     * with rollback of already-acquired locks on the first failure.
     *
     * MIRROR: DeployMainCli.$acquireLockAllOrNothing is the deploy-flow
     * twin of this contract (##2957 DEP-1) — keep them in lockstep.
     */
    private void function $acquireLockAllOrNothing(
        required array hosts,
        required string acquireCmd,
        required any lock,
        required boolean dryRun
    ) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.acquireCmd);
            }
            return;
        }
        var c = arguments.acquireCmd;
        // Shared struct so the callback can record progress — closures can't
        // reliably mutate outer scalars across engines (anti-pattern ##10).
        var state = {acquired: [], lastHost: ""};
        try {
            variables.sshPool.sequential(arguments.hosts, function(ssh, host) {
                state.lastHost = host;
                ssh.run(c, {raise: true});
                arrayAppend(state.acquired, host);
            });
        } catch (any e) {
            $rollbackAcquiredLocks(state.acquired, arguments.lock);
            throw(
                type = "Wheels.Deploy.LockAcquireFailed",
                message = "Could not acquire the deploy lock on " & state.lastHost
                    & " — another deploy may hold it. Rolled back "
                    & arrayLen(state.acquired) & " already-acquired lock(s). "
                    & "Inspect with 'wheels deploy lock status'; clear a stale lock with "
                    & "'wheels deploy lock release'. Cause: " & e.message,
                detail = e.detail ?: ""
            );
        }
    }

    /**
     * Best-effort release of the locks a partially-failed acquire already
     * placed. A rollback failure must never shadow the LockAcquireFailed
     * the caller is about to throw.
     */
    private void function $rollbackAcquiredLocks(required array hosts, required any lock) {
        if (!arrayLen(arguments.hosts)) return;
        var releaseCmd = arguments.lock.release();
        try {
            variables.sshPool.onEach(arguments.hosts, function(ssh, host) {
                ssh.run(releaseCmd, {raise: false});
            });
        } catch (any e) {
            // Swallowed deliberately — the acquire error is the one the
            // operator needs to see.
        }
    }

    /** Order-preserving dedupe — a host serving several roles appears once. */
    private array function $uniqueHosts(required array hosts) {
        var seen = {};
        var out = [];
        for (var h in arguments.hosts) {
            if (!structKeyExists(seen, h)) {
                seen[h] = true;
                arrayAppend(out, h);
            }
        }
        return out;
    }

    private void function $dispatch(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            }
            return;
        }
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c, {raise: doRaise}); });
    }

    private string function $currentUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
