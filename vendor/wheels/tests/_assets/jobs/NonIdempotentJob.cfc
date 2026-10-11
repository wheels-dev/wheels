/**
 * A job that must not run twice: after a reap it is not retried, it ends 'interrupted'.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.idempotent = false;
	}

	public void function perform(struct data = {}) {
	}

}
