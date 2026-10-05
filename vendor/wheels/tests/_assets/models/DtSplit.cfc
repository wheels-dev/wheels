component extends="Model" {

	/*
	 * Backs sqlServerDateStringSplitSpec: one column of each SQL Server date and time type. The
	 * spec creates and drops the table, on SQL Server only.
	 */
	function config() {
		table("c_o_r_e_dtsplits");
	}

}
