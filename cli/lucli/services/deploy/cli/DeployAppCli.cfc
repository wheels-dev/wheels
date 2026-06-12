/**
 * App subcommand surface: wheels deploy app <verb>
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/app.rb
 *
 * Phase 2 simplification: live/maintenance use a marker file on the server
 * rather than kamal-proxy's native maintenance mode. Full proxy-native
 * semantics land in a Phase 3 follow-up.
 *
 * Accepts an SshPool (real or Fake) in init() for testability. Config is
 * loaded per invocation. Methods honor opts.dryRun — when true, commands
 * are buffered (read via dryRunOutput()) and no network calls happen.
 */
component {

    public DeployAppCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function boot(required struct opts) {
        // boot (re)creates the container, so env.secret values must be
        // delivered to the role env file first (#2957).
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.run(role, version);
        }, {deliverEnvFile: true});
        return $renderResult(arguments.opts, "Booted app on " & n & " host(s)");
    }

    public string function start(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.start(role, version);
        });
        return $renderResult(arguments.opts, "Started app on " & n & " host(s)");
    }

    public string function stop(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.stop(role, version);
        });
        return $renderResult(arguments.opts, "Stopped app on " & n & " host(s)");
    }

    public string function details(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.status(role, version);
        });
        return $renderResult(arguments.opts, "Collected app details on " & n & " host(s)");
    }

    public string function containers(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.containers();
        }, {versionOptional: true});
        return $renderResult(arguments.opts, "Listed app containers on " & n & " host(s)");
    }

    public string function images(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.images();
        }, {versionOptional: true});
        return $renderResult(arguments.opts, "Listed app images on " & n & " host(s)");
    }

    public string function logs(required struct opts) {
        var logOpts = {
            tail: arguments.opts.tail ?: 100,
            follow: arguments.opts.follow ?: false,
            container: arguments.opts.container ?: ""
        };
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.logs(logOpts);
        }, {versionOptional: true});
        return $renderResult(arguments.opts, "Tailed app logs on " & n & " host(s)");
    }

    public string function live(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.live(role, version);
        });
        return $renderResult(arguments.opts, "Marked app live on " & n & " host(s)");
    }

    public string function maintenance(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.maintenance(role, version);
        });
        return $renderResult(arguments.opts, "Put app into maintenance mode on " & n & " host(s)");
    }

    public string function remove(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.remove(role, version);
        });
        return $renderResult(arguments.opts, "Removed app from " & n & " host(s)");
    }

    // ── Private plumbing ───────────────────────────────────────

    private numeric function $forEachHost(required struct opts, required any cmdFn, struct flags = {}) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var version = arguments.opts.version ?: "";
        var versionOptional = arguments.flags.versionOptional ?: false;
        if (!versionOptional && !len(version)) {
            throw(type="DeployAppCli.MissingVersion",
                  message="This verb requires --version (e.g. --version=v1.2.3). On older wrappers that pre-date the picocli rewrite, pass --release instead.");
        }
        var dryRun = arguments.opts.dryRun ?: false;
        var appCmds = new modules.wheels.services.deploy.commands.AppCommands(cfg);
        var roleFilter = arguments.opts.role ?: "";
        var hostCount = 0;

        // env.secret delivery (#2957): container-(re)creating verbs opt in
        // via flags.deliverEnvFile. Content renders once — an unresolvable
        // secret fails fast locally before any remote call.
        var secretNames = (arguments.flags.deliverEnvFile ?: false) ? cfg.env().secret() : [];
        var envFileContent = "";
        if (arrayLen(secretNames)) {
            envFileContent = appCmds.env_file_content(secretNames, $resolvedSecrets());
        }

        for (var role in cfg.roles()) {
            if (len(roleFilter) && role.name() != roleFilter) continue;
            for (var host in role.hosts()) {
                if (arrayLen(secretNames)) {
                    $deliverEnvFile(
                        [host],
                        appCmds.ensure_env_file(role),
                        appCmds.relock_env_file(role),
                        envFileContent,
                        appCmds.env_file_path(role),
                        secretNames,
                        dryRun
                    );
                }
                var cmd = arguments.cmdFn(appCmds, role, version);
                $dispatch([host], cmd, dryRun);
                hostCount++;
            }
        }
        return hostCount;
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private void function $dispatch(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return;
        }
        // raise defaults to true so nonzero remote exits surface as
        // Wheels.Deploy.RemoteExecutionFailed instead of silently passing — #2696.
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c, {raise: doRaise}); });
    }

    /**
     * Resolved key→value map from the SecretResolver the loader built for
     * the most recent load(). Empty struct when no resolver exists.
     */
    private struct function $resolvedSecrets() {
        var resolver = variables.loader.secretResolver();
        return isObject(resolver) ? resolver.all() : {};
    }

    /**
     * Deliver env.secret content to `remotePath` on each host (#2957):
     * ensure-cmd (mkdir + touch + chmod 600) first so the file is
     * permission-locked before content lands, then SFTP via uploadString —
     * values never enter argv or dry-run output — then relock-cmd
     * (chmod 600) AFTER the upload, belt-and-braces against the SFTP layer
     * resetting perms to 0644 (sshj's preserve-attributes default;
     * SshClient disables it, but FakeSshPool can't verify that, so the
     * re-lock is the testable guarantee). Mirrors
     * DeployMainCli.$deliverEnvFile (each Cli keeps its own dispatch
     * plumbing by design).
     */
    private void function $deliverEnvFile(
        required array hosts,
        required string ensureCmd,
        required string relockCmd,
        required string content,
        required string remotePath,
        required array secretNames,
        required boolean dryRun
    ) {
        $dispatch(arguments.hosts, arguments.ensureCmd, arguments.dryRun);
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(
                    variables.dryRunBuffer,
                    "[" & h & "] upload env file " & arguments.remotePath
                        & " (" & arrayLen(arguments.secretNames) & " secret(s): "
                        & arrayToList(arguments.secretNames, ", ") & " — values not shown)"
                );
            }
            $dispatch(arguments.hosts, arguments.relockCmd, arguments.dryRun);
            return;
        }
        var c = arguments.content;
        var p = arguments.remotePath;
        var relock = arguments.relockCmd;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) {
            ssh.uploadString(c, p);
            ssh.run(relock, {raise: true});
        });
    }
}
