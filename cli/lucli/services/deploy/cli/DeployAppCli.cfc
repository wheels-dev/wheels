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
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public void function boot(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.run(role, version);
        });
    }

    public void function start(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.start(role, version);
        });
    }

    public void function stop(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.stop(role, version);
        });
    }

    public void function details(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.status(role, version);
        });
    }

    public void function containers(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.containers();
        }, {versionOptional: true});
    }

    public void function images(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.images();
        }, {versionOptional: true});
    }

    public void function logs(required struct opts) {
        var logOpts = {
            tail: arguments.opts.tail ?: 100,
            follow: arguments.opts.follow ?: false,
            container: arguments.opts.container ?: ""
        };
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.logs(logOpts);
        }, {versionOptional: true});
    }

    public void function live(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.live(role, version);
        });
    }

    public void function maintenance(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.maintenance(role, version);
        });
    }

    public void function remove(required struct opts) {
        $forEachHost(arguments.opts, function(cmds, role, version) {
            return cmds.remove(role, version);
        });
    }

    // ── Private plumbing ───────────────────────────────────────

    private void function $forEachHost(required struct opts, required any cmdFn, struct flags = {}) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var version = arguments.opts.version ?: "";
        var versionOptional = arguments.flags.versionOptional ?: false;
        if (!versionOptional && !len(version)) {
            throw(type="DeployAppCli.MissingVersion",
                  message="This verb requires --version");
        }
        var dryRun = arguments.opts.dryRun ?: false;
        var appCmds = new cli.lucli.services.deploy.commands.AppCommands(cfg);
        var roleFilter = arguments.opts.role ?: "";

        for (var role in cfg.roles()) {
            if (len(roleFilter) && role.name() != roleFilter) continue;
            for (var host in role.hosts()) {
                var cmd = arguments.cmdFn(appCmds, role, version);
                $dispatch([host], cmd, dryRun);
            }
        }
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
