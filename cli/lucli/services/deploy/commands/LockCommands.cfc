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
        // The symlink target is three concatenated shell words: the single-
        // quoted (inert) user, a double-quoted middle segment whose
        // $(hostname) and $(date ...) ARE resolved by the remote shell, and
        // the single-quoted (inert) message. Adjacent quoted segments join
        // into one argument, so metacharacters in user/message can't execute
        // while the metadata substitutions still expand. Previously the whole
        // target was single-quoted, which suppressed command substitution and
        // recorded the literal "$(hostname)" text (##2957 DEP-10).
        var target = shellEscape(user)
            & """@$(hostname)/$(date --iso-8601=seconds)/"""
            & shellEscape(message);
        return "ln -s " & target & " " & lockPath();
    }

    public string function release() {
        return "rm -f " & lockPath();
    }

    public string function status() {
        return "readlink " & lockPath();
    }
}
