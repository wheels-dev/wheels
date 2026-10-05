component extends="Model" {

	/*
	 * Backs advisoryLockTenantSpec: the authors table as a shared (non-tenant) model, which keeps
	 * the application's default datasource when a tenant datasource is active.
	 */
	function config() {
		table("c_o_r_e_authors");
		sharedModel();
	}

}
