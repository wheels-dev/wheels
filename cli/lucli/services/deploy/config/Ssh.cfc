/**
 * Ssh — immutable accessor for the `ssh:` block.
 *
 * Mirrors Kamal's lib/kamal/configuration/ssh.rb defaults:
 *   user:      deploy user on target hosts (default root)
 *   port:      sshd port (default 22)
 *   proxy:     bastion/jump host (empty = direct)
 *   keys:      array of private key paths (default empty -> ssh-agent)
 *   keys_only: disallow password auth (default false)
 */
component {

	public any function init(struct raw = {}) {
		variables.raw = arguments.raw;
		return this;
	}

	public string function user() {
		return variables.raw.user ?: "root";
	}

	public numeric function port() {
		return variables.raw.port ?: 22;
	}

	public string function proxy() {
		return variables.raw.proxy ?: "";
	}

	/**
	 * Private key paths. Kamal stores `keys:` as an array of strings; tilde
	 * (`~/`) expansion is the caller's responsibility — sshj's
	 * `loadKeys(String)` reads via `java.io.File`, which does not expand
	 * the home shortcut.
	 */
	public array function keys() {
		if (structKeyExists(variables.raw, "keys") && isArray(variables.raw.keys)) {
			return variables.raw.keys;
		}
		return [];
	}

	public boolean function keysOnly() {
		var v = "";
		if (structKeyExists(variables.raw, "keys_only")) v = variables.raw.keys_only;
		else if (structKeyExists(variables.raw, "keysOnly")) v = variables.raw.keysOnly;
		else return false;
		return isBoolean(v) ? v : false;
	}

	/**
	 * Expand a leading `~` / `~/` in a path against the JVM `user.home`
	 * property. sshj's `loadKeys(String)` reads via `java.io.File`, which
	 * doesn't expand the home shortcut — so callers that hand SSH key
	 * paths off to sshj must expand first or sshj will look for a file
	 * literally named `~`.
	 *
	 * `$` prefix marks this as internal-but-public so it can be unit-tested
	 * without going through a Module instance; per CLAUDE.md, `private`
	 * mixin/helper functions don't survive cross-engine integration paths,
	 * so we use public-with-`$` instead.
	 */
	public string function $expandHome(required string path) {
		if (arguments.path == "~") {
			return createObject("java", "java.lang.System").getProperty("user.home");
		}
		if (left(arguments.path, 2) == "~/") {
			var home = createObject("java", "java.lang.System").getProperty("user.home");
			return home & "/" & mid(arguments.path, 3, len(arguments.path) - 2);
		}
		return arguments.path;
	}

}
