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
        var line = "$(date --iso-8601=seconds) #variables.config.service()# #arguments.event#";
        // Escape nothing — the event is produced by our Cli layer, not user input to shell.
        return "echo """ & line & """ >> /tmp/kamal-audit.log";
    }
}
