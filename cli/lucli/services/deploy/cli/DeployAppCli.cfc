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
        // Host-prefixed remote stdout collected by read verbs (#2957 DEP-6a).
        variables.liveOutput = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function boot(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.run(role, version);
        });
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
        }, {collect: true});
        return $renderResult(arguments.opts, "Collected app details on " & n & " host(s)");
    }

    public string function containers(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.containers();
        }, {versionOptional: true, collect: true});
        return $renderResult(arguments.opts, "Listed app containers on " & n & " host(s)");
    }

    public string function images(required struct opts) {
        var n = $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.images();
        }, {versionOptional: true, collect: true});
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
        }, {versionOptional: true, collect: true});
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
        arrayClear(variables.liveOutput);
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
        // collect=true marks a read verb: remote stdout is gathered into
        // liveOutput and appended to the live-mode summary (#2957 DEP-6a).
        var collect = arguments.flags.collect ?: false;
        var appCmds = new modules.wheels.services.deploy.commands.AppCommands(cfg);
        var roleFilter = arguments.opts.role ?: "";
        var hostCount = 0;

        for (var role in cfg.roles()) {
            if (len(roleFilter) && role.name() != roleFilter) continue;
            for (var host in role.hosts()) {
                var cmd = arguments.cmdFn(appCmds, role, version);
                if (collect) {
                    for (var l in $dispatchCollect([host], cmd, dryRun)) {
                        arrayAppend(variables.liveOutput, l);
                    }
                } else {
                    $dispatch([host], cmd, dryRun);
                }
                hostCount++;
            }
        }
        return hostCount;
    }

    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        if (arrayLen(variables.liveOutput)) {
            return arguments.summary & chr(10) & arrayToList(variables.liveOutput, chr(10));
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
     * Dispatch + collect host-prefixed remote output (`[host] line`) for
     * read verbs (#2957 DEP-6a). Sequential so output order is stable and
     * the collection stays single-threaded. Mirrors
     * DeployMainCli.$dispatchCollect — keep the two in lockstep.
     */
    private array function $dispatchCollect(required array hosts, required string cmd, required boolean dryRun, boolean allowFail = false) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return [];
        }
        var c = arguments.cmd;
        var doRaise = !arguments.allowFail;
        var ctx = {lines: []};
        variables.sshPool.sequential(arguments.hosts, function(ssh, host) {
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
}
