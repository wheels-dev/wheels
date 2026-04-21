/**
 * Ssh — immutable accessor for the `ssh:` block.
 *
 * Mirrors Kamal's lib/kamal/configuration/ssh.rb defaults:
 *   user:      deploy user on target hosts (default root)
 *   port:      sshd port (default 22)
 *   proxy:     bastion/jump host (empty = direct)
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

	public boolean function keysOnly() {
		var v = "";
		if (structKeyExists(variables.raw, "keys_only")) v = variables.raw.keys_only;
		else if (structKeyExists(variables.raw, "keysOnly")) v = variables.raw.keysOnly;
		else return false;
		return isBoolean(v) ? v : false;
	}

}
