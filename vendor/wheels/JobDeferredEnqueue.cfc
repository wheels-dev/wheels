/**
 * Internal: a job enqueued inside a Wheels-managed transaction on another datasource
 * (a tenant's). It rides that transaction's afterCommit/afterRollback queue: the job row
 * is written once the transaction commits and dropped if it rolls back.
 */
component {

	public any function init(required any job, required struct row, boolean durable = false) {
		variables.job = arguments.job;
		variables.row = arguments.row;
		// durable (enqueue transactional = false): written on rollback too.
		variables.durable = arguments.durable;
		return this;
	}

	/**
	 * Called by the model layer when the owning transaction resolves.
	 */
	public void function $runTransactionCallbacks(required string type, string operation = "", boolean propagateErrors = true) {
		if (CompareNoCase(arguments.type, "afterCommit") != 0 && !variables.durable) {
			writeLog(
				text = "Job '#variables.row.jobClass#' [#variables.row.id#] was not enqueued: the transaction it was enqueued in rolled back",
				type = "information",
				file = "wheels_jobs"
			);
			return;
		}
		if (arguments.propagateErrors) {
			variables.job.$persistJobRow(variables.row);
			return;
		}
		try {
			variables.job.$persistJobRow(variables.row);
		} catch (any e) {
			// $persistJobRow has already logged the failure at error level
		}
	}

}
