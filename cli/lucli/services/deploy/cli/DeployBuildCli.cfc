/**
 * Build subcommand: wheels deploy build <verb>
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/build.rb
 *
 * Most verbs run LOCALLY on the dev machine (push, create, remove, details, dev).
 * Only `pull` fans out over SSH to every server.
 * `deliver` is a composite: push then pull.
 *
 * Accepts an SshPool (real or Fake) in init() for testability. Config is
 * loaded per invocation. Methods honor opts.dryRun — when true, commands
 * are buffered (read via dryRunOutput()) and no network calls happen.
 */
component {

    public DeployBuildCli function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public void function deliver(required struct opts) {
        // push clears the buffer and writes; tell pull to preserve what push wrote.
        push(arguments.opts);
        var pullOpts = duplicate(arguments.opts);
        pullOpts.preserveBuffer = "1";
        pull(pullOpts);
    }

    public void function push(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var version = arguments.opts.version ?: $gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;
        if (!len(arguments.opts.preserveBuffer ?: "")) arrayClear(variables.dryRunBuffer);
        var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
        $runLocal(builder.push(version), dryRun);
    }

    public void function pull(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var version = arguments.opts.version ?: $gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;
        if (!len(arguments.opts.preserveBuffer ?: "")) arrayClear(variables.dryRunBuffer);
        var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
        var hosts = $allHosts(cfg);
        $dispatchSsh(hosts, builder.pull(version), dryRun);
    }

    public void function create(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new cli.lucli.services.deploy.commands.BuilderCommands(cfg).create(), dryRun);
    }

    public void function remove(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new cli.lucli.services.deploy.commands.BuilderCommands(cfg).remove(), dryRun);
    }

    public void function details(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new cli.lucli.services.deploy.commands.BuilderCommands(cfg).details(), dryRun);
    }

    public void function dev(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new cli.lucli.services.deploy.commands.BuilderCommands(cfg).dev(), dryRun);
    }

    // ── Private plumbing ───────────────────────────────────────

    private any function $loadCfg(required struct opts) {
        return variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
    }

    private void function $runLocal(required string cmd, required boolean dryRun) {
        if (arguments.dryRun) {
            arrayAppend(variables.dryRunBuffer, "[local] " & arguments.cmd);
            return;
        }
        var pb = createObject("java", "java.lang.ProcessBuilder").init(["bash", "-c", arguments.cmd]);
        pb.inheritIO();
        var proc = pb.start();
        proc.waitFor();
        if (proc.exitValue() != 0) {
            throw(type="DeployBuildCli.CommandFailed",
                  message="Local build command failed with exit " & proc.exitValue() & ": " & arguments.cmd);
        }
    }

    private void function $dispatchSsh(required array hosts, required string cmd, required boolean dryRun) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            return;
        }
        var c = arguments.cmd;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(c); });
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) {
            for (var h in role.hosts()) arrayAppend(out, h);
        }
        return out;
    }

    private string function $gitShortSha() {
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder")
                .init(["git", "rev-parse", "--short", "HEAD"]);
            pb.redirectErrorStream(true);
            var proc = pb.start();
            var reader = createObject("java", "java.io.BufferedReader").init(
                createObject("java", "java.io.InputStreamReader").init(proc.getInputStream(), "UTF-8")
            );
            var sb = createObject("java", "java.lang.StringBuilder").init();
            var line = reader.readLine();
            while (!isNull(line)) {
                sb.append(line);
                line = reader.readLine();
            }
            proc.waitFor();
            return trim(sb.toString());
        } catch (any e) {
            return "unknown";
        }
    }
}
