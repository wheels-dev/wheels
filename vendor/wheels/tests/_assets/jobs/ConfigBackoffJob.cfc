/**
 * Backoff settings live only in config(). Proves S3: processing paths must
 * call init() so config() is not stuck unused after CreateObject().
 */
component extends="wheels.Job" {

	public void function config() {
		super.config();
		this.baseDelay = 600;
		this.maxDelay = 7200;
	}

	public void function perform(struct data = {}) {
		throw(type = "Wheels.Tests.JobFailure", message = "ConfigBackoffJob always fails");
	}

}
