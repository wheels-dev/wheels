/**
 * Reads .kamal/secrets (and .kamal/secrets.<destination>) files and
 * expands $(cmd) subshells via local bash, yielding a key→value map.
 *
 * This is how Kamal integrates with external secret managers: users
 * declare `REGISTRY_PASSWORD=$(op read op://Deploy/Registry/password)`
 * in .kamal/secrets and on load the `op` CLI actually runs. We do the
 * same — no embedded vault, no network adapter, just `bash -c`.
 *
 * Destination overlay: .kamal/secrets loads first, then
 * .kamal/secrets.<destination> (if destination is set and the file
 * exists) overrides keys.
 *
 * Missing file is a no-op — ALL calls to .get() return empty string.
 */
component {

    public SecretResolver function init(struct opts = {}) {
        variables.projectRoot = arguments.opts.projectRoot ?: expandPath("./");
        variables.destination = arguments.opts.destination ?: "";
        variables.resolved = $loadAll();
        return this;
    }

    public string function get(required string key) {
        return variables.resolved[arguments.key] ?: "";
    }

    public boolean function has(required string key) {
        return structKeyExists(variables.resolved, arguments.key);
    }

    public struct function all() {
        return duplicate(variables.resolved);
    }

    private struct function $loadAll() {
        var base = $resolveFile($secretPath(""));
        var overlay = len(variables.destination) ? $resolveFile($secretPath(variables.destination)) : {};
        var out = duplicate(base);
        for (var k in overlay) out[k] = overlay[k];
        return out;
    }

    private string function $secretPath(required string destination) {
        var root = variables.projectRoot;
        if (right(root, 1) != "/") root &= "/";
        if (len(arguments.destination)) {
            return root & ".kamal/secrets." & arguments.destination;
        }
        return root & ".kamal/secrets";
    }

    /**
     * Run the given secrets file through `bash -c 'set -a; source FILE; env'`
     * and parse the resulting env block. The difference between our new env
     * and a baseline `env` capture gives us just the keys introduced by the
     * file (including $() expansions, since bash resolves those during source).
     */
    private struct function $resolveFile(required string path) {
        if (!fileExists(arguments.path)) return {};

        // Step 1: capture baseline env so we can subtract it later.
        var baseline = $runBash("env");
        var baselineKeys = $parseEnvKeys(baseline);

        // Step 2: source the file, then emit env. `set -a` exports all vars.
        var cmd = "set -a; source " & $shellEscape(arguments.path) & "; env";
        var enriched = $runBash(cmd);

        var out = {};
        for (var line in listToArray(enriched, chr(10), false)) {
            var eq = find("=", line);
            if (eq < 1) continue;
            var key = left(line, eq - 1);
            var val = mid(line, eq + 1, 99999);
            // Only keep keys introduced by the file (not baseline).
            if (!arrayContainsNoCase(baselineKeys, key)) {
                out[key] = val;
            }
        }
        return out;
    }

    private array function $parseEnvKeys(required string envBlock) {
        var keys = [];
        for (var line in listToArray(arguments.envBlock, chr(10), false)) {
            var eq = find("=", line);
            if (eq > 0) arrayAppend(keys, left(line, eq - 1));
        }
        return keys;
    }

    private string function $runBash(required string cmd) {
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder").init(["bash", "-c", arguments.cmd]);
            pb.redirectErrorStream(true);
            var proc = pb.start();
            var reader = createObject("java", "java.io.BufferedReader").init(
                createObject("java", "java.io.InputStreamReader").init(proc.getInputStream(), "UTF-8")
            );
            var sb = createObject("java", "java.lang.StringBuilder").init();
            var line = reader.readLine();
            while (!isNull(line)) {
                sb.append(line);
                sb.append(chr(10));
                line = reader.readLine();
            }
            proc.waitFor();
            return sb.toString();
        } catch (any e) {
            return "";
        }
    }

    private string function $shellEscape(required string path) {
        return "'" & replace(arguments.path, "'", "'\''", "all") & "'";
    }
}
