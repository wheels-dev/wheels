/**
 * ProcessOrdersJob (core-suite fixture)
 *
 * A plain job for the core job specs (jobs.*). It lives with the suite rather
 * than in app/jobs/ so the specs run the same in the framework repo and inside
 * an app built with `wheels new`; `wheels.tests._assets.jobs` is on the job
 * class allowlist outside production.
 *
 * Usage:
 *   job = new wheels.tests._assets.jobs.ProcessOrdersJob();
 *   job.enqueue(data={batchSize: 50});
 *   job.enqueueIn(seconds=300, data={batchSize: 100});
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.queue = "default";
		this.priority = 0;
		this.maxRetries = 3;
	}

	/**
	 * Main job execution method
	 * @data Job data/parameters
	 */
	public void function perform(struct data = {}) {
		local.batchSize = StructKeyExists(arguments.data, "batchSize") ? arguments.data.batchSize : 10;

		writeLog(
			text = "ProcessOrdersJob: Processing batch of #local.batchSize# orders",
			type = "information",
			file = "wheels_jobs"
		);

		writeLog(
			text = "ProcessOrdersJob: Batch processing complete",
			type = "information",
			file = "wheels_jobs"
		);
	}
}
