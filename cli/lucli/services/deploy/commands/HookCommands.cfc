/**
 * Dev-machine hook discovery + env contract.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/hook.rb
 *
 * Unlike every other *Commands.cfc, HookCommands does NOT emit shell
 * strings for SSH execution. Hooks run on the DEV machine via a local
 * ProcessBuilder (triggered by DeployMainCli). This class returns a
 * `{hookPath, env, exists}` struct describing what to run.
 *
 * Hook env block prefix is KAMAL_* (NOT WHEELS_*). This is required for
 * compatibility with users migrating from Ruby Kamal — their existing
 * hook scripts read KAMAL_VERSION/KAMAL_HOSTS/etc. and must work unchanged.
 *
 * The class does NO I/O beyond fileExists() — actual process invocation
 * is the Cli layer's responsibility.
 */
component extends="Base" {

    public HookCommands function init(required any config, struct opts = {}) {
        variables.config = arguments.config;
        variables.projectRoot = arguments.opts.projectRoot ?: expandPath("./");
        return this;
    }

    public string function hookPath(required string name) {
        // Normalize trailing slash on projectRoot.
        var root = variables.projectRoot;
        if (right(root, 1) != "/") root &= "/";
        return root & ".kamal/hooks/" & arguments.name;
    }

    public struct function forHook(required string name, required struct env) {
        var path = hookPath(arguments.name);
        var exists = fileExists(path);
        // Lucee fileInfo().mode — could check for executable bit; for v1
        // we treat "file exists" as sufficient and let the OS complain if
        // it's not executable. The cli layer can refine this if needed.
        var enriched = $enrichEnv(arguments.env);
        return {
            hookPath: path,
            env: enriched,
            exists: exists
        };
    }

    private struct function $enrichEnv(required struct callerEnv) {
        var out = duplicate(arguments.callerEnv);
        out.KAMAL_PERFORMER = out.KAMAL_PERFORMER ?: $performer();
        out.KAMAL_DESTINATION = out.KAMAL_DESTINATION ?: variables.config.destination();
        return out;
    }

    private string function $performer() {
        // Try git user.name first, fall back to $USER env.
        var name = $runLocal(["git", "config", "user.name"]);
        if (!len(name)) {
            var sys = createObject("java", "java.lang.System");
            name = sys.getenv("USER");
            if (isNull(name) || !len(name)) name = "unknown";
        }
        return name;
    }

    private string function $runLocal(required array cmdArgs) {
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder").init(arguments.cmdArgs);
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
            return "";
        }
    }
}
