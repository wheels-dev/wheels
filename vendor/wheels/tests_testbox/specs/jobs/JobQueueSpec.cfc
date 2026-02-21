/**
 * Tests for the Wheels Job Queue system.
 * Tests job configuration, enqueueing, processing, retry logic, and queue management.
 */
component extends="wheels.Testbox" {

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
			});

			it("throws NotImplemented when perform() is called on base class", function() {
				local.job = new wheels.Job();
				expect(function() {
					local.job.perform();
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
