/**
 * Weighted test shard planner (#4629 prototype).
 *
 * LPT = longest processing time first: bundles by measured weight descending,
 * then each bundle on the lightest shard. These specs pin the deterministic
 * contract CI relies on: every bundle exactly once, stable output, and less
 * imbalance than round-robin on a skewed suite.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("ShardPlanner (##4629)", () => {

			beforeEach(() => {
				planner = new wheels.wheelstest.ShardPlanner();
			});

			it("puts every bundle in exactly one shard", () => {
				var bundles = ["a.OneSpec", "a.TwoSpec", "b.ThreeSpec", "c.FourSpec", "d.FiveSpec"];
				var plan = planner.plan(bundles = bundles, shardCount = 3);
				var seen = [];
				for (var shard in plan.partitions) {
					for (var bundle in shard) {
						ArrayAppend(seen, bundle);
					}
				}
				expect(ArrayLen(seen)).toBe(ArrayLen(bundles));
				for (var bundle in bundles) {
					expect(ArrayFind(seen, bundle)).toBeGT(0, "missing #bundle#");
				}
				// no duplicates
				var counts = {};
				for (var bundle in seen) {
					counts[bundle] = (StructKeyExists(counts, bundle) ? counts[bundle] : 0) + 1;
				}
				for (var bundle in counts) {
					expect(counts[bundle]).toBe(1, "duplicate #bundle#");
				}
			});

			it("is deterministic for a given input", () => {
				var bundles = ["x.A", "x.B", "x.C", "x.D", "x.E", "x.F"];
				var weights = {"x.A" = 10, "x.C" = 7, "x.F" = 3};
				var first = planner.plan(bundles = bundles, shardCount = 3, weights = weights);
				var reversed = [];
				for (var i = ArrayLen(bundles); i >= 1; i--) {
					ArrayAppend(reversed, bundles[i]);
				}
				var second = planner.plan(bundles = reversed, shardCount = 3, weights = weights);
				expect(first.partitions).toBe(second.partitions);
				expect(first.totals).toBe(second.totals);
			});

			it("defaults missing weights to 1 and keeps ties name-ascending", () => {
				var plan = planner.plan(bundles = ["b.SecondSpec", "a.FirstSpec", "c.ThirdSpec"], shardCount = 3);
				expect(plan.totals).toBe([1, 1, 1]);
				expect(plan.partitions[1]).toBe(["a.FirstSpec"]);
				expect(plan.partitions[2]).toBe(["b.SecondSpec"]);
				expect(plan.partitions[3]).toBe(["c.ThirdSpec"]);
			});

			it("leaves extra shards empty when there are fewer bundles than shards", () => {
				var plan = planner.plan(bundles = ["a.A", "b.B"], shardCount = 4);
				expect(ArrayLen(plan.partitions)).toBe(4);
				expect(plan.partitions[1]).toBe(["a.A"]);
				expect(plan.partitions[2]).toBe(["b.B"]);
				expect(ArrayLen(plan.partitions[3])).toBe(0);
				expect(ArrayLen(plan.partitions[4])).toBe(0);
			});

			it("handles an empty bundle list", () => {
				var plan = planner.plan(bundles = [], shardCount = 3);
				expect(ArrayLen(plan.partitions)).toBe(3);
				expect(plan.total).toBe(0);
				expect(planner.partition(bundles = [], shardCount = 3, shardIndex = 2)).toBe([]);
			});

			it("rejects a zero shard count", () => {
				expect(function() {
					planner.plan(bundles = ["a.A"], shardCount = 0);
				}).toThrow("Wheels.InvalidShard");
			});

			it("rejects a negative shard count", () => {
				expect(function() {
					planner.partition(bundles = ["a.A"], shardCount = -1, shardIndex = 1);
				}).toThrow("Wheels.InvalidShard");
			});

			it("rejects a fractional shard count", () => {
				expect(function() {
					planner.plan(bundles = ["a.A"], shardCount = 1.5);
				}).toThrow("Wheels.InvalidShard");
			});

			it("rejects an out-of-range or fractional shard index", () => {
				expect(function() {
					planner.partition(bundles = ["a.A", "b.B"], shardCount = 2, shardIndex = 0);
				}).toThrow("Wheels.InvalidShard");
				expect(function() {
					planner.partition(bundles = ["a.A", "b.B"], shardCount = 2, shardIndex = 3);
				}).toThrow("Wheels.InvalidShard");
				expect(function() {
					planner.partition(bundles = ["a.A", "b.B"], shardCount = 2, shardIndex = 1.5);
				}).toThrow("Wheels.InvalidShard");
			});

			it("rejects non-numeric and negative weights", () => {
				expect(function() {
					planner.plan(bundles = ["a.A"], shardCount = 2, weights = {"a.A" = "slow"});
				}).toThrow("Wheels.InvalidShard");
				expect(function() {
					planner.plan(bundles = ["a.A"], shardCount = 2, weights = {"a.A" = -5});
				}).toThrow("Wheels.InvalidShard");
			});

			it("caps the shard count at 64", () => {
				var plan = planner.plan(bundles = ["a.A"], shardCount = 64);
				expect(ArrayLen(plan.partitions)).toBe(64);
				expect(function() {
					planner.plan(bundles = ["a.A"], shardCount = 65);
				}).toThrow("Wheels.InvalidShard");
				expect(function() {
					planner.partition(bundles = ["a.A"], shardCount = 65, shardIndex = 1);
				}).toThrow("Wheels.InvalidShard");
			});

			it("breaks case-only name ties with a deterministic case-sensitive order", () => {
				var bundles = ["b.Spec", "B.Spec", "a.Spec"];
				var forward = planner.plan(bundles = bundles, shardCount = 3);
				var reversed = [];
				for (var i = ArrayLen(bundles); i >= 1; i--) {
					ArrayAppend(reversed, bundles[i]);
				}
				var backward = planner.plan(bundles = reversed, shardCount = 3);
				// Case-sensitive Compare: "B.Spec" < "a.Spec" < "b.Spec".
				expect(forward.partitions[1]).toBe(["B.Spec"]);
				expect(forward.partitions[2]).toBe(["a.Spec"]);
				expect(forward.partitions[3]).toBe(["b.Spec"]);
				expect(forward.partitions).toBe(backward.partitions);
			});

			it("reduces the slowest shard vs round-robin on the PMX skew (##4629)", () => {
				// Weights from the 2026-11-06 PMX artifact (bundleStats.totalDuration).
				var bundles = [
					"pmx.VentasSpec",
					"pmx.PortalSecondFactorConcurrencySpec",
					"pmx.ReciboSpec",
					"pmx.CfdiPedimentosSpec",
					"pmx.VentasEmbarqueSpec",
					"pmx.VentasPedidoDetailSpec",
					"pmx.GunPackSpec",
					"pmx.GunPickSpec"
				];
				var weights = {
					"pmx.VentasSpec" = 101.6,
					"pmx.PortalSecondFactorConcurrencySpec" = 35.7,
					"pmx.ReciboSpec" = 32.7,
					"pmx.CfdiPedimentosSpec" = 26.8,
					"pmx.VentasEmbarqueSpec" = 26.0,
					"pmx.VentasPedidoDetailSpec" = 23.9,
					"pmx.GunPackSpec" = 21.7,
					"pmx.GunPickSpec" = 21.0
				};

				var lpt = planner.plan(bundles = bundles, shardCount = 3, weights = weights);
				var roundRobin = $roundRobinTotals(bundles = bundles, weights = weights, shardCount = 3);

				var lptMax = 0;
				for (var total in lpt.totals) {
					lptMax = Max(lptMax, total);
				}
				var rrMax = 0;
				for (var total in roundRobin) {
					rrMax = Max(rrMax, total);
				}

				// 3 shards: LPT max 104.4s vs round-robin max 150.1s (~30% lower).
				expect(Round(lptMax * 10) / 10).toBe(104.4);
				expect(Round(rrMax * 10) / 10).toBe(150.1);
				expect(lptMax).toBeLT(rrMax);
			});

			it("partitions with a 1-based shard index and no overlap", () => {
				var bundles = ["a.A", "b.B", "c.C", "d.D"];
				var first = planner.partition(bundles = bundles, shardCount = 2, shardIndex = 1);
				var second = planner.partition(bundles = bundles, shardCount = 2, shardIndex = 2);
				for (var bundle in first) {
					expect(ArrayFind(second, bundle)).toBe(0);
				}
				expect(ArrayLen(first) + ArrayLen(second)).toBe(4);
			});

		});

	}

	/** Simple round-robin over the input order, for the imbalance comparison. */
	private array function $roundRobinTotals(required array bundles, required struct weights, required numeric shardCount) {
		var totals = [];
		for (var i = 1; i <= arguments.shardCount; i++) {
			ArrayAppend(totals, 0);
		}
		for (var i = 1; i <= ArrayLen(arguments.bundles); i++) {
			var bundle = arguments.bundles[i];
			var weight = StructKeyExists(arguments.weights, bundle) ? arguments.weights[bundle] : 1;
			var target = ((i - 1) MOD arguments.shardCount) + 1;
			totals[target] = totals[target] + weight;
		}
		return totals;
	}

}
