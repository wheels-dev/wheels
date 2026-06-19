/**
 * Registry subcommand surface: wheels deploy registry <verb>
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/registry.rb
 *
 * `setup` is an alias for `login`; `remove` is an alias for `logout`.
 * Password may be supplied via opts.password (tests, programmatic callers)
 * or resolved from .kamal/secrets via SecretResolver using the first key
 * listed in registry.password[]. Either way it is delivered to the remote
 * `docker login --password-stdin` over SSH stdin — never as part of the
 * command string (#2956).
 */
component {

    public DeployRegistryCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function setup(required struct opts)  { return login(arguments.opts); }
    public string function login(required struct opts)  { return $runLogin(arguments.opts, true); }
    public string function logout(required struct opts) { return $runLogin(arguments.opts, false); }
    public string function remove(required struct opts) { return logout(arguments.opts); }

    // ── Private plumbing ───────────────────────────────────────

    private string function $runLogin(required struct opts, required boolean isLogin) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var regCmds = new modules.wheels.services.deploy.commands.RegistryCommands(cfg);
        var hosts = $allHosts(cfg);
        // #2956: the password never enters the command string. login() emits
        // `--password-stdin` and the secret travels via SSH exec-channel
        // stdin, so dry-run output, exception summaries, and remote argv
        // stay clean.
        var pw = "";
        if (arguments.isLogin) {
            pw = arguments.opts.password ?: $resolvePassword(cfg);
            if (!len(pw) && !dryRun) {
                throw(
                    type = "DeployRegistryCli.MissingPassword",
                    message = "No registry password available — `docker login --password-stdin` "
                        & "would receive an empty secret. Declare the key listed under "
                        & "registry.password[] in deploy.yml inside .kamal/secrets."
                );
            }
        }
        var cmd = arguments.isLogin ? regCmds.login() : regCmds.logout();
        // #2696: login is strict (auth failure must surface); logout tolerates.
        $dispatch(hosts, cmd, dryRun, !arguments.isLogin, pw);
        var action = arguments.isLogin ? "Logged into" : "Logged out of";
        return $renderResult(
            arguments.opts,
            action & " registry " & cfg.registry().server()
                & " on " & arrayLen(hosts) & " host(s)"
        );
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private string function $resolvePassword(required any cfg) {
        // registry.password is an array of secret keys; we consult the
        // SecretResolver for the first one. If multiple keys are listed,
        // Kamal semantics are "any of these work" — Phase 2 MVP just uses
        // the first.
        var secrets = arguments.cfg.registry().password();
        if (!arrayLen(secrets)) return "";
        var resolver = new modules.wheels.services.deploy.lib.SecretResolver();
        return resolver.get(secrets[1]);
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) {
            for (var h in role.hosts()) arrayAppend(out, h);
        }
        return out;
    }

    private void function $dispatch(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false, string stdinData = "") {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return;
        }
        // #2696: registry login is strict; logout is tolerant.
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        var sin = arguments.stdinData;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c, {raise: doRaise, stdin: sin}); });
    }
}
