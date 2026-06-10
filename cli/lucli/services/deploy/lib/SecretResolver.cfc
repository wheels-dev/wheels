/**
 * Reads .kamal/secrets (and .kamal/secrets.<destination>) files and
 * expands $(cmd) subshells via local bash, yielding a key→value map.
 *
 * This is how Kamal integrates with external secret managers: users
 * declare `REGISTRY_PASSWORD=$(op read op://Deploy/Registry/password)`
 * in .kamal/secrets and on load the `op` CLI actually runs. We do the
 * same — no embedded vault, no network adapter, just `bash -c`.
 *
 * Resolution sources the file in bash (`set -a` exports every assignment
 * and bash expands $(cmd) substitutions), then prints each key DECLARED
 * IN THE FILE back as a KEY<US>VALUE<RS> record (US = chr(31), RS =
 * chr(30)). Reading the declared keys individually — instead of diffing
 * `env` output against a baseline capture — means:
 *   - keys that also exist in the parent environment (user exports, CI
 *     vars) still resolve to the file's value instead of being dropped,
 *   - multi-line values (TLS certs, SSH keys) survive intact, because
 *     records are RS-separated rather than newline-separated.
 *
 * Destination overlay: .kamal/secrets loads first, then
 * .kamal/secrets.<destination> (if destination is set and the file
 * exists) overrides keys.
 *
 * Missing file is a no-op — ALL calls to .get() return empty string.
 * A present file on a machine where bash can't run throws
 * SecretResolver.BashUnavailable instead of silently resolving zero
 * secrets (which would let callers proceed with empty credentials).
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
     * Source the secrets file through bash and read back the value of each
     * key the file declares, as RS-terminated KEY<US>VALUE records.
     */
    private struct function $resolveFile(required string path) {
        if (!fileExists(arguments.path)) return {};

        var candidates = $candidateKeys(fileRead(arguments.path, "UTF-8"));
        if (!arrayLen(candidates)) return {};

        // `set -a` exports every assignment made while sourcing; the file's
        // own stdout is discarded so it can't corrupt the record stream.
        // `${!k+x}` (set-check on the indirected name) filters out candidate
        // keys bash never actually set — e.g. base64 continuation lines of a
        // quoted multi-line value that merely look like assignments.
        // \037 = US (key/value separator), \036 = RS (record terminator).
        // NUL would be the only byte guaranteed absent from env values, but
        // Lucee's chr(0) yields an empty string, so it can't be used as a
        // CFML-side delimiter; RS never appears in realistic secret values.
        var script = "set -a; source " & $shellEscape(arguments.path) & " >/dev/null; "
            & "for __wheels_key in " & arrayToList(candidates, " ") & "; do "
            & "if [ -n ""${!__wheels_key+x}"" ]; then "
            & "printf '%s\037%s\036' ""$__wheels_key"" ""${!__wheels_key}""; "
            & "fi; done";
        var result = $runBash(script);
        if (result.exitCode != 0) {
            throw(
                type = "SecretResolver.ResolutionFailed",
                message = "Resolving secrets from [" & arguments.path & "] failed (bash exit code " & result.exitCode & ").",
                detail = result.err
            );
        }
        return $parseRecords(result.out);
    }

    /**
     * Scan raw file content for the env keys it declares: lines shaped
     * `KEY=...` or `export KEY=...`. Lines inside quoted multi-line values
     * can produce false candidates; those are filtered by the set-check in
     * the resolution script because bash never defines them as variables.
     */
    private array function $candidateKeys(required string content) {
        var keys = [];
        for (var line in listToArray(arguments.content, chr(10), false)) {
            var m = reFind("^[ \t]*(export[ \t]+)?([A-Za-z_][A-Za-z0-9_]*)=", line, 1, true);
            if (arrayLen(m.pos) >= 3 && m.pos[3] > 0) {
                var key = mid(line, m.pos[3], m.len[3]);
                // Exact-match dedupe (arrayFind is case-sensitive): FOO and
                // foo are distinct bash variables, so both stay candidates.
                if (!arrayFind(keys, key)) arrayAppend(keys, key);
            }
        }
        return keys;
    }

    /**
     * Parse the KEY<US>VALUE<RS> records emitted by the resolution script.
     * The RS (chr(30)) terminator doesn't appear in realistic secret values,
     * so multi-line values pass through intact. The `sep > 1` guard skips
     * malformed records and avoids Left(str, 0), which crashes Lucee 7
     * (Cross-Engine Invariant 8).
     */
    private struct function $parseRecords(required string blob) {
        var out = {};
        for (var rec in listToArray(arguments.blob, chr(30), false)) {
            var sep = find(chr(31), rec);
            if (sep <= 1) continue;
            out[left(rec, sep - 1)] = mid(rec, sep + 1, len(rec));
        }
        return out;
    }

    /**
     * Run a command through local bash, capturing stdout and stderr
     * separately. Returns {exitCode, out, err}. Throws
     * SecretResolver.BashUnavailable when bash can't be started (e.g.
     * Windows without WSL/Git Bash) — surfacing the failure beats silently
     * yielding zero secrets.
     */
    private struct function $runBash(required string cmd) {
        var proc = "";
        try {
            var pb = createObject("java", "java.lang.ProcessBuilder").init(["bash", "-c", arguments.cmd]);
            proc = pb.start();
        } catch (any e) {
            throw(
                type = "SecretResolver.BashUnavailable",
                message = "Unable to launch bash to resolve .kamal/secrets: " & e.message,
                detail = "Secret resolution requires a local bash for $(cmd) expansion. On Windows, run inside WSL or Git Bash."
            );
        }
        var out = $readStream(proc.getInputStream());
        var err = $readStream(proc.getErrorStream());
        var exitCode = proc.waitFor();
        return {exitCode: exitCode, out: out, err: err};
    }

    private string function $readStream(required any inputStream) {
        var scanner = createObject("java", "java.util.Scanner").init(arguments.inputStream, "UTF-8");
        scanner.useDelimiter("\A");
        var content = scanner.hasNext() ? scanner.next() : "";
        scanner.close();
        return content;
    }

    private string function $shellEscape(required string path) {
        return "'" & replace(arguments.path, "'", "'\''", "all") & "'";
    }
}
