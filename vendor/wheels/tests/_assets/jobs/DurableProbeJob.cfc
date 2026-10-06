/**
 * Test-only job whose class default is transactional = false (jobDurableEnqueueSpec).
 */
component extends="wheels.tests._assets.jobs.ProbeJob" {

	public void function config() {
		this.transactional = false;
	}

}
