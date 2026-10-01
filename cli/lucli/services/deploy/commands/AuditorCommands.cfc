/**
 * Audit log append commands.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/auditor.rb
 *
 * Emits a remote shell append of a timestamped event line to
 * /tmp/kamal-audit.log. The shell handles timestamping via `date`.
 */
component extends="Base" {

    public AuditorCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function record(required string event) {
        // Only the timestamp is left to the shell; the service and event text
        // (which carries the release version) reach it single-quoted, so
        // $( ), backticks and separators in a version stay inert.
        var text = "#variables.config.service()# #arguments.event#";
        return "echo ""$(date --iso-8601=seconds)"" " & shellEscape(text) & " >> /tmp/kamal-audit.log";
    }
}
