/**
 * ProcessOrdersJob
 * Queue: default
 * Priority: normal
 */
component extends="wheels.Job" {

	// Job configuration
	property name="queue" default="default";
	property name="priority" default="normal";
	property name="retries" default="3";
	property name="timeout" default="300";

	/**
	 * Constructor - Configure job settings
	 */
	function init() {
		// Initialize job configuration
		variables.jobName = "ProcessOrdersJob";
		return this;
	}

	/**
	 * Main job execution method
	 * @data.hint Job data/parameters
	 */
	public void function perform(struct data = {}) {
		try {
			// Log job start
			logInfo("Starting ProcessOrdersJob with data: " & serializeJSON(arguments.data));

			// Validate input data
			validateJobData(arguments.data);

			// TODO: Implement your job logic here
			processJobData(arguments.data);

			// Log job completion
			logInfo("Completed ProcessOrdersJob successfully");

		} catch (any e) {
			// Log error
			logError("Error in ProcessOrdersJob: " & e.message, e);

			// Re-throw to trigger retry logic
			throw(object=e);
		}
	}

	/**
	 * Enqueue job for processing
	 * @data.hint Job data
	 */
	public void function enqueue(struct data = {}) {
		// Add job to queue
		super.enqueue(
			jobName = variables.jobName,
			data = arguments.data,
			queue = variables.queue,
			priority = variables.priority
		);
	}

	/**
	 * Enqueue job with delay
	 * @seconds.hint Delay in seconds
	 * @data.hint Job data
	 */
	public void function enqueueIn(required numeric seconds, struct data = {}) {
		enqueueAt(
			datetime = dateAdd("s", arguments.seconds, now()),
			data = arguments.data
		);
	}

	/**
	 * Enqueue job for specific time
	 * @datetime.hint When to run the job
	 * @data.hint Job data
	 */
	public void function enqueueAt(required date datetime, struct data = {}) {
		super.enqueueAt(
			jobName = variables.jobName,
			data = arguments.data,
			queue = variables.queue,
			priority = variables.priority,
			runAt = arguments.datetime
		);
	}

	// ========================================
	// Private Methods
	// ========================================

	/**
	 * Validate job data
	 */
	private void function validateJobData(required struct data) {
		// Add validation logic here
		// Example: if (!structKeyExists(arguments.data, "requiredField")) {
		//     throw(type="ValidationException", message="Missing required field");
		// }
	}

	/**
	 * Process job data
	 */
	private void function processJobData(required struct data) {
		// Implement your job processing logic here
		// Example:
		// - Process batch records
		// - Send emails
		// - Generate reports
		// - Sync with external APIs
		// - Clean up old data
	}

	/**
	 * Log info message
	 */
	private void function logInfo(required string message) {
		if (structKeyExists(application, "log")) {
			application.log.info(arguments.message);
		}
		writeLog(text=arguments.message, type="information", file="jobs");
	}

	/**
	 * Log error message
	 */
	private void function logError(required string message, any exception) {
		if (structKeyExists(application, "log")) {
			application.log.error(arguments.message, arguments.exception);
		}
		writeLog(text=arguments.message, type="error", file="jobs");
	}
}