/**
 * A job that turns the heartbeat grace off for itself (core-suite fixture).
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.heartbeatGrace = 0;
	}

	public void function perform(struct data = {}) {
	}

}
