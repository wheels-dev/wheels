/**
 * A job's perform() can call model() like a controller can. wheels.Job extends nothing, so
 * model() is a small delegate to application.wo.model(); the guides' job examples rely on it.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job model() helper", function() {

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue = 'test_job_model'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
				StructDelete(request, "$wheelsJobModelProbe");
			});

			afterEach(function() {
				StructDelete(request, "$wheelsJobModelProbe");
				try {
					queryExecute("DELETE FROM wheels_jobs WHERE queue = 'test_job_model'", {}, {datasource = application.wheels.dataSourceName});
				} catch (any e) {
				}
			});

			it("returns the same model class object as application.wo.model()", function() {
				var job = new wheels.Job();
				var viaJob = job.model("Author");
				var viaGlobal = application.wo.model("Author");
				expect(viaJob.tableName()).toBe(viaGlobal.tableName());
				expect(viaJob.count()).toBe(viaGlobal.count());
			});

			it("lets perform() look up a record when the worker processes the job", function() {
				var expected = application.wo.model("Author").findOne(order = "id");
				var probeJob = CreateObject("component", "wheels.tests._assets.jobs.ModelLookupJob").init();
				var enqueued = probeJob.enqueue(data = {firstName = expected.firstName}, queue = "test_job_model");
				expect(enqueued.persisted).toBeTrue();

				var worker = new wheels.JobWorker();
				var result = worker.processNext(queues = "test_job_model");

				expect(result.success).toBeTrue();
				expect(request).toHaveKey("$wheelsJobModelProbe");
				expect(request.$wheelsJobModelProbe.found).toBeTrue();
				expect(request.$wheelsJobModelProbe.firstName).toBe(expected.firstName);

				var row = queryExecute(
					"SELECT status FROM wheels_jobs WHERE id = :id",
					{id = {value = enqueued.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(row.status).toBe("completed");
			});
		});
	}
}
