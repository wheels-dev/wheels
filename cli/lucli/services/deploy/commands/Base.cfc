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
     * Render docker --env-file content (KEY=value lines) for the declared
     * `env.secret` names from an already-resolved secrets map (SecretResolver
     * .all()). Pure string building — resolution I/O happened at config load.
     *
     * Values are escaped Kamal-style for docker's env-file parser (one line
     * per key, no quoting layer): backslash doubled, then any newline form
     * (CRLF / LF / CR) collapsed to a literal `\n` sequence. Docker hands the
     * two-character sequence through verbatim, exactly as Ruby Kamal does.
     *
     * A declared name the resolver can't supply throws
     * Wheels.Deploy.EnvSecretMissing listing the MISSING names only —
     * resolvable keys and all values stay out of the message (##2956/##2957).
     */
    public string function env_file_content(
        required array secretNames,
        required struct resolved
    ) {
        var lines = [];
        var missing = [];
        for (var name in arguments.secretNames) {
            if (!structKeyExists(arguments.resolved, name)) {
                arrayAppend(missing, name);
                continue;
            }
            var v = toString(arguments.resolved[name]);
            v = replace(v, "\", "\\", "all");
            v = replace(v, chr(13) & chr(10), "\n", "all");
            v = replace(v, chr(10), "\n", "all");
            v = replace(v, chr(13), "\n", "all");
            arrayAppend(lines, name & "=" & v);
        }
        if (arrayLen(missing)) {
            throw(
                type = "Wheels.Deploy.EnvSecretMissing",
                message = "env.secret declares [" & arrayToList(missing, ", ")
                    & "] but no value resolved from .kamal/secrets (or its destination overlay). "
                    & "Add the key(s) there — values may use $(cmd) substitution.",
                detail = "Unresolved secret keys are listed by name only; values are never read or printed."
            );
        }
        return arrayToList(lines, chr(10)) & chr(10);
    }

    /**
     * Command that prepares a remote env file before its content is uploaded:
     * create the directory, create the file, and lock it to 600 perms FIRST so
     * the secret content never lands in a world-readable window. Runs before
     * SshClient.uploadString writes the content over SFTP (##2957).
     */
    public string function $ensureEnvFileCmd(required string dir, required string path) {
        return "mkdir -p " & shellEscape(arguments.dir)
            & " && touch " & shellEscape(arguments.path)
            & " && chmod 600 " & shellEscape(arguments.path);
    }

    /**
     * Command that re-locks a remote env file to 600 perms AFTER its content
     * is uploaded. Belt-and-braces for the SFTP layer: sshj's file transfer
     * can apply local-file attributes (0644) to the remote on put — SshClient
     * disables that (setPreserveAttributes(false)), but the real SFTP
     * behavior is unverifiable through FakeSshPool, so the delivery flow also
     * dispatches this re-lock and the specs pin it (##2957).
     */
    public string function $relockEnvFileCmd(required string path) {
        return "chmod 600 " & shellEscape(arguments.path);
    }
}
