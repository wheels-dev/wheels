/**
 * Test-only job with custom backoff settings that always fails.
 * The settings live in the pseudo-constructor (not config()) because the queue
 * processing paths instantiate job classes via CreateObject() without calling init().
 */
component extends="wheels.Job" {

	this.baseDelay = 600;
	this.maxDelay = 7200;

	public void function perform(struct data = {}) {
		throw(type = "Wheels.Tests.JobFailure", message = "FailingBackoffJob always fails");
	}
}
