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
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public void function acquire(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new cli.lucli.services.deploy.commands.LockCommands(cfg);
        var cmd = lock.acquire({
            user: $currentUser(),
            message: arguments.opts.message ?: "manual acquire"
        });
        $dispatchAny($allHosts(cfg), cmd, dryRun);
    }

    public void function release(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new cli.lucli.services.deploy.commands.LockCommands(cfg);
        $dispatchAny($allHosts(cfg), lock.release(), dryRun);
    }

    public void function status(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        var lock = new cli.lucli.services.deploy.commands.LockCommands(cfg);
        $dispatchAny($allHosts(cfg), lock.status(), dryRun);
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

    private void function $dispatchAny(required array hosts, required string cmd, required boolean dryRun) {
        if (arguments.dryRun) {
            if (arrayLen(arguments.hosts)) {
                arrayAppend(variables.dryRunBuffer, "[" & arguments.hosts[1] & "] " & arguments.cmd);
            }
            return;
        }
        var c = arguments.cmd;
        // Lock ops target just one host (the lock file lives on one path; any host works).
        variables.sshPool.onAny(arguments.hosts, function(ssh, host) { ssh.run(c); });
    }

    private string function $currentUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }
}
