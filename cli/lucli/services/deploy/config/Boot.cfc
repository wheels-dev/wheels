/**
 * Boot — immutable accessor for the `boot:` block.
 *
 * Mirrors Kamal's lib/kamal/configuration/boot.rb:
 *   limit: number of hosts (or a percentage string like "25%") to boot at a
 *          time (default 10)
 *   wait:  seconds to wait between host boots (default 5)
 *
 * `wheels deploy` applies the block only when deploy.yml has one (see
 * DeployMainCli): each role's hosts boot in batches of batchSize(), with
 * wait() seconds between batches.
 *
 * Both keys are single-word (`limit`/`wait`) so there is no snake_case/
 * camelCase split to tolerate the way Ssh.keysOnly() handles keys_only/
 * keysOnly. The defensive coercion below (string-typed numerics, the
 * percentage form, and invalid shapes degrading to the defaults) covers the
 * real-world YAML variance instead.
 */
component {

	public any function init(struct raw = {}) {
		variables.raw = arguments.raw;
		return this;
	}

	public numeric function limit() {
		if (!structKeyExists(variables.raw, "limit")) return 10;
		return $coerceNumber(variables.raw.limit, 10);
	}

	/**
	 * Hosts per batch for a role with `hostCount` hosts: limit() as a count,
	 * or, for the percentage form, that share of hostCount rounded up. Never
	 * less than 1, so a batch always makes progress.
	 */
	public numeric function batchSize(required numeric hostCount) {
		var size = limit();
		if (structKeyExists(variables.raw, "limit") && isSimpleValue(variables.raw.limit) && right(trim(variables.raw.limit), 1) == "%") {
			size = ceiling(arguments.hostCount * size / 100);
		}
		return max(1, int(size));
	}

	public numeric function wait() {
		if (!structKeyExists(variables.raw, "wait")) return 5;
		return $coerceNumber(variables.raw.wait, 5);
	}

	/**
	 * Coerce a raw value to a non-negative count. Accepts numerics, numeric
	 * strings, and Kamal's percentage form ("25%" → 25); anything else
	 * returns the fallback so the accessor never throws on a malformed block.
	 */
	private numeric function $coerceNumber(required any value, required numeric fallback) {
		if (isNumeric(arguments.value)) return arguments.value;
		if (isSimpleValue(arguments.value)) {
			var s = trim(arguments.value);
			if (len(s) && right(s, 1) == "%") s = left(s, len(s) - 1);
			if (len(s) && isNumeric(s)) return s;
		}
		return arguments.fallback;
	}

}
