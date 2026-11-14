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
		local.params = {};
		// Each key must be a single simple value: a duplicated query parameter
		// arrives as an array and must 400, not 500.
		for (local.key in ["shards", "shard", "shardWeights", "shardWeightsFile"]) {
			if (StructKeyExists(arguments.url, local.key)) {
				if (!IsSimpleValue(arguments.url[local.key])) {
					throw(type = "Wheels.InvalidShard", message = "#local.key# must be a single value");
				}
				local.params[local.key] = arguments.url[local.key];
				local.rv.requested = true;
			}
		}
		if (!local.rv.requested) {
			return local.rv;
		}

		if (StructKeyExists(local.params, "shards")) {
			local.rawShards = local.params.shards;
			if (
				!IsNumeric(local.rawShards)
				|| Val(local.rawShards) < 1
				|| Val(local.rawShards) != Int(Val(local.rawShards))
			) {
				throw(type = "Wheels.InvalidShard", message = "shards must be a positive integer");
			}
			local.rv.shardCount = Int(Val(local.rawShards));
			if (local.rv.shardCount > variables.MAX_SHARDS) {
				throw(
					type = "Wheels.InvalidShard",
					message = "shards must be between 1 and #variables.MAX_SHARDS#"
				);
			}
		}
		if (StructKeyExists(local.params, "shard")) {
			if (
				!IsNumeric(local.params.shard)
				|| Val(local.params.shard) < 1
				|| Val(local.params.shard) != Int(Val(local.params.shard))
				|| Val(local.params.shard) > local.rv.shardCount
			) {
				throw(
					type = "Wheels.InvalidShard",
					message = "shard must be an integer between 1 and #local.rv.shardCount#"
				);
			}
			local.rv.shardIndex = Int(Val(local.params.shard));
		}

		local.hasInlineWeights = StructKeyExists(local.params, "shardWeights");
		local.hasFileWeights = false;
		if (StructKeyExists(local.params, "shardWeightsFile")) {
			// Literal truthy flag only; 0/false/yes/on are a 400 rather than a
			// silent no-op that would shard with default weights.
			if (!ListFindNoCase("1,true", local.params.shardWeightsFile)) {
				throw(type = "Wheels.InvalidShard", message = "shardWeightsFile accepts only 1 or true");
			}
			local.hasFileWeights = true;
		}
		if (local.hasInlineWeights && local.hasFileWeights) {
			throw(
				type = "Wheels.InvalidShard",
				message = "use either shardWeights or shardWeightsFile, not both"
			);
		}
		if (local.hasInlineWeights || local.hasFileWeights) {
			// Weights only make sense when actually sharding; validate them even
			// when shards is absent/1 so bad input never runs a full suite.
			if (local.rv.shardCount <= 1) {
				throw(type = "Wheels.InvalidShard", message = "shard weights require shards > 1");
			}
			if (local.hasInlineWeights) {
				// The cap applies to the ENCODED value: that is what must fit in
				// the request line (~8 KB on Adobe). Re-encode the decoded value
				// so a long JSON payload cannot slip through by decoding short.
				local.encodedWeightsLength = Len(URLEncodedFormat(local.params.shardWeights));
				if (local.encodedWeightsLength > variables.MAX_URL_WEIGHTS) {
					throw(
						type = "Wheels.InvalidShard",
						message = "shardWeights in the query string is limited to #variables.MAX_URL_WEIGHTS# characters once URL-encoded (got #local.encodedWeightsLength#); use shardWeightsFile=1 for the full suite"
					);
				}
				local.rawWeights = local.params.shardWeights;
			} else {
				// Fixed location under the app's tests directory: the caller
				// cannot point this at an arbitrary path.
				local.weightsPath = Len(arguments.weightsPath)
					? arguments.weightsPath
					: ExpandPath("/tests/shard-weights.json");
				if (!FileExists(local.weightsPath)) {
					throw(
						type = "Wheels.InvalidShard",
						message = "tests/shard-weights.json was not found in the app root"
					);
				}
				if (FileInfo(local.weightsPath).size > variables.MAX_WEIGHTS_FILE_BYTES) {
					throw(
						type = "Wheels.InvalidShard",
						message = "tests/shard-weights.json must be at most #variables.MAX_WEIGHTS_FILE_BYTES# bytes"
					);
				}
				local.rawWeights = FileRead(local.weightsPath);
			}
			if (IsSimpleValue(local.rawWeights)) {
				try {
					local.rawWeights = DeserializeJSON(local.rawWeights);
				} catch (any e) {
					throw(
						type = "Wheels.InvalidShard",
						message = "shard weights must be a JSON object of bundle name to seconds"
					);
				}
			}
			if (!IsStruct(local.rawWeights)) {
				throw(
					type = "Wheels.InvalidShard",
					message = "shard weights must be a JSON object of bundle name to seconds"
				);
			}
			local.rv.weights = local.rawWeights;
			for (local.bundleName in local.rv.weights) {
				if (!IsNumeric(local.rv.weights[local.bundleName]) || local.rv.weights[local.bundleName] < 0) {
					throw(
						type = "Wheels.InvalidShard",
						message = "weight for bundle '#local.bundleName#' must be a non-negative number"
					);
				}
			}
		}
		return local.rv;
	}

}
