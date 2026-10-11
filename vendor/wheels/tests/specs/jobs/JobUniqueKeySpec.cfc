/**
 * De-duplicated enqueue. `enqueue(uniqueKey = "...")` writes at most one job per key: a second
 * enqueue with the same key — including one that loses a race to the first — returns
 * `{enqueued: false, duplicate: true}` with the existing job's id instead of writing another row.
 * A job enqueued without a key gets its own id as its key, so it never collides.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job uniqueKey", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_unique_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			afterEach(function() {
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_unique_%'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			it("writes one job for two enqueues with the same uniqueKey", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var first = job.enqueue(data = {n = 1}, queue = "test_unique_same", uniqueKey = "report:2026-10-12T11:00Z");
				var second = job.enqueue(data = {n = 2}, queue = "test_unique_same", uniqueKey = "report:2026-10-12T11:00Z");

				expect($rowCount("test_unique_same")).toBe(1, "the second enqueue must not write another row");
				expect(first.enqueued).toBeTrue();
				expect(first.duplicate).toBeFalse();
				expect(second.enqueued).toBeFalse();
				expect(second.duplicate).toBeTrue();
				expect(second.persisted).toBeFalse();
				expect(second.id).toBe(first.id, "a duplicate reports the existing job's id");
			});

			it("classifies an enqueue that loses the race to the unique index as a duplicate", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var first = job.enqueue(queue = "test_unique_race", uniqueKey = "slot:race");
				// This job's pre-check never sees the existing row, so its INSERT is the one that
				// hits the unique index, as a concurrent enqueue's would.
				var racer = new wheels.tests._assets.jobs.RacingUniqueKeyJob();
				var lost = racer.enqueue(queue = "test_unique_race", uniqueKey = "slot:race");

				expect($rowCount("test_unique_race")).toBe(1);
				expect(lost.duplicate).toBeTrue("the race loser must be reported as a duplicate, not an error");
				expect(lost.enqueued).toBeFalse();
				expect(lost.id).toBe(first.id);
			});

			it("writes separate jobs for different keys and for enqueues without a key", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				job.enqueue(queue = "test_unique_many", uniqueKey = "a");
				job.enqueue(queue = "test_unique_many", uniqueKey = "b");
				var plain1 = job.enqueue(queue = "test_unique_many");
				var plain2 = job.enqueue(queue = "test_unique_many");

				expect($rowCount("test_unique_many")).toBe(4);
				expect(plain1.enqueued).toBeTrue();
				expect(plain1.duplicate).toBeFalse();
				expect($uniqueKeyOf(plain1.id)).toBe(plain1.id, "a job enqueued without a key uses its id as its key");
				expect($uniqueKeyOf(plain2.id)).toBe(plain2.id);
			});

			it("de-duplicates enqueueIn and enqueueAt", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var first = job.enqueueIn(seconds = 60, queue = "test_unique_delayed", uniqueKey = "delayed:1");
				var second = job.enqueueAt(runAt = DateAdd("h", 1, Now()), queue = "test_unique_delayed", uniqueKey = "delayed:1");

				expect($rowCount("test_unique_delayed")).toBe(1);
				expect(second.duplicate).toBeTrue();
				expect(second.id).toBe(first.id);
			});

			it("still treats the key as taken after the job has completed", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var first = job.enqueue(queue = "test_unique_done", uniqueKey = "done:1");
				queryExecute(
					"UPDATE wheels_jobs SET status = 'completed' WHERE id = :id",
					{id = {value = first.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				var again = job.enqueue(queue = "test_unique_done", uniqueKey = "done:1");

				expect(again.duplicate).toBeTrue("a key stays taken while its row exists, whatever its status");
				expect($rowCount("test_unique_done")).toBe(1);
			});

			it("rejects a uniqueKey longer than 255 characters", function() {
				expect(function() {
					var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
					job.enqueue(queue = "test_unique_long", uniqueKey = RepeatString("k", 256));
				}).toThrow("Wheels.Job.InvalidUniqueKey");
				expect($rowCount("test_unique_long")).toBe(0);
			});

		});
	}

	private numeric function $rowCount(required string queue) {
		var q = queryExecute(
			"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE queue = :queue",
			{queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return Val(q.cnt);
	}

	/**
	 * The row's uniqueKey, or "" when the table has no such column.
	 */
	private string function $uniqueKeyOf(required string id) {
		var q = queryExecute(
			"SELECT * FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		if (!q.recordCount || !ListFindNoCase(q.columnList, "uniqueKey")) {
			return "";
		}
		return IsNull(q.uniqueKey[1]) ? "" : ToString(q.uniqueKey[1]);
	}

}
