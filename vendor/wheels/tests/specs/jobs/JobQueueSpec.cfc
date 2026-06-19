/**
 * Tests for the Wheels Job Queue system.
 * Tests job configuration, enqueueing, processing, retry logic, and queue management.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job Base Class", function() {

			it("can be instantiated", function() {
				local.job = new wheels.Job();
				expect(local.job).toBeInstanceOf("wheels.Job");
			});

			it("has default configuration values", function() {
				local.job = new wheels.Job();
				expect(local.job.queue).toBe("default");
				expect(local.job.priority).toBe(0);
				expect(local.job.maxRetries).toBe(3);
				expect(local.job.timeout).toBe(300);
				expect(local.job.baseDelay).toBe(2);
				expect(local.job.maxDelay).toBe(3600);
			});

			it("throws NotImplemented when perform() is called on base class", function() {
				var job = new wheels.Job();
				expect(function() {
					job.perform();
				}).toThrow(type = "Wheels.NotImplemented");
			});
		});

		describe("Job Enqueue Methods", function() {

			it("enqueue returns a job struct with id and status", function() {
				local.job = new wheels.Job();
				// Override perform to prevent NotImplemented error
				prepareMock(local.job);
				local.result = local.job.enqueue(data = {test: true});

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
				expect(local.result).toHaveKey("status");
				expect(local.result.status).toBe("pending");
			});

			it("enqueue accepts custom queue name", function() {
				local.job = new wheels.Job();
				prepareMock(local.job);
				local.result = local.job.enqueue(data = {}, queue = "high_priority");

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
			});

			it("enqueue accepts custom priority", function() {
				local.job = new wheels.Job();
				prepareMock(local.job);
				local.result = local.job.enqueue(data = {}, priority = 10);

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
			});

			it("enqueueIn accepts seconds delay", function() {
				local.job = new wheels.Job();
				prepareMock(local.job);
				local.result = local.job.enqueueIn(seconds = 60, data = {delayed: true});

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
				expect(local.result.status).toBe("pending");
			});

			it("enqueueAt accepts a specific datetime", function() {
				local.job = new wheels.Job();
				prepareMock(local.job);
				local.futureDate = DateAdd("h", 1, Now());
				local.result = local.job.enqueueAt(runAt = local.futureDate, data = {scheduled: true});

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
				expect(local.result.status).toBe("pending");
			});
		});

		describe("Job Configuration Override", function() {

			it("subclass can override default configuration", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				expect(local.job.queue).toBe("default");
				expect(local.job.maxRetries).toBe(3);
			});
		});

		describe("Queue Stats", function() {

			it("queueStats returns a struct with status counts", function() {
				local.job = new wheels.Job();
				local.stats = local.job.queueStats();

				expect(local.stats).toBeStruct();
				expect(local.stats).toHaveKey("pending");
				expect(local.stats).toHaveKey("processing");
				expect(local.stats).toHaveKey("completed");
				expect(local.stats).toHaveKey("failed");
				expect(local.stats).toHaveKey("total");
			});

			it("queueStats accepts queue filter", function() {
				local.job = new wheels.Job();
				local.stats = local.job.queueStats(queue = "default");

				expect(local.stats).toBeStruct();
				expect(local.stats).toHaveKey("total");
			});
		});

		describe("Queue Management", function() {

			it("retryFailed returns a numeric count", function() {
				local.job = new wheels.Job();
				local.count = local.job.retryFailed();
				expect(local.count).toBeNumeric();
			});

			it("purgeCompleted returns a numeric count", function() {
				local.job = new wheels.Job();
				local.count = local.job.purgeCompleted(days = 7);
				expect(local.count).toBeNumeric();
			});

			it("purgeCompleted accepts custom days parameter", function() {
				local.job = new wheels.Job();
				local.count = local.job.purgeCompleted(days = 30);
				expect(local.count).toBeNumeric();
			});
		});

		describe("Job Processing", function() {

			it("processQueue returns a result struct", function() {
				local.job = new wheels.Job();
				local.result = local.job.processQueue();

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("processed");
				expect(local.result).toHaveKey("failed");
				expect(local.result).toHaveKey("skipped");
				expect(local.result).toHaveKey("errors");
			});

			it("processQueue accepts queue filter", function() {
				local.job = new wheels.Job();
				local.result = local.job.processQueue(queue = "default");

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("processed");
			});

			it("processQueue accepts limit parameter", function() {
				local.job = new wheels.Job();
				local.result = local.job.processQueue(limit = 5);

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("processed");
			});
		});

		describe("Job Claim Guard", function() {

			beforeEach(function() {
				// Clean up any leftover test jobs from prior runs
				try { queryExecute("DELETE FROM wheels_jobs WHERE queue = 'test_claim_guard'", {}, {datasource = application.wheels.dataSourceName}); }
				catch (any e) { /* table may not exist */ }
			});

			afterEach(function() {
				try { queryExecute("DELETE FROM wheels_jobs WHERE queue = 'test_claim_guard'", {}, {datasource = application.wheels.dataSourceName}); }
				catch (any e) { /* table may not exist */ }
			});

			it("does not execute a job already claimed by another worker", function() {
				// Enqueue using a concrete subclass so jobClass resolves correctly
				local.testJob = new app.jobs.ProcessOrdersJob();
				local.enqueued = local.testJob.enqueue(data = {}, queue = "test_claim_guard");
				expect(local.enqueued).toHaveKey("persisted");
				expect(local.enqueued.persisted).toBeTrue();

				// Simulate a concurrent worker having already claimed the job
				queryExecute(
					"UPDATE wheels_jobs SET status = 'processing' WHERE id = :id",
					{id = {value = local.enqueued.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);

				// Build the job row as processQueue's SELECT would have seen it pre-claim
				local.jobRow = {
					id = local.enqueued.id,
					jobClass = "app.jobs.ProcessOrdersJob",
					queue = "test_claim_guard",
					data = "{}",
					attempts = 0,
					maxRetries = 3
				};

				local.job = new wheels.Job();
				prepareMock(local.job);
				makePublic(local.job, "$processJob");
				local.jobResult = local.job.$processJob(jobRow = local.jobRow);

				// The lost claim must be reported as skipped, not executed
				expect(local.jobResult).toHaveKey("skipped");
				expect(local.jobResult.skipped).toBeTrue();
				expect(local.jobResult.success).toBeFalse();

				// The already-claimed row must be untouched: still processing, attempts not incremented
				local.row = queryExecute(
					"SELECT status, attempts FROM wheels_jobs WHERE id = :id",
					{id = {value = local.enqueued.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(local.row.status).toBe("processing");
				expect(local.row.attempts).toBe(0);
			});
		});

		describe("Job Data Serialization", function() {

			it("enqueue handles complex data structures", function() {
				local.job = new wheels.Job();
				prepareMock(local.job);
				local.complexData = {
					name: "Test Job",
					items: [1, 2, 3],
					nested: {
						key: "value",
						active: true
					}
				};
				local.result = local.job.enqueue(data = local.complexData);

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
			});

			it("enqueue handles empty data", function() {
				local.job = new wheels.Job();
				prepareMock(local.job);
				local.result = local.job.enqueue(data = {});

				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
			});
		});

		describe("Example Job (ProcessOrdersJob)", function() {

			it("can be instantiated", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				expect(local.job).toBeInstanceOf("wheels.Job");
			});

			it("has a perform method", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				expect(local.job).toHaveKey("perform");
			});

			it("perform executes without error", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				// Should not throw
				local.job.perform(data = {batchSize: 5});
			});

			it("can be enqueued", function() {
				local.job = new app.jobs.ProcessOrdersJob();
				local.result = local.job.enqueue(data = {batchSize: 10});
				expect(local.result).toBeStruct();
				expect(local.result).toHaveKey("id");
			});
		});
	}
}
