/**
 * Sleeps longer than this.timeout so S1 can prove perform is cut off
 * instead of hanging until the method returns.
 */
component extends="wheels.Job" {

	public void function config() {
		super.config();
		this.timeout = 1;
	}

	public void function perform(struct data = {}) {
		sleep(3000);
		request.$wheelsSlowJobFinished = true;
	}

}
