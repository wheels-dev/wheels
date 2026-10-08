/**
 * A job with a fixed concurrency key, and exclusive left false (core-suite fixture): the key
 * alone makes it share one lease.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.concurrencyKey = "nightly-report";
	}

	public void function perform(struct data = {}) {
	}

}
