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
        // so clearing one host would strand stale locks on the rest — but
        // per host, best-effort: fleet-wide stale locks most plausibly
        // exist BECAUSE a host died mid-deploy, so the recovery path must
        // keep working around an unreachable host instead of aborting on it.
        var failed = $dispatchPerHostTolerant($uniqueHosts($allHosts(cfg)), lock.release(), dryRun);
        return $renderResult(
            arguments.opts,
            "Released deploy lock for " & cfg.service()
                & $skippedHostsSuffix(failed, "the lock was NOT released there; re-run 'wheels deploy lock release' when the host is back")
        );
    }

    public string function status(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        // readlink exits nonzero when the lock file is missing — which is
        // exactly what the operator wants to learn from `status`. Treat that
        // as advisory output, not a thrown error. #2696. Checked on every
        // host since the lock lives fleet-wide (##2957 DEP-1) — and the same
        // advisory contract covers an unreachable host: report it, don't throw.
        // #2957 DEP-6a: also surface readlink's output (the lock holder on
        // stdout, or the "No such file" diagnostic on stderr) per host instead
        // of dropping it.
        var collected = $collectPerHostTolerant($uniqueHosts($allHosts(cfg)), lock.status(), dryRun);
        var summary = "Checked deploy lock status for " & cfg.service();
        if (arrayLen(collected.lines)) summary &= chr(10) & arrayToList(collected.lines, chr(10));
        summary &= $skippedHostsSuffix(collected.failed, "the lock state there is unknown");
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
     * the caller is about to throw. Host-granular: one unreachable host
     * must not stop the rollback from clearing the remaining healthy hosts.
     */
    private void function $rollbackAcquiredLocks(required array hosts, required any lock) {
        if (!arrayLen(arguments.hosts)) return;
        // $dispatchPerHostTolerant never throws — per-host failures are
        // swallowed deliberately; the acquire error is the one the operator
        // needs to see.
        $dispatchPerHostTolerant(arguments.hosts, arguments.lock.release(), false);
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

    /**
     * Per-host best-effort dispatch. allowFail-style onEach is NOT enough
     * for tolerant fan-out: the real SshPool.onEach pre-resolves a
     * connection for EVERY host before submitting any task, so a single
     * unreachable host throws before the command runs anywhere, and a
     * transport failure inside a task (dead cached connection) is rethrown
     * from future.get() regardless of {raise: false}. Dispatching each host
     * in its own sequential([host]) call with a per-host try/catch confines
     * every failure mode — connect and transport alike — to its host.
     *
     * @return array of {host, message} structs for hosts that failed.
     *
     * MIRROR: DeployMainCli.$dispatchPerHostTolerant is the deploy-flow
     * twin of this helper — keep them in lockstep.
     */
    private array function $dispatchPerHostTolerant(
        required array hosts,
        required string cmd,
        required boolean dryRun
    ) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            }
            return [];
        }
        var c = arguments.cmd;
        var failed = [];
        for (var h in arguments.hosts) {
            try {
                variables.sshPool.sequential([h], function(ssh, host) {
                    ssh.run(c, {raise: false});
                });
            } catch (any e) {
                arrayAppend(failed, {host: h, message: e.message});
            }
        }
        return failed;
    }

    /**
     * Render the unreachable-host warning appended to a verb's summary.
     * Empty string when nothing failed.
     */
    private string function $skippedHostsSuffix(required array failed, required string consequence) {
        if (!arrayLen(arguments.failed)) return "";
        var parts = [];
        for (var f in arguments.failed) {
            arrayAppend(parts, f.host & " (" & f.message & ")");
        }
        return chr(10) & "WARNING: skipped " & arrayLen(arguments.failed)
            & " unreachable host(s): " & arrayToList(parts, "; ")
            & " — " & arguments.consequence & ".";
    }

    /**
     * Per-host best-effort dispatch that ALSO collects the remote output,
     * host-prefixed (`[host] line`). Combines two ##2957 contracts that the
     * `lock status` verb needs at once:
     *   - DEP-1: read the lock on EVERY host (the lock lives fleet-wide), and
     *     tolerate an unreachable host — report it, don't throw. Each host
     *     runs in its own sequential([host]) with a per-host try/catch so a
     *     dead connect or a dead cached session is confined to that host (see
     *     $dispatchPerHostTolerant for why allowFail-style onEach/onAny is not
     *     enough).
     *   - DEP-6a: surface what readlink actually said. Stdout wins (the lock
     *     holder); stderr is the fallback so the "No such file" diagnostic on
     *     an unheld lock still reaches the operator. The command is run with
     *     {raise: false} so a nonzero exit (no lock held) is advisory output,
     *     not a thrown error.
     *
     * @return struct {lines: array of "[host] line", failed: array of
     *         {host, message} for hosts that were unreachable}.
     */
    private struct function $collectPerHostTolerant(
        required array hosts,
        required string cmd,
        required boolean dryRun
    ) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            }
            return {lines: [], failed: []};
        }
        var c = arguments.cmd;
        // Closures can't write outer locals reliably — collect via a shared struct.
        var ctx = {lines: [], failed: []};
        for (var h in arguments.hosts) {
            try {
                variables.sshPool.sequential([h], function(ssh, host) {
                    var res = ssh.run(c, {raise: false});
                    var text = trim(res.stdout ?: "");
                    if (!len(text)) text = trim(res.stderr ?: "");
                    if (!len(text)) return;
                    text = replace(text, chr(13), "", "all");
                    for (var line in listToArray(text, chr(10))) {
                        arrayAppend(ctx.lines, "[" & host & "] " & line);
                    }
                });
            } catch (any e) {
                arrayAppend(ctx.failed, {host: h, message: e.message});
            }
        }
        return ctx;
    }

    private string function $currentUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
