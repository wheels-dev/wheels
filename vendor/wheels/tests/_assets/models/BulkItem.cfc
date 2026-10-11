component extends="Model" {

	function config() {
		table("c_o_r_e_bulkitems");
	}

	// For bulkTransactionSpec: runs insertAll() inside the caller's transaction, where its own
	// transaction = "commit" joins the open one.
	public boolean function insertAllInside(required array records) {
		insertAll(records = arguments.records, transaction = "commit");
		return true;
	}

}
