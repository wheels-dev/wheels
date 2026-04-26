/**
 * Top-level deploy verbs.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/cli/main.rb
 *
 * Accepts an SshPool (real or Fake) in init() for testability. Config is
 * loaded per invocation and passed into each *Commands.cfc. All methods
 * honor opts.dryRun — when true, commands print to writeOutput with a
 * [host] prefix and no network calls happen.
 *
 * Phase 2 integration: lock acquire/release (bracketing the body of work
 * with try/finally so the lock is released even on failure), and pre/post
 * deploy hooks that run locally on the dev machine via ProcessBuilder.
 */
component {

    public DeployMainCli function init(any sshPool = "", struct opts = {}) {
        variables.sshPool = arguments.sshPool;
        variables.projectRoot = arguments.opts.projectRoot ?: expandPath("./");
        variables.loader = new modules.wheels.services.deploy.config.ConfigLoader();
        variables.dryRunBuffer = [];
        return this;
    }

    /**
     * Accumulated dry-run output from the most recent deploy/rollback/etc.
     * Callers that want to show dry-run commands to the user read this
     * after the verb returns. Emitting to a buffer (rather than writeOutput)
     * keeps the test runner's JSON response stream clean.
     */
    public array function dryRunOutput() {
        return variables.dryRunBuffer;
    }

    public string function version() {
        return "wheels-deploy mirrors kamal 2.4.0 / kamal-proxy v0.8.6";
    }

    public string function config(required struct opts) {
        var cfg = variables.loader.load(arguments.opts.configPath);
        var yaml = new modules.wheels.services.deploy.lib.Yaml();
        var rolesMap = $roleHosts(cfg);
        return yaml.dump({
            service: cfg.service(),
            image: cfg.image(),
            servers: rolesMap,
            registry: {
                server: cfg.registry().server(),
                username: cfg.registry().username()
            }
        });
    }

    public string function deploy(required struct opts) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var ver = arguments.opts.version ?: $gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;

        var app = new modules.wheels.services.deploy.commands.AppCommands(cfg);
        var proxy = new modules.wheels.services.deploy.commands.ProxyCommands(cfg);
        var builder = new modules.wheels.services.deploy.commands.BuilderCommands(cfg);
        var lock = new modules.wheels.services.deploy.commands.LockCommands(cfg);
        var hooks = new modules.wheels.services.deploy.commands.HookCommands(
            cfg,
            {projectRoot: variables.projectRoot}
        );

        var hosts = $allHosts(cfg);
        var hookEnv = {
            KAMAL_VERSION: ver,
            KAMAL_HOSTS: arrayToList(hosts, ",")
        };
        var deployStart = getTickCount();

        $fireHook(hooks, "pre-deploy", hookEnv, dryRun);

        try {
            $dispatchAny(
                hosts,
                lock.acquire({user: $currentUser(), message: "deploy " & ver}),
                dryRun
            );

            try {
                $dispatch(hosts, builder.pull(ver), dryRun);
                $dispatchAny(hosts, proxy.details() & " || " & proxy.boot(), dryRun);

                for (var role in cfg.roles()) {
                    for (var host in role.hosts()) {
                        $dispatch([host], app.run(role, ver), dryRun);
                        $dispatch(
                            [host],
                            proxy.deploy(role, app.container_name(role, ver) & ":3000"),
                            dryRun
                        );
                    }
                }
            } finally {
                $dispatchAny(hosts, lock.release(), dryRun);
            }

            hookEnv.KAMAL_RUNTIME = int((getTickCount() - deployStart) / 1000);
            $fireHook(hooks, "post-deploy", hookEnv, dryRun);
        } catch (any e) {
            hookEnv.KAMAL_RUNTIME = int((getTickCount() - deployStart) / 1000);
            hookEnv.KAMAL_ERROR = e.message;
            $fireHook(hooks, "post-deploy-failure", hookEnv, dryRun);
            rethrow;
        }

        return $renderResult(
            arguments.opts,
            "Deployed " & cfg.service() & " version " & ver
                & " to " & arrayLen(hosts) & " host(s): " & arrayToList(hosts, ", ")
        );
    }

    public string function redeploy(required struct opts) {
        return deploy(arguments.opts);
    }

    public string function rollback(required struct opts) {
        arrayClear(variables.dryRunBuffer);
        if (!len(arguments.opts.version ?: "")) {
            throw(
                type = "DeployMainCli.MissingVersion",
                message = "rollback requires a version (pass opts.version)"
            );
        }
        var cfg = variables.loader.load(arguments.opts.configPath);
        var app = new modules.wheels.services.deploy.commands.AppCommands(cfg);
        var proxy = new modules.wheels.services.deploy.commands.ProxyCommands(cfg);
        var dryRun = arguments.opts.dryRun ?: false;
        var hostList = [];
        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                $dispatch([host], app.start(role, arguments.opts.version), dryRun);
                $dispatch(
                    [host],
                    proxy.deploy(role, app.container_name(role, arguments.opts.version) & ":3000"),
                    dryRun
                );
                arrayAppend(hostList, host);
            }
        }

        return $renderResult(
            arguments.opts,
            "Rolled back " & cfg.service() & " to version " & arguments.opts.version
                & " on " & arrayLen(hostList) & " host(s): " & arrayToList(hostList, ", ")
        );
    }

    public string function setup(required struct opts) {
        // Phase 2 will add accessory boot; for Phase 1 this equals deploy.
        return deploy(arguments.opts);
    }

    /**
     * Print the on-server audit log. Emits `tail -n <N> /tmp/kamal-audit.log`
     * on every host, aggregates output via the dry-run buffer when requested.
     */
    public string function audit(required struct opts) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var tail = arguments.opts.tail ?: 100;
        var cmd = "tail -n " & tail & " /tmp/kamal-audit.log";
        var hosts = $allHosts(cfg);
        var dryRun = arguments.opts.dryRun ?: false;
        $dispatch(hosts, cmd, dryRun);
        return $renderResult(
            arguments.opts,
            "Tailed audit log (last " & tail & " lines) on "
                & arrayLen(hosts) & " host(s): " & arrayToList(hosts, ", ")
        );
    }

    /**
     * Embedded Markdown help.
     * Bare `docs` prints a TOC of available sections; `docs <section>`
     * prints that section's content. Section files live in ./docs/*.md.
     */
    public string function docs(required struct opts) {
        var section = arguments.opts.section ?: "";
        var sections = $docsSections();
        if (!len(section)) {
            return "Available docs sections:" & chr(10) & chr(10)
                 & "  " & arrayToList(sections, chr(10) & "  ") & chr(10) & chr(10)
                 & "Usage: wheels deploy docs <section>";
        }
        var path = $docsPath(section);
        if (!fileExists(path)) {
            throw(
                type = "DeployMainCli.UnknownDocsSection",
                message = "No docs section named '" & section & "'. Run 'wheels deploy docs' for the list."
            );
        }
        return fileRead(path);
    }

    /**
     * Aggregate of app.containers, proxy.details, and accessory.details
     * for every accessory. Dispatched per-host so the user can see the
     * state of each host independently.
     */
    public string function details(required struct opts) {
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var appCmds = new modules.wheels.services.deploy.commands.AppCommands(cfg);
        var proxyCmds = new modules.wheels.services.deploy.commands.ProxyCommands(cfg);
        var hosts = $allHosts(cfg);

        // app details: docker ps filtered by service label
        $dispatch(hosts, appCmds.containers(), dryRun);
        // proxy details: docker ps filtered by kamal-proxy name
        $dispatch(hosts, proxyCmds.details(), dryRun);
        // accessory details (if any)
        if (arrayLen(cfg.accessories())) {
            var accCmds = new modules.wheels.services.deploy.commands.AccessoryCommands(cfg);
            for (var acc in cfg.accessories()) {
                $dispatch(acc.hosts(), accCmds.details(acc), dryRun);
            }
        }
        return $renderResult(
            arguments.opts,
            "Collected app + proxy + accessory details from "
                & arrayLen(hosts) & " host(s): " & arrayToList(hosts, ", ")
        );
    }

    /**
     * Destructive teardown. Requires --confirm. Chains app container
     * removal → proxy removal → accessory removal → registry logout.
     */
    public string function remove(required struct opts) {
        if (!(arguments.opts.confirm ?: false)) {
            throw(
                type = "DeployMainCli.RemoveNotConfirmed",
                message = "remove is destructive — pass --confirm to proceed"
            );
        }
        arrayClear(variables.dryRunBuffer);
        var cfg = variables.loader.load(
            arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""}
        );
        var dryRun = arguments.opts.dryRun ?: false;
        var proxyCmds = new modules.wheels.services.deploy.commands.ProxyCommands(cfg);
        var regCmds = new modules.wheels.services.deploy.commands.RegistryCommands(cfg);
        var hosts = $allHosts(cfg);

        // Remove all app containers for this service, across all versions.
        // Versions can't be enumerated locally, so we issue a broad
        // docker rm scoped by the service label.
        var broadRemove = "docker ps -a --filter label=service=" & cfg.service()
                        & " --format '{{.ID}}' | xargs -r docker rm -f";
        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                $dispatch([host], broadRemove, dryRun);
            }
        }
        // Remove proxy.
        $dispatch(hosts, proxyCmds.remove(), dryRun);
        // Remove each accessory.
        if (arrayLen(cfg.accessories())) {
            var accCmds = new modules.wheels.services.deploy.commands.AccessoryCommands(cfg);
            for (var acc in cfg.accessories()) {
                $dispatch(acc.hosts(), accCmds.remove(acc), dryRun);
            }
        }
        // Logout of registry.
        $dispatch(hosts, regCmds.logout(), dryRun);

        return $renderResult(
            arguments.opts,
            "Removed " & cfg.service() & " and its containers from "
                & arrayLen(hosts) & " host(s): " & arrayToList(hosts, ", ")
        );
    }

    private array function $docsSections() {
        // Hardcoded to keep TOC output stable across Lucee / Adobe
        // (directoryList sort differs). The files must exist on disk —
        // $docsPath throws if one goes missing.
        return [
            "accessories",
            "builder",
            "env",
            "hooks",
            "proxy",
            "registry",
            "servers",
            "ssh"
        ];
    }

    private string function $docsPath(required string section) {
        return expandPath("/cli/lucli/services/deploy/cli/docs")
             & "/" & arguments.section & ".md";
    }

    public string function init_stub(required struct opts) {
        var cwd = arguments.opts.cwd ?: expandPath("./");
        if (right(cwd, 1) != "/") cwd &= "/";

        var force = arguments.opts.force ?: false;
        var deployYmlPath = cwd & "config/deploy.yml";
        var secretsPath = cwd & ".kamal/secrets";

        if (!force && fileExists(deployYmlPath)) {
            throw(
                type = "DeployMainCli.InitAlreadyExists",
                message = "config/deploy.yml already exists at " & deployYmlPath & "; pass --force to overwrite"
            );
        }

        var serviceName = arguments.opts.service ?: $basename(cwd);
        var imageName = arguments.opts.image ?: (serviceName & "/web");
        var registryUser = arguments.opts.registryUsername ?: "changeme";

        var mustache = new modules.wheels.services.deploy.lib.Mustache();
        var tplDir = expandPath("/cli/lucli/templates/deploy/init");
        var ctx = {
            service_name: serviceName,
            image_name: imageName,
            registry_username: registryUser
        };

        if (!directoryExists(cwd & "config")) directoryCreate(cwd & "config", true, true);
        fileWrite(deployYmlPath, mustache.render(fileRead(tplDir & "/deploy.yml.mustache"), ctx));

        if (!directoryExists(cwd & ".kamal/hooks")) directoryCreate(cwd & ".kamal/hooks", true, true);
        fileWrite(secretsPath, mustache.render(fileRead(tplDir & "/secrets.mustache"), ctx));

        return "Created config/deploy.yml and .kamal/secrets." & chr(10)
             & "Next steps:" & chr(10)
             & "  1. Edit config/deploy.yml — update servers, proxy host, registry username." & chr(10)
             & "  2. Populate .kamal/secrets with real values (or $(cmd) substitutions)." & chr(10)
             & "  3. wheels deploy setup";
    }

    private string function $basename(required string path) {
        var parts = listToArray(arguments.path, "/\");
        if (!arrayLen(parts)) return "myapp";
        return parts[arrayLen(parts)];
    }

    // ── Private helpers ────────────────────────────────────────────

    /**
     * Unified result renderer. In --dry-run mode, returns the buffered
     * commands so the operator can inspect them. In real mode, returns
     * the caller-supplied summary so the user gets visible confirmation
     * that the deploy completed. Avoids the blank-string bug that occurs
     * when Module.cfc wraps void verbs with dryRunOutput().
     */
    private string function $renderResult(required struct opts, required string summary) {
        if (arguments.opts.dryRun ?: false) {
            return arrayToList(variables.dryRunBuffer, chr(10));
        }
        return arguments.summary;
    }

    private void function $dispatch(
        required array hosts,
        required string cmd,
        required boolean dryRun
    ) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) {
                arrayAppend(variables.dryRunBuffer, "[" & h & "] " & arguments.cmd);
            }
            return;
        }
        // Capture cmd into a local so the closure sees a stable reference
        // (Adobe CF argument-scope closures can be flaky otherwise).
        var c = arguments.cmd;
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) {
            ssh.run(c);
        });
    }

    /**
     * Dispatch a single command to "any one" host — used for operations
     * that only need to happen once across the fleet (lock acquire/release,
     * proxy boot check). FakeSshPool.onAny records exactly one call.
     */
    private void function $dispatchAny(
        required array hosts,
        required string cmd,
        required boolean dryRun
    ) {
        if (arguments.dryRun) {
            arrayAppend(variables.dryRunBuffer, "[any] " & arguments.cmd);
            return;
        }
        if (arrayLen(arguments.hosts) == 0) return;
        var c = arguments.cmd;
        // Prefer onAny when available (both real SshPool and FakeSshPool
        // expose it). Fall back to onEach with a single host otherwise.
        if (structKeyExists(variables.sshPool, "onAny")) {
            variables.sshPool.onAny(arguments.hosts, function(ssh, host) {
                ssh.run(c);
            });
        } else {
            variables.sshPool.onEach([arguments.hosts[1]], function(ssh, host) {
                ssh.run(c);
            });
        }
    }

    /**
     * Fire a local hook with KAMAL_* env. Silently no-ops if the hook
     * doesn't exist (hooks are optional). Under dryRun, records a marker
     * in the dryRun buffer instead of exec'ing.
     */
    private void function $fireHook(
        required any hooks,
        required string name,
        required struct env,
        required boolean dryRun
    ) {
        var h = arguments.hooks.forHook(arguments.name, arguments.env);
        if (!h.exists) return;

        if (arguments.dryRun) {
            arrayAppend(
                variables.dryRunBuffer,
                "[local] hook " & arguments.name & " " & h.hookPath
            );
            return;
        }

        var pb = createObject("java", "java.lang.ProcessBuilder").init([h.hookPath]);
        var envMap = pb.environment();
        for (var k in h.env) {
            envMap.put(javaCast("string", k), javaCast("string", h.env[k]));
        }
        pb.directory(createObject("java", "java.io.File").init(variables.projectRoot));
        pb.redirectErrorStream(true);
        var proc = pb.start();
        var reader = createObject("java", "java.io.BufferedReader").init(
            createObject("java", "java.io.InputStreamReader").init(
                proc.getInputStream(), "UTF-8"
            )
        );
        var line = reader.readLine();
        while (!isNull(line)) {
            writeOutput("[hook:" & arguments.name & "] " & line & chr(10));
            line = reader.readLine();
        }
        var exitCode = proc.waitFor();
        if (exitCode != 0) {
            throw(
                type = "DeployMainCli.HookFailed",
                message = "Hook " & arguments.name & " exited with code " & exitCode
            );
        }
    }

    private string function $currentUser() {
        var sys = createObject("java", "java.lang.System");
        var user = sys.getenv("USER");
        if (isNull(user) || !len(user)) user = "unknown";
        return user;
    }

    private array function $allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) {
            for (var h in role.hosts()) arrayAppend(out, h);
        }
        return out;
    }

    private struct function $roleHosts(required any cfg) {
        var out = {};
        for (var role in arguments.cfg.roles()) {
            out[role.name()] = role.hosts();
        }
        return out;
    }

    private string function $gitShortSha() {
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder")
                .init(["git", "rev-parse", "--short", "HEAD"]);
            pb.redirectErrorStream(true);
            var proc = pb.start();
            proc.waitFor();
            var reader = createObject("java", "java.io.BufferedReader").init(
                createObject("java", "java.io.InputStreamReader").init(
                    proc.getInputStream(), "UTF-8"
                )
            );
            var sb = createObject("java", "java.lang.StringBuilder").init();
            var line = reader.readLine();
            while (!isNull(line)) {
                sb.append(line);
                line = reader.readLine();
            }
            return trim(sb.toString());
        } catch (any e) {
            return "unknown";
        }
    }

}
