/**
 * Backs transactionAbortRollbackSpec: methods run through invokeWithTransaction() that write a
 * marked row and then end the request with `abort`, or return normally. Each aborting method sets
 * server["wheelsTxnAbortProbe_<marker>"] right before the abort, so the spec can tell the request
 * really reached the write (a positive control). The spec creates and drops the table.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_txnabortprobes");
	}

	public boolean function insertThenAbort(required string marker) {
		this.create(marker = arguments.marker, transaction = "none");
		server["wheelsTxnAbortProbe_" & arguments.marker] = true;
		abort;
	}

	public boolean function insertThenReturn(required string marker) {
		this.create(marker = arguments.marker, transaction = "none");
		return true;
	}

	public boolean function insertThenFalse(required string marker) {
		this.create(marker = arguments.marker, transaction = "none");
		return false;
	}

	// a row, then a nested invokeWithTransaction() (which joins this transaction) that aborts
	public boolean function outerThenNestedAbort(required string marker) {
		this.create(marker = arguments.marker & "-outer", transaction = "none");
		this.invokeWithTransaction(method = "insertThenAbort", marker = arguments.marker & "-inner");
		return true;
	}

	// a row, then a savepoint unit that aborts
	public boolean function outerThenSavepointAbort(required string marker) {
		this.create(marker = arguments.marker & "-outer", transaction = "none");
		this.invokeWithTransaction(method = "insertThenAbort", transaction = "savepoint", marker = arguments.marker & "-inner");
		return true;
	}

	// a row kept, then a savepoint unit that returns false (rolled back to the savepoint)
	public boolean function outerThenSavepointFalse(required string marker) {
		this.create(marker = arguments.marker & "-outer", transaction = "none");
		this.invokeWithTransaction(method = "insertThenFalse", transaction = "savepoint", marker = arguments.marker & "-inner");
		return true;
	}

}
