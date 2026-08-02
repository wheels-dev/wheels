component extends="Model" {

	/*
	 * Exists purely to exercise the request-query-cache key collision guarded by
	 * requestQueryCacheTenantCollisionSpec (#3336): `Tenant` is the natural model name for the
	 * control-plane model in a database-per-tenant app, and CFML struct keys are case-insensitive,
	 * so it is the one model name that can alias onto framework-owned `request.wheels.tenant`.
	 * Backed by the existing authors fixture table so no populate.cfm changes are needed.
	 */
	function config() {
		table("c_o_r_e_authors");
	}

}
