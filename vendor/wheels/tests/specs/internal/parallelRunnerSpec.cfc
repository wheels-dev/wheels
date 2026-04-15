component extends="wheels.WheelsTest" {

	function run() {

		describe("ParallelRunner", () => {

			beforeEach(() => {
				runner = new wheels.wheelstest.ParallelRunner(
					baseUrl = "http://localhost:8080",
					workers = 4
				);
			});

			describe("discoverBundles()", () => {

				it("finds Spec files in the core test directory", () => {
					var bundles = runner.discoverBundles(baseDirectory = "wheels.tests.specs");
					expect(bundles).toBeArray();
					expect(arrayLen(bundles)).toBeGT(0);
				});

				it("returns dotted paths ending with the bundle name", () => {
					var bundles = runner.discoverBundles(baseDirectory = "wheels.tests.specs");
					// Every path should start with the base directory
					for (var b in bundles) {
						expect(b).toInclude("wheels.tests.specs.");
					}
				});

				it("returns an empty array for a nonexistent directory", () => {
					var bundles = runner.discoverBundles(baseDirectory = "wheels.tests.specs.nonexistent_abc123");
					expect(bundles).toBeArray();
					expect(arrayLen(bundles)).toBe(0);
				});

				it("finds bundles in a subdirectory", () => {
					var bundles = runner.discoverBundles(baseDirectory = "wheels.tests.specs.model");
					expect(bundles).toBeArray();
					expect(arrayLen(bundles)).toBeGT(0);
					for (var b in bundles) {
						expect(b).toInclude("wheels.tests.specs.model.");
					}
				});

			});

			describe("partitionBundles()", () => {

				it("distributes bundles evenly via round-robin", () => {
					var bundles = ["a", "b", "c", "d", "e", "f"];
					var partitions = runner.partitionBundles(bundles = bundles, partitionCount = 3);

					expect(partitions).toBeArray();
					expect(arrayLen(partitions)).toBe(3);
					// Round-robin: [a,d], [b,e], [c,f]
					expect(partitions[1]).toBe(["a", "d"]);
					expect(partitions[2]).toBe(["b", "e"]);
					expect(partitions[3]).toBe(["c", "f"]);
				});

				it("handles fewer bundles than workers", () => {
					var bundles = ["a", "b"];
					var partitions = runner.partitionBundles(bundles = bundles, partitionCount = 5);

					// Should cap at 2 partitions since we only have 2 bundles
					expect(arrayLen(partitions)).toBe(2);
					expect(partitions[1]).toBe(["a"]);
					expect(partitions[2]).toBe(["b"]);
				});

				it("handles a single bundle", () => {
					var bundles = ["only"];
					var partitions = runner.partitionBundles(bundles = bundles, partitionCount = 4);

					expect(arrayLen(partitions)).toBe(1);
					expect(partitions[1]).toBe(["only"]);
				});

				it("handles an empty bundle list", () => {
					var bundles = [];
					var partitions = runner.partitionBundles(bundles = bundles, partitionCount = 4);

					expect(arrayLen(partitions)).toBe(0);
				});

				it("preserves all bundles across partitions", () => {
					var bundles = ["a", "b", "c", "d", "e", "f", "g"];
					var partitions = runner.partitionBundles(bundles = bundles, partitionCount = 3);

					var allBundles = [];
					for (var p in partitions) {
						for (var b in p) {
							arrayAppend(allBundles, b);
						}
					}
					arraySort(allBundles, "textNoCase");
					arraySort(bundles, "textNoCase");
					expect(allBundles).toBe(bundles);
				});

			});

			describe("aggregateResults()", () => {

				it("sums totals correctly from multiple partitions", () => {
					var partitionResults = [
						{
							success = true,
							data = {totalPass = 10, totalFail = 1, totalError = 0, totalSkipped = 2, totalDuration = 1000, bundleStats = []},
							error = "", duration = 1000, partition = 1, status = "COMPLETED"
						},
						{
							success = true,
							data = {totalPass = 20, totalFail = 0, totalError = 1, totalSkipped = 3, totalDuration = 2000, bundleStats = []},
							error = "", duration = 2000, partition = 2, status = "COMPLETED"
						}
					];

					var result = runner.aggregateResults(partitionResults = partitionResults);

					expect(result.totalPass).toBe(30);
					expect(result.totalFail).toBe(1);
					expect(result.totalError).toBe(1);
					expect(result.totalSkipped).toBe(5);
					expect(result.totalDuration).toBe(3000);
				});

				it("merges bundleStats arrays", () => {
					var partitionResults = [
						{
							success = true,
							data = {
								totalPass = 5, totalFail = 0, totalError = 0, totalSkipped = 0,
								totalDuration = 500,
								bundleStats = [{name = "BundleA", totalPass = 5, totalFail = 0, suiteStats = []}]
							},
							error = "", duration = 500, partition = 1, status = "COMPLETED"
						},
						{
							success = true,
							data = {
								totalPass = 3, totalFail = 0, totalError = 0, totalSkipped = 0,
								totalDuration = 300,
								bundleStats = [{name = "BundleB", totalPass = 3, totalFail = 0, suiteStats = []}]
							},
							error = "", duration = 300, partition = 2, status = "COMPLETED"
						}
					];

					var result = runner.aggregateResults(partitionResults = partitionResults);

					expect(arrayLen(result.bundleStats)).toBe(2);
					expect(result.bundleStats[1].name).toBe("BundleA");
					expect(result.bundleStats[2].name).toBe("BundleB");
				});

				it("collects failures from spec results", () => {
					var partitionResults = [
						{
							success = true,
							data = {
								totalPass = 5, totalFail = 1, totalError = 0, totalSkipped = 0,
								totalDuration = 500,
								bundleStats = [{
									name = "FailBundle",
									totalPass = 5, totalFail = 1,
									suiteStats = [{
										name = "Suite1",
										specStats = [
											{name = "passing test", status = "Passed", failMessage = ""},
											{name = "failing test", status = "Failed", failMessage = "expected true but got false"}
										],
										suiteStats = []
									}]
								}]
							},
							error = "", duration = 500, partition = 1, status = "COMPLETED"
						}
					];

					var result = runner.aggregateResults(partitionResults = partitionResults);

					expect(arrayLen(result.failures)).toBe(1);
					expect(result.failures[1].bundle).toBe("FailBundle");
					expect(result.failures[1].spec).toBe("failing test");
					expect(result.failures[1].status).toBe("Failed");
					expect(result.failures[1].message).toInclude("expected true");
				});

				it("records partition-level errors", () => {
					var partitionResults = [
						{
							success = true,
							data = {totalPass = 5, totalFail = 0, totalError = 0, totalSkipped = 0, totalDuration = 500, bundleStats = []},
							error = "", duration = 500, partition = 1, status = "COMPLETED"
						},
						{
							success = false,
							data = {},
							error = "HTTP 500: Internal Server Error", duration = 100, partition = 2, status = "COMPLETED"
						}
					];

					var result = runner.aggregateResults(partitionResults = partitionResults);

					expect(arrayLen(result.partitionErrors)).toBe(1);
					expect(result.partitionErrors[1].partition).toBe(2);
					expect(result.partitionErrors[1].error).toInclude("500");
					// Partition errors count toward totalError
					expect(result.totalError).toBe(1);
				});

				it("handles all partitions failing", () => {
					var partitionResults = [
						{success = false, data = {}, error = "timeout", duration = 600000, partition = 1, status = "COMPLETED"},
						{success = false, data = {}, error = "timeout", duration = 600000, partition = 2, status = "COMPLETED"}
					];

					var result = runner.aggregateResults(partitionResults = partitionResults);

					expect(result.totalPass).toBe(0);
					expect(result.totalError).toBe(2);
					expect(arrayLen(result.partitionErrors)).toBe(2);
				});

			});

			describe("formatReport()", () => {

				it("produces readable text output for passing results", () => {
					var results = {
						totalPass = 100, totalFail = 0, totalError = 0, totalSkipped = 5,
						totalDuration = 5000, bundleStats = [], failures = [],
						partitionErrors = [], workers = 4, partitions = 4, wallTime = 2000
					};

					var report = runner.formatReport(results = results, format = "text");

					expect(report).toInclude("Parallel Test Results");
					expect(report).toInclude("Workers: 4");
					expect(report).toInclude("Passed: 100");
					expect(report).toInclude("RESULT: PASSED");
				});

				it("includes failure details in text output", () => {
					var results = {
						totalPass = 90, totalFail = 2, totalError = 0, totalSkipped = 0,
						totalDuration = 5000, bundleStats = [],
						failures = [
							{bundle = "MyBundle", spec = "my test", status = "Failed", message = "assertion failed"}
						],
						partitionErrors = [], workers = 4, partitions = 4, wallTime = 2000
					};

					var report = runner.formatReport(results = results, format = "text");

					expect(report).toInclude("Failures");
					expect(report).toInclude("MyBundle");
					expect(report).toInclude("assertion failed");
					expect(report).toInclude("RESULT: FAILED");
				});

				it("produces valid JSON output", () => {
					var results = {
						totalPass = 50, totalFail = 0, totalError = 0, totalSkipped = 0,
						totalDuration = 2000, bundleStats = [], failures = [],
						partitionErrors = [], workers = 2, partitions = 2, wallTime = 1200
					};

					var report = runner.formatReport(results = results, format = "json");
					var parsed = deserializeJSON(report);

					expect(parsed.totalPass).toBe(50);
					expect(parsed.workers).toBe(2);
				});

			});

		});

	}

}
