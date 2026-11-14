/**
 * The app runner (/wheels/app/tests) must use the same shard contract as the
 * core runner. The parser/planner behavior is covered by shardRequestSpec and
 * shardPlannerSpec; this pins that app-runner.cfm actually wires them and
 * reports the shard metadata (#4689 follow-up).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("app runner shard contract (##4689)", () => {

			it("uses ShardRequest and ShardPlanner and reports selection metadata", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				expect(Find("wheels.wheelstest.ShardRequest", source)).toBeGT(0);
				expect(Find("wheels.wheelstest.ShardPlanner", source)).toBeGT(0);
				expect(Find("Invalid shard parameters", source)).toBeGT(0);
				expect(Find("bundlesSelected", source)).toBeGT(0);
				expect(Find("shardCount", source)).toBeGT(0);
				expect(Find("shardIndex", source)).toBeGT(0);
			});

			it("selects before setBundles and counts discovered bundles first", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				expect(Find("local.bundlesDiscovered = ArrayLen(local.sortedBundles)", source)).toBeGT(0);
				expect(Find("local.sortedBundles = local.shardPlanner.partition", source)).toBeGT(0);
				expect(Find("testBox.setBundles(local.sortedBundles)", source)).toBeGT(0);
				expect(Find("local.bundlesDiscovered = ArrayLen(local.sortedBundles)", source))
					.toBeLT(Find("testBox.setBundles(local.sortedBundles)", source));
			});

		});

	}

}
