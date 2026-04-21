/**
 * Registry subcommand surface: wheels deploy registry <verb>
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/registry.rb
 *
 * `setup` is an alias for `login`; `remove` is an alias for `logout`.
 * Password may be supplied via opts.password (tests, explicit CLI flag)
 * or resolved from .kamal/secrets via SecretResolver using the first key
 * listed in registry.password[].
 */
component {

    public DeployRegistryCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public void function setup(required struct opts)  { login(arguments.opts); }
    public void function login(required struct opts)  { $runLogin(arguments.opts, true); }
    public void function logout(required struct opts) { $runLogin(arguments.opts, false); }
    public void function remove(required struct opts) { logout(arguments.opts); }

    // ── Private plumbing ───────────────────────────────────────

    private void function $runLogin(required struct opts, required boolean isLogin) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var regCmds = new cli.lucli.services.deploy.commands.RegistryCommands(cfg);
        var hosts = $allHosts(cfg);
        var cmd = arguments.isLogin
            ? regCmds.login({password: arguments.opts.password ?: $resolvePassword(cfg)})
            : regCmds.logout();
        $dispatch(hosts, cmd, dryRun);
    }

    private string function $resolvePassword(required any cfg) {
        // registry.password is an array of secret keys; we consult the
        // SecretResolver for the first one. If multiple keys are listed,
        // Kamal semantics are "any of these work" — Phase 2 MVP just uses
        // the first.
        var secrets = arguments.cfg.registry().password();
        if (!arrayLen(secrets)) return "";
        var resolver = new cli.lucli.services.deploy.lib.SecretResolver();
        return resolver.get(secrets[1]);
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
