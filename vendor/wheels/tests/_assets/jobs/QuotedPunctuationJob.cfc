/**
 * A real job whose declaration has `{` and `>` inside a quoted attribute value
 * before its extends, so the jobsEnqueue source check must read past them.
 */
component displayname="Orders {daily} > archive" extends="wheels.Job" {
	public void function perform(struct data = {}) {
	}
}
