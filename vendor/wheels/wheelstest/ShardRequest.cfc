/**
 * Parses and validates the shared shard request contract used by both test
 * runners (`vendor/wheels/tests/runner.cfm` and `tests/app-runner.cfm`):
 *
 *   ?shards=N&shard=K
 *   ?shardWeights=<url-encoded JSON>     (small scopes; encoded cap 6000)
 *   ?shardWeightsFile=1                  (tests/shard-weights.json)
 *
 * Throws `Wheels.InvalidShard` with a caller-facing message; the runners turn
 * that into HTTP 400 JSON. Keeping the rules here means the core and app
 * runners cannot drift (#4689 follow-up).
 */
component output="false" {

	variables.MAX_SHARDS = 64;
	variables.MAX_URL_WEIGHTS = 6000;
	variables.MAX_WEIGHTS_FILE_BYTES = 131072;

	/**
	 * @url          The request's `url` scope.
	 * @weightsPath  Optional override for the fixed weights-file location
	 *               (tests use a temp file; production callers omit it).
	 * @return       {requested, shardCount, shardIndex, weights}
	 */
	public struct function parse(required struct url, string weightsPath = "") {
		local.rv = {
			requested = false,
			shardCount = 1,
			shardIndex = 1,
			weights = {}
		};
		local.params = $collectParams(url = arguments.url);
		if (!StructCount(local.params)) {
			return local.rv;
		}
		local.rv.requested = true;
		local.rv.shardCount = $parseShardCount(params = local.params);
		local.rv.shardIndex = $parseShardIndex(params = local.params, shardCount = local.rv.shardCount);
		local.rv.weights = $parseWeights(
			params = local.params,
			shardCount = local.rv.shardCount,
			weightsPath = arguments.weightsPath
		);
		return local.rv;
	}

	/** Collect only single, simple query parameters; duplicates are a 400. */
	private struct function $collectParams(required struct url) {
		local.params = {};
		for (local.key in ["shards", "shard", "shardWeights", "shardWeightsFile"]) {
			if (StructKeyExists(arguments.url, local.key)) {
				if (!IsSimpleValue(arguments.url[local.key])) {
					throw(type = "Wheels.InvalidShard", message = "#local.key# must be a single value");
				}
				local.params[local.key] = arguments.url[local.key];
			}
		}
		return local.params;
	}

	private numeric function $parseShardCount(required struct params) {
		if (!StructKeyExists(arguments.params, "shards")) {
			return 1;
		}
		local.raw = arguments.params.shards;
		if (!IsNumeric(local.raw) || Val(local.raw) < 1 || Val(local.raw) != Int(Val(local.raw))) {
			throw(type = "Wheels.InvalidShard", message = "shards must be a positive integer");
		}
		local.count = Int(Val(local.raw));
		if (local.count > variables.MAX_SHARDS) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shards must be between 1 and #variables.MAX_SHARDS#"
			);
		}
		return local.count;
	}

	private numeric function $parseShardIndex(required struct params, required numeric shardCount) {
		if (!StructKeyExists(arguments.params, "shard")) {
			return 1;
		}
		local.raw = arguments.params.shard;
		if (
			!IsNumeric(local.raw)
			|| Val(local.raw) < 1
			|| Val(local.raw) != Int(Val(local.raw))
			|| Val(local.raw) > arguments.shardCount
		) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shard must be an integer between 1 and #arguments.shardCount#"
			);
		}
		return Int(Val(local.raw));
	}

	/** Resolve and validate the optional weights (inline JSON or fixed file). */
	private struct function $parseWeights(
		required struct params,
		required numeric shardCount,
		required string weightsPath
	) {
		local.hasInline = StructKeyExists(arguments.params, "shardWeights");
		local.hasFile = $parseFileFlag(params = arguments.params);
		if (local.hasInline && local.hasFile) {
			throw(
				type = "Wheels.InvalidShard",
				message = "use either shardWeights or shardWeightsFile, not both"
			);
		}
		if (!local.hasInline && !local.hasFile) {
			return {};
		}
		// Weights only make sense when actually sharding; validate them even when
		// shards is absent/1 so bad input never runs a full suite.
		if (arguments.shardCount <= 1) {
			throw(type = "Wheels.InvalidShard", message = "shard weights require shards > 1");
		}
		local.raw = local.hasInline
			? $inlineWeights(params = arguments.params)
			: $fileWeights(weightsPath = arguments.weightsPath);
		return $validateWeights(raw = local.raw);
	}

	/** Literal truthy flag only; 0/false/yes/on are a 400, never silently absent. */
	private boolean function $parseFileFlag(required struct params) {
		if (!StructKeyExists(arguments.params, "shardWeightsFile")) {
			return false;
		}
		if (!ListFindNoCase("1,true", arguments.params.shardWeightsFile)) {
			throw(type = "Wheels.InvalidShard", message = "shardWeightsFile accepts only 1 or true");
		}
		return true;
	}

	/** Inline weights: the cap applies to the ENCODED value (request-line fit). */
	private string function $inlineWeights(required struct params) {
		local.encodedLength = Len(URLEncodedFormat(arguments.params.shardWeights));
		if (local.encodedLength > variables.MAX_URL_WEIGHTS) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shardWeights in the query string is limited to #variables.MAX_URL_WEIGHTS# characters once URL-encoded (got #local.encodedLength#); use shardWeightsFile=1 for the full suite"
			);
		}
		return arguments.params.shardWeights;
	}

	/** File weights: fixed app-root path, size-capped, never caller-chosen. */
	private string function $fileWeights(required string weightsPath) {
		local.path = Len(arguments.weightsPath) ? arguments.weightsPath : ExpandPath("/tests/shard-weights.json");
		if (!FileExists(local.path)) {
			throw(
				type = "Wheels.InvalidShard",
				message = "tests/shard-weights.json was not found in the app root"
			);
		}
		local.content = FileRead(local.path);
		if (Len(local.content) > variables.MAX_WEIGHTS_FILE_BYTES) {
			throw(
				type = "Wheels.InvalidShard",
				message = "tests/shard-weights.json must be at most #variables.MAX_WEIGHTS_FILE_BYTES# bytes"
			);
		}
		return local.content;
	}

	/** Parse the JSON and require an object of bundle name -> non-negative number. */
	private struct function $validateWeights(required string raw) {
		try {
			local.weights = DeserializeJSON(arguments.raw);
		} catch (any e) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shard weights must be a JSON object of bundle name to seconds"
			);
		}
		if (!IsStruct(local.weights)) {
			throw(
				type = "Wheels.InvalidShard",
				message = "shard weights must be a JSON object of bundle name to seconds"
			);
		}
		for (local.bundleName in local.weights) {
			if (!IsNumeric(local.weights[local.bundleName]) || local.weights[local.bundleName] < 0) {
				throw(
					type = "Wheels.InvalidShard",
					message = "weight for bundle '#local.bundleName#' must be a non-negative number"
				);
			}
		}
		return local.weights;
	}

}
