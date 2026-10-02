component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
	}

	// #3933 probe: delegate a finder override to the framework original via super.<name>().
	public any function findAll() {
		variables.superFindAllDelegated = true;
		return super.findAll(argumentCollection = arguments);
	}

	public boolean function wasDelegated() {
		return StructKeyExists(variables, "superFindAllDelegated") && variables.superFindAllDelegated;
	}

}
