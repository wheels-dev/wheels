/**
 * ProcessOrdersJob
 *
 * Example background job demonstrating the Wheels job queue system.
 * Processes pending orders in batch.
 *
 * Usage:
 *   job = new app.jobs.ProcessOrdersJob();
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

		// TODO: Replace with actual order processing logic
		// Example:
		// var orders = model("Order").findAll(where="status='pending'", maxRows=local.batchSize);
		// for (var order in orders) {
		//   order.status = "processing";
		//   order.save();
		//   // process the order...
		//   order.status = "completed";
		//   order.save();
		// }

		writeLog(
			text = "ProcessOrdersJob: Batch processing complete",
			type = "information",
			file = "wheels_jobs"
		);
	}
}
