/**
 * Shared string-building helpers for *Commands.cfc.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/base.rb
 * All methods return strings. No I/O.
 */
component {

    public string function docker() {
        var parts = ["docker"];
        for (var i = 1; i <= arrayLen(arguments); i++) {
            var a = arguments[i];
            if (isArray(a)) {
                for (var item in a) if (len(item)) arrayAppend(parts, item);
            } else if (len(a)) {
                arrayAppend(parts, a);
            }
        }
        return arrayToList(parts, " ");
    }

    public string function combine(required array cmds, string sep = " ") {
        return arrayToList(arguments.cmds, arguments.sep);
    }

    public string function chain(required array cmds) {
        return combine(arguments.cmds, " && ");
    }

    public string function pipe(required array cmds) {
        return combine(arguments.cmds, " | ");
    }

    public string function appendIf(required boolean cond, required array args) {
        return arguments.cond ? arrayToList(arguments.args, " ") : "";
    }

    /**
     * POSIX-shell single-quote a value so embedded metacharacters ($( ),
     * backticks, semicolons, spaces) stay inert when the command reaches a
     * remote or local shell. Embedded single quotes are closed, escaped,
     * and reopened ('\''). Same logic as SecretResolver.$shellEscape (##2956).
     */
    public string function shellEscape(required string value) {
        return "'" & replace(arguments.value, "'", "'\''", "all") & "'";
    }

    /**
     * Fail fast on a non-empty `env.secret` block: wheels deploy has no
     * env-file delivery mechanism yet, so declared secrets would silently
     * never reach the container — and the natural workaround (moving them
     * to env.clear) would funnel them into plaintext remote argv. Secret
     * NAMES only are surfaced; values are never read (##2956). Env-file
     * delivery is tracked in ##2957. An empty `secret: []` stays a no-op.
     */
    public void function $rejectEnvSecrets(required any env) {
        var secretNames = arguments.env.secret();
        if (arrayLen(secretNames)) {
            throw(
                type = "Wheels.Deploy.EnvSecretUnsupported",
                message = "env.secret is not yet delivered to containers by wheels deploy — "
                    & "declared secret(s) [" & arrayToList(secretNames, ", ")
                    & "] would be silently omitted. Remove the env.secret block for now; "
                    & "env-file delivery is tracked in wheels-dev/wheels ##2957.",
                detail = "Secret names are listed by name only; their values are never read or printed."
            );
        }
    }
}
