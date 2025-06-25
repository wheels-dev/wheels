/**
 * Base Job class for Wheels framework
 * Provides common functionality for background jobs
 */
component {

	/**
	 * Constructor
	 */
	public function init() {
		return this;
	}

	/**
	 * Main job execution method to be overridden by subclasses
	 * @data Job data/parameters
	 */
	public void function perform(struct data = {}) {
		throw(type="Wheels.NotImplemented", message="The perform() method must be implemented in the job subclass");
	}

	/**
	 * Enqueue job for processing
	 * @jobName Name of the job
	 * @data Job data
	 * @queue Queue name
	 * @priority Job priority
	 */
	public void function enqueue(
		required string jobName,
		struct data = {},
		string queue = "default",
		string priority = "normal"
	) {
		// Placeholder for queue implementation
		// In a real implementation, this would add the job to a queue system
		writeLog(
			text="Job '#arguments.jobName#' enqueued to queue '#arguments.queue#' with priority '#arguments.priority#'",
			type="information",
			file="jobs"
		);
	}

	/**
	 * Enqueue job for specific time
	 * @jobName Name of the job
	 * @data Job data
	 * @queue Queue name
	 * @priority Job priority
	 * @runAt When to run the job
	 */
	public void function enqueueAt(
		required string jobName,
		struct data = {},
		string queue = "default",
		string priority = "normal",
		required date runAt
	) {
		// Placeholder for scheduled queue implementation
		writeLog(
			text="Job '#arguments.jobName#' scheduled for #dateTimeFormat(arguments.runAt, 'yyyy-mm-dd HH:nn:ss')#",
			type="information",
			file="jobs"
		);
	}
}