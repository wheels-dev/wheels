/**
 * A job whose duplicate pre-check never finds anything, as if a concurrent enqueue with the same
 * uniqueKey inserted its row between this enqueue's check and its INSERT. The INSERT then hits the
 * unique index, which is the path a real race loser takes.
 */
component extends="wheels.Job" {

	public string function $findJobIdByUniqueKey(required string uniqueKey) {
		return "";
	}

	public void function perform(struct data = {}) {
	}

}
