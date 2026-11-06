/**
 * Deterministic duration-weighted test shard planner.
 *
 * CI shards the core suite by asking each runner request for one slice:
 *
 *   /wheels/core/tests?format=json&shards=8&shard=3&shardWeights=<url-encoded JSON>
 *
 * `shardWeights` maps a discovered bundle name (dotted path, as reported in
 * `bundleStats[].name`; `bundlesDiscovered` is the count) to measured seconds.
 * The planner uses Longest Processing
 * Time first (LPT): bundles are sorted by weight descending (ties by bundle name
 * ascending) and each is placed on the currently lightest shard. That beats
 * round-robin partitioning on skewed suites, where a single hot bundle otherwise
 * lands on top of an already-full shard.
 *
 * Each shard still needs its own application instance and database. This
 * component only decides which bundles one request runs; it does not run
 * anything in parallel and does not make a shared database safe.
 */
component output="false" {

	/**
	 * Upper bound on shardCount, enforced here and by the runner. A request for
	 * an absurd number of shards must be rejected before allocating partitions.
	 */
	variables.MAX_SHARDS = 64;

	public ShardPlanner function init() {
		return this;
	}

	/**
	 * Partition bundles into `shardCount` weighted shards.
	 *
	 * @bundles     Bundle names (dotted paths); order is irrelevant.
	 * @shardCount  Number of shards, integer >= 1.
	 * @weights     Optional struct of bundle name -> measured seconds. Missing
	 *              bundles weigh 1. Non-numeric or negative weights throw.
	 * @return      { partitions: array of arrays, totals: array of numeric,
	 *                total: numeric, shardCount: numeric }
	 */
	public struct function plan(required array bundles, required numeric shardCount, struct weights = {}) {
		$validateShardCount(arguments.shardCount);

		local.entries = [];
		for (local.bundle in arguments.bundles) {
			local.weight = 1;
			if (StructKeyExists(arguments.weights, local.bundle)) {
				local.weight = arguments.weights[local.bundle];
				if (!IsNumeric(local.weight) || local.weight < 0) {
					throw(
						type = "Wheels.InvalidShard",
						message = "weight for bundle '#local.bundle#' must be a non-negative number"
					);
				}
				local.weight = Val(local.weight);
			}
			ArrayAppend(local.entries, {name = local.bundle, weight = local.weight});
		}

		// LPT: heaviest first, bundle name ascending on ties, then always place on
		// the currently lightest shard (lowest index wins a tie, so the output is
		// deterministic for a given input).
		ArraySort(local.entries, function(a, b) {
			if (a.weight != b.weight) {
				return a.weight > b.weight ? -1 : 1;
			}
			// Case-sensitive total order: CompareNoCase would both tie "a.X" and
			// "A.X" (leaving their relative order to the input) and disagree with
			// the runner's case-sensitive bundle names.
			return Compare(a.name, b.name);
		});

		local.partitions = [];
		local.totals = [];
		for (local.i = 1; local.i <= arguments.shardCount; local.i++) {
			ArrayAppend(local.partitions, []);
			ArrayAppend(local.totals, 0);
		}

		for (local.entry in local.entries) {
			local.target = 1;
			for (local.i = 2; local.i <= arguments.shardCount; local.i++) {
				if (local.totals[local.i] < local.totals[local.target]) {
					local.target = local.i;
				}
			}
			ArrayAppend(local.partitions[local.target], local.entry.name);
			local.totals[local.target] = local.totals[local.target] + local.entry.weight;
		}

		local.total = 0;
		for (local.t in local.totals) {
			local.total = local.total + local.t;
		}

		return {
			partitions = local.partitions,
			totals = local.totals,
			total = local.total,
			shardCount = arguments.shardCount
		};
	}

	/**
	 * Return one shard's bundle list (1-based shardIndex).
	 *
	 * @bundles     Bundle names (dotted paths).
	 * @shardCount  Number of shards, integer >= 1.
	 * @shardIndex  1-based shard index, <= shardCount.
	 * @weights     Optional bundle name -> seconds map (see plan()).
	 */
	public array function partition(
		required array bundles,
		required numeric shardCount,
		required numeric shardIndex,
		struct weights = {}
	) {
		$validateShardCount(arguments.shardCount);
		if (
			!IsNumeric(arguments.shardIndex)
			|| arguments.shardIndex < 1
			|| arguments.shardIndex != Int(arguments.shardIndex)
			|| arguments.shardIndex > arguments.shardCount
		) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shardIndex must be an integer between 1 and #arguments.shardCount#"
			);
		}
		local.plan = plan(
			bundles = arguments.bundles,
			shardCount = arguments.shardCount,
			weights = arguments.weights
		);
		return local.plan.partitions[Int(arguments.shardIndex)];
	}

	private void function $validateShardCount(required numeric shardCount) {
		if (
			!IsNumeric(arguments.shardCount)
			|| arguments.shardCount < 1
			|| arguments.shardCount != Int(arguments.shardCount)
		) {
			throw(type = "Wheels.InvalidShard", message = "shardCount must be a positive integer");
		}
		if (arguments.shardCount > variables.MAX_SHARDS) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shardCount must be between 1 and #variables.MAX_SHARDS#"
			);
		}
	}

}
