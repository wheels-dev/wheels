/**
 * Deploy lock acquire/release/status commands.
 *
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/lock.rb
 *
 * Lock path: /tmp/kamal_deploy_lock_<service>
 * Mechanism: symlink whose target encodes user/host/timestamp/message.
 *   - Acquire: ln -s "<metadata>" <path> — atomic, fails if target exists.
 *   - Release: rm -f <path>.
 *   - Status: readlink <path> — prints metadata or errors if unlocked.
 *
 * The <metadata> target is a base64-ish URL-safe string in Kamal's Ruby
 * impl; we use a simpler human-readable form
 * (<user>@<host>/<iso-timestamp>/<message>) since the data is only ever
 * displayed for humans, never parsed. Deliberate divergence; documented
 * in the Phase 2 retrospective.
 */
component extends="Base" {

    public LockCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function lockPath() {
        return "/tmp/kamal_deploy_lock_" & variables.config.service();
    }

    public string function acquire(required struct opts) {
        var user = arguments.opts.user ?: "unknown";
        var message = arguments.opts.message ?: "";
        // $(hostname) and $(date ...) resolved by the remote shell; user and
        // message are escaped by surrounding the whole target in single
        // quotes so shell metacharacters don't blow up the ln command.
        // Inner single quotes in either value are closed and re-opened
        // ( "'\''").
        var safeUser = replace(user, "'", "'\''", "all");
        var safeMessage = replace(message, "'", "'\''", "all");
        var target = "'" & safeUser & "@$(hostname)/$(date --iso-8601=seconds)/" & safeMessage & "'";
        return "ln -s " & target & " " & lockPath();
    }

    public string function release() {
        return "rm -f " & lockPath();
    }

    public string function status() {
        return "readlink " & lockPath();
    }
}
