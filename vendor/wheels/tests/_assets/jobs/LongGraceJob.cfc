/**
 * A job with its own, longer heartbeat grace (core-suite fixture).
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.heartbeatGrace = 1200;
	}

	public void function perform(struct data = {}) {
	}

}
