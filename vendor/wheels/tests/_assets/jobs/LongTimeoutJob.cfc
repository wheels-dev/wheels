/**
 * A job whose own timeout (900 s) is longer than the 300 s default, so specs can check that the
 * worker claims and runs it with its own timeout rather than a caller's.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.timeout = 900;
	}

	public void function perform(struct data = {}) {
	}

}
