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
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    public array function dryRunOutput() { return variables.dryRunBuffer; }

    public string function deliver(required struct opts) {
        // push clears the buffer and writes; tell pull to preserve what push wrote.
        push(arguments.opts);
        var pullOpts = duplicate(arguments.opts);
        pullOpts.preserveBuffer = "1";
        pull(pullOpts);
        var cfg = $loadCfg(arguments.opts);
        var version = arguments.opts.version ?: $gitShortSha();
        return $renderResult(
            arguments.opts,
            "Delivered " & cfg.image() & ":" & version & " (pushed + pulled)"
        );
    }

    public string function push(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var version = arguments.opts.version ?: $gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;
        if (!len(arguments.opts.preserveBuffer ?: "")) arrayClear(variables.dryRunBuffer);
        var builder = new modules.wheels.services.deploy.commands.BuilderCommands(cfg);
        $runLocal(builder.push(version), dryRun);
        return $renderResult(arguments.opts, "Pushed " & cfg.image() & ":" & version);
    }

    public string function pull(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var version = arguments.opts.version ?: $gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;
        if (!len(arguments.opts.preserveBuffer ?: "")) arrayClear(variables.dryRunBuffer);
        var builder = new modules.wheels.services.deploy.commands.BuilderCommands(cfg);
        var hosts = $allHosts(cfg);
        $dispatchSsh(hosts, builder.pull(version), dryRun);
        return $renderResult(
            arguments.opts,
            "Pulled " & cfg.image() & ":" & version & " on " & arrayLen(hosts) & " host(s)"
        );
    }

    public string function create(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new modules.wheels.services.deploy.commands.BuilderCommands(cfg).create(), dryRun);
        return $renderResult(arguments.opts, "Created builder for " & cfg.image());
    }

    public string function remove(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new modules.wheels.services.deploy.commands.BuilderCommands(cfg).remove(), dryRun);
        return $renderResult(arguments.opts, "Removed builder for " & cfg.image());
    }

    public string function details(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new modules.wheels.services.deploy.commands.BuilderCommands(cfg).details(), dryRun);
        return $renderResult(arguments.opts, "Collected builder details for " & cfg.image());
    }

    public string function dev(required struct opts) {
        var cfg = $loadCfg(arguments.opts);
        var dryRun = arguments.opts.dryRun ?: false;
        arrayClear(variables.dryRunBuffer);
        $runLocal(new modules.wheels.services.deploy.commands.BuilderCommands(cfg).dev(), dryRun);
        return $renderResult(arguments.opts, "Ran dev build for " & cfg.image());
    }

    // ── Private plumbing ───────────────────────────────────────

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

    // Stderr is drained but discarded on non-zero exit so git's "fatal: not a git repository..." doesn't surface as the version string (issue #2671).
    public string function $gitShortSha(string workingDir = "") {
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder")
                .init(["git", "rev-parse", "--short", "HEAD"]);
            if (len(arguments.workingDir)) {
                pb.directory(createObject("java", "java.io.File").init(arguments.workingDir));
            }
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
            var exitCode = proc.waitFor();
            if (exitCode != 0) return "unknown";
            return trim(sb.toString());
        } catch (any e) {
            return "unknown";
        }
    }
}
