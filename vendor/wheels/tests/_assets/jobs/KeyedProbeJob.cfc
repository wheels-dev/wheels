/**
 * A job whose concurrency key comes from its data (core-suite fixture): one run per account.
 */
component extends="wheels.Job" {

	public string function concurrencyKey(struct data = {}) {
		return "acct-" & arguments.data.account;
	}

	public void function perform(struct data = {}) {
	}

}
