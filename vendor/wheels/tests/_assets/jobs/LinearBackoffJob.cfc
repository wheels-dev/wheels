/**
 * Sets retryBackoff=linear in config(). Linear is a reserved no-op: the
 * schedule must stay exponential (S2) once config() actually runs (S3).
 */
component extends="wheels.Job" {

	public void function config() {
		super.config();
		this.baseDelay = 600;
		this.maxDelay = 7200;
		this.retryBackoff = "linear";
	}

	public void function perform(struct data = {}) {
		throw(type = "Wheels.Tests.JobFailure", message = "LinearBackoffJob always fails");
	}

}
