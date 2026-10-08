/**
 * A job whose concurrency key comes from its data (core-suite fixture): one run per account.
 * It also sets this.concurrencyKey, which concurrencyKeyFor() takes precedence over.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.concurrencyKey = "ignored-static-key";
	}

	public string function concurrencyKeyFor(struct data = {}) {
		return "acct-" & arguments.data.account;
	}

	public void function perform(struct data = {}) {
	}

}
