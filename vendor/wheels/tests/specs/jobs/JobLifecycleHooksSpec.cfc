/**
 * Job lifecycle hooks and the stored result. beforePerform/afterPerform run with perform() as part
 * of the work; onSuccess/onFailure run after the outcome is recorded and can't change it; the
 * app-wide jobsOnFailure hook hears about every failure; perform()'s return value is stored in
 * wheels_jobs.result. Both processing paths (the worker and processQueue()) are covered.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("job lifecycle hooks", function() {

			beforeEach(function() {
				new wheels.Job().$ensureJobTable();
				$cleanup();
				application["$hookSpecLog"] = "";
				application["$hookSpecSuccessThrows"] = false;
				application["$hookSpecGlobalCount"] = 0;
				StructDelete(application, "$hookSpecGlobal");
				application.wheels.jobsOnFailure = "wheels.tests._assets.jobs.FailureHookTarget.record";
				StructDelete(application.wheels, "$jobsOnFailureWarned");
			});

			afterEach(function() {
				$cleanup();
				StructDelete(application.wheels, "jobsOnFailure");
				StructDelete(application.wheels, "$jobsOnFailureWarned");
				application["$hookSpecSuccessThrows"] = false;
			});

			it("runs beforePerform, perform, afterPerform, then onSuccess, and stores the result", function() {
				var id = $insertJob(queue = "test_hooks_ok", data = {mode = "text"});
				var result = new wheels.JobWorker().processNext(queues = "test_hooks_ok", timeout = 300);
				expect(result.success).toBeTrue(result.error);
				expect(application["$hookSpecLog"]).toBe("before|perform|after|success:done");
				expect($row(id).result).toBe("done");
			});

			it("stores a complex result as JSON", function() {
				var id = $insertJob(queue = "test_hooks_struct", data = {mode = "struct"});
				new wheels.JobWorker().processNext(queues = "test_hooks_struct", timeout = 300);
				var stored = DeserializeJSON($row(id).result);
				expect(stored.count).toBe(2);
				expect(ListLast(application["$hookSpecLog"], "|")).toBe("success:complex");
			});

			it("stores NULL when perform() returns nothing", function() {
				var id = $insertJob(queue = "test_hooks_void", data = {mode = "void"});
				new wheels.JobWorker().processNext(queues = "test_hooks_void", timeout = 300);
				var row = $row(id);
				expect(row.status).toBe("completed");
				expect(row.resultIsNull).toBeTrue();
				expect(ListLast(application["$hookSpecLog"], "|")).toBe("success:none");
			});

			it("cuts a long result short with a visible marker", function() {
				var id = $insertJob(queue = "test_hooks_long", data = {mode = "long"});
				new wheels.JobWorker().processNext(queues = "test_hooks_long", timeout = 300);
				var stored = $row(id).result;
				expect(Len(stored)).toBeLTE(4000);
				expect(Right(stored, 14)).toBe("...[truncated]");
			});

			it("stores a non-ASCII result intact", function() {
				var id = $insertJob(queue = "test_hooks_unicode", data = {mode = "unicode"});
				new wheels.JobWorker().processNext(queues = "test_hooks_unicode", timeout = 300);
				expect($row(id).result).toBe("caf" & Chr(233) & " " & Chr(8211) & " " & Chr(26085) & Chr(26412) & " " & Chr(10003));
			});

			it("cuts a long non-ASCII result at what the column counts, never mid-character", function() {
				var id = $insertJob(queue = "test_hooks_unicodelong", data = {mode = "unicodeLong"});
				new wheels.JobWorker().processNext(queues = "test_hooks_unicodelong", timeout = 300);
				var stored = $row(id).result;
				var original = RepeatString(Chr(26085) & Chr(26412), 1500);
				if (new wheels.Job().$detectDatabaseType() == "sqlserver") {
					// NVARCHAR(4000) counts characters: 3000 fit whole.
					expect(stored).toBe(original);
				} else {
					// 9000 UTF-8 bytes: cut to 4000 bytes, on a character boundary.
					expect(Right(stored, 14)).toBe("...[truncated]");
					expect(Len(CharsetDecode(stored, "utf-8"))).toBeLTE(4000);
					var kept = Left(stored, Len(stored) - 14);
					expect(Left(original, Len(kept))).toBe(kept);
				}
			});

			it("calls onFailure and the app's hook with isFinal = false when the job will be retried", function() {
				var id = $insertJob(queue = "test_hooks_retry", data = {mode = "fail"});
				var result = new wheels.JobWorker().processNext(queues = "test_hooks_retry", timeout = 300);
				expect(result.success).toBeFalse();
				expect($row(id).status).toBe("pending");
				expect(ListLast(application["$hookSpecLog"], "|")).toBe("failure:1:false:Spec.HookFailure");
				var event = application["$hookSpecGlobal"];
				expect(event.jobId).toBe(id);
				expect(event.jobClass).toBe("wheels.tests._assets.jobs.HookProbeJob");
				expect(event.queue).toBe("test_hooks_retry");
				expect(event.attempt).toBe(1);
				expect(event.isFinal).toBeFalse();
				expect(event.error.type).toBe("Spec.HookFailure");
				expect(event.error.message).toInclude("perform failed");
				expect(event.error.detail).toBe("spec detail");
				expect(StructKeyExists(event, "data")).toBeFalse("job data never reaches the app-wide hook");
			});

			it("calls the hooks with isFinal = true when the job is marked failed", function() {
				var id = $insertJob(queue = "test_hooks_final", data = {mode = "fail"}, attempts = 1);
				new wheels.JobWorker().processNext(queues = "test_hooks_final", timeout = 300);
				expect($row(id).status).toBe("failed");
				expect(ListLast(application["$hookSpecLog"], "|")).toBe("failure:2:true:Spec.HookFailure");
				expect(application["$hookSpecGlobal"].isFinal).toBeTrue();
				expect(application["$hookSpecGlobalCount"]).toBe(1);
			});

			it("fails the attempt when beforePerform throws, without running perform()", function() {
				var id = $insertJob(queue = "test_hooks_before", data = {failBefore = true});
				var result = new wheels.JobWorker().processNext(queues = "test_hooks_before", timeout = 300);
				expect(result.success).toBeFalse();
				expect(application["$hookSpecLog"]).toBe("before|failure:1:false:Spec.BeforeFailure");
				expect($row(id).status).toBe("pending");
			});

			it("keeps the job completed when onSuccess throws", function() {
				application["$hookSpecSuccessThrows"] = true;
				var id = $insertJob(queue = "test_hooks_throws", data = {mode = "text"});
				var result = new wheels.JobWorker().processNext(queues = "test_hooks_throws", timeout = 300);
				expect(result.success).toBeTrue(result.error);
				expect($row(id).status).toBe("completed");
			});

			it("still records the failure when the app's hook can't be called", function() {
				application.wheels.jobsOnFailure = "wheels.tests._assets.jobs.NoSuchHookTarget.record";
				var id = $insertJob(queue = "test_hooks_badglobal", data = {mode = "fail"});
				new wheels.JobWorker().processNext(queues = "test_hooks_badglobal", timeout = 300);
				expect($row(id).status).toBe("pending");
				expect(ListLast(application["$hookSpecLog"], "|")).toBe("failure:1:false:Spec.HookFailure");
			});

			it("runs the hooks and stores the result in processQueue() too", function() {
				var okId = $insertJob(queue = "test_hooks_pq", data = {mode = "text"});
				var failId = $insertJob(queue = "test_hooks_pq", data = {mode = "fail"}, attempts = 1);
				new wheels.Job().processQueue(queue = "test_hooks_pq", limit = 0);
				expect($row(okId).result).toBe("done");
				expect(application["$hookSpecLog"]).toInclude("success:done");
				expect(application["$hookSpecLog"]).toInclude("failure:2:true:Spec.HookFailure");
				expect($row(failId).status).toBe("failed");
				expect(application["$hookSpecGlobal"].jobId).toBe(failId);
			});

			it("calls the hooks with isFinal = true when the reaper marks a dead worker's last attempt failed", function() {
				var id = $insertJob(queue = "test_hooks_reap", data = {mode = "text"}, attempts = 2, status = "processing", stale = true);
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_hooks_reap");
				expect($row(id).status).toBe("failed");
				expect(application["$hookSpecLog"]).toBe("failure:2:true:Wheels.JobTimeout");
				expect(application["$hookSpecGlobal"].isFinal).toBeTrue();
			});

			it("calls the hooks with isFinal = true when the reaper interrupts a job that isn't idempotent", function() {
				var id = $insertJob(queue = "test_hooks_interrupt", data = {mode = "text"}, attempts = 1, status = "processing", stale = true, jobClass = "wheels.tests._assets.jobs.NonIdempotentHookJob");
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_hooks_interrupt");
				expect($row(id).status).toBe("interrupted");
				expect(application["$hookSpecLog"]).toBe("failure:1:true:Wheels.JobTimeout");
				expect(application["$hookSpecGlobal"].isFinal).toBeTrue();
			});

			it("doesn't call the hooks when the reaper schedules a retry", function() {
				$insertJob(queue = "test_hooks_reapretry", data = {mode = "text"}, attempts = 1, status = "processing", stale = true);
				new wheels.JobWorker().checkTimeouts(timeout = 300, queues = "test_hooks_reapretry");
				expect(application["$hookSpecLog"]).toBe("");
				expect(application["$hookSpecGlobalCount"]).toBe(0);
			});

		});
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_hooks_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	private string function $insertJob(
		required string queue,
		struct data = {},
		numeric attempts = 0,
		string status = "pending",
		boolean stale = false,
		string jobClass = "wheels.tests._assets.jobs.HookProbeJob"
	) {
		var id = CreateUUID();
		var stamp = arguments.stale ? DateAdd("h", -2, Now()) : DateAdd("s", -5, Now());
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, :jobClass, :queue, :data, 0, :status, :attempts, 1, :runAt, :createdAt, :updatedAt)",
			{
				id = {value = id, cfsqltype = "cf_sql_varchar"},
				jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
				queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
				data = {value = SerializeJSON(arguments.data), cfsqltype = "cf_sql_longvarchar"},
				status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
				attempts = {value = arguments.attempts, cfsqltype = "cf_sql_integer"},
				runAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				createdAt = {value = stamp, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = stamp, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		return id;
	}

	private struct function $row(required string id) {
		var q = queryExecute(
			"SELECT status, result FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		var nulls = queryExecute(
			"SELECT id FROM wheels_jobs WHERE id = :id AND result IS NULL",
			{id = {value = arguments.id, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return {
			status = q.recordCount ? q.status : "",
			result = q.recordCount && !IsNull(q.result[1]) ? q.result[1] : "",
			resultIsNull = nulls.recordCount > 0
		};
	}

}
