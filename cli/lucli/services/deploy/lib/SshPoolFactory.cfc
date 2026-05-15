/**
 * Factory for SshPool instances seeded from a deploy.yml.
 *
 * Pipeline:
 *   1. configPath missing/empty   → defaultless SshPool
 *   2. configPath unparseable      → defaultless SshPool (swallow; the
 *      deploy verb itself surfaces config errors with proper formatting)
 *   3. otherwise                   → ssh.user, ssh.port, first ssh.keys[]
 *      (with `~/` expanded against `user.home`) seeded into SshPool
 */
component {

	/**
	 * Build a pool from the deploy.yml at `configPath`. Missing files and
	 * parse errors yield a defaultless pool — the verb itself will reload
	 * and report.
	 */
	public any function fromConfigPath(required string configPath) {
		var sshDefaults = {};
		if (len(arguments.configPath) && fileExists(arguments.configPath)) {
			try {
				var loader = new modules.wheels.services.deploy.config.ConfigLoader();
				var cfg = loader.load(arguments.configPath);
				sshDefaults = $defaultsFromConfig(cfg);
			} catch (any e) {
				// Swallow — the verb will reload + report properly.
				sshDefaults = {};
			}
		}
		return new modules.wheels.services.deploy.lib.SshPool(sshDefaults);
	}

	/**
	 * Translate a loaded Config into the defaults struct expected by
	 * `SshPool.init()`. `$` prefix marks this as internal-but-public so
	 * tests can pin the YAML → struct mapping without going through file
	 * I/O. Always returns at least `{user, port}` (sourced from
	 * `Ssh.cfc`'s `"root"` / `22` defaults when the block is absent);
	 * `privateKey` is included only when a non-empty key path is
	 * configured.
	 */
	public struct function $defaultsFromConfig(required any config) {
		var s = arguments.config.ssh();
		var out = {
			user: s.user(),
			port: s.port()
		};
		var keys = s.keys();
		if (arrayLen(keys) >= 1 && len(trim(keys[1]))) {
			out.privateKey = s.$expandHome(keys[1]);
		}
		return out;
	}

}
