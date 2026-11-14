/**
 * Shared shard request contract (#4689 follow-up): both test runners use
 * wheels.wheelstest.ShardRequest so validation cannot drift between the core
 * (/wheels/core/tests) and app (/wheels/app/tests) runners.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("ShardRequest (##4689)", () => {

			beforeEach(() => {
				shardRequest = new wheels.wheelstest.ShardRequest();
			});

			it("leaves absent shard params unchanged", () => {
				var rv = shardRequest.parse(url = {});
				expect(rv.requested).toBeFalse();
				expect(rv.shardCount).toBe(1);
				expect(rv.shardIndex).toBe(1);
				expect(rv.weights).toBe({});
			});

			it("parses shards/shard", () => {
				var rv = shardRequest.parse(url = {shards = "3", shard = "2"});
				expect(rv.requested).toBeTrue();
				expect(rv.shardCount).toBe(3);
				expect(rv.shardIndex).toBe(2);
			});

			it("rejects invalid shard counts and indexes", () => {
				expect(function() { shardRequest.parse(url = {shards = "0"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "65"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "abc"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "1.5"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "2", shard = "0"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "2", shard = "3"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "2", shard = "1.5"}); }).toThrow("Wheels.InvalidShard");
			});

			it("rejects duplicated query parameters (arrays) instead of 500ing", () => {
				expect(function() {
					shardRequest.parse(url = {shards = ["2", "3"]});
				}).toThrow("Wheels.InvalidShard");
			});

			it("validates inline weights only with shards > 1", () => {
				expect(function() {
					shardRequest.parse(url = {shards = "1", shardWeights = '{"a":1}'});
				}).toThrow("Wheels.InvalidShard");
				expect(function() {
					shardRequest.parse(url = {shards = "2", shardWeights = '{"a":"slow"}'});
				}).toThrow("Wheels.InvalidShard");
				expect(function() {
					shardRequest.parse(url = {shards = "2", shardWeights = '{"a":-1}'});
				}).toThrow("Wheels.InvalidShard");
				var good = shardRequest.parse(url = {shards = "2", shardWeights = '{"a":2}'});
				expect(good.weights.a).toBe(2);
			});

			it("caps inline weights by their ENCODED length", () => {
				var huge = "{" & RepeatString(" ", 7000) & "}";
				expect(function() {
					shardRequest.parse(url = {shards = "2", shardWeights = huge});
				}).toThrow("Wheels.InvalidShard");
			});

			it("reads the fixed weights file, and validates its shape and size", () => {
				var path = GetTempDirectory() & "shard-weights-#CreateUUID()#.json";
				try {
					FileWrite(path, '{"a":3,"b":1}');
					var good = shardRequest.parse(url = {shards = "2", shardWeightsFile = "1"}, weightsPath = path);
					expect(good.weights.a).toBe(3);

					expect(function() {
						shardRequest.parse(url = {shards = "2", shardWeightsFile = "1"}, weightsPath = path & ".missing");
					}).toThrow("Wheels.InvalidShard");

					FileWrite(path, 'not json');
					expect(function() {
						shardRequest.parse(url = {shards = "2", shardWeightsFile = "1"}, weightsPath = path);
					}).toThrow("Wheels.InvalidShard");

					FileWrite(path, '{"a":-1}');
					expect(function() {
						shardRequest.parse(url = {shards = "2", shardWeightsFile = "1"}, weightsPath = path);
					}).toThrow("Wheels.InvalidShard");
				} finally {
					if (FileExists(path)) {
						FileDelete(path);
					}
				}
			});

			it("accepts only the literal truthy shardWeightsFile flag", () => {
				expect(function() { shardRequest.parse(url = {shards = "2", shardWeightsFile = "0"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "2", shardWeightsFile = "false"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "2", shardWeightsFile = "yes"}); }).toThrow("Wheels.InvalidShard");
				expect(function() { shardRequest.parse(url = {shards = "2", shardWeightsFile = "on"}); }).toThrow("Wheels.InvalidShard");
			});

			it("rejects inline and file weights together", () => {
				expect(function() {
					shardRequest.parse(url = {shards = "2", shardWeights = '{"a":1}', shardWeightsFile = "1"});
				}).toThrow("Wheels.InvalidShard");
			});

		});

	}

}
