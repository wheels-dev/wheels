component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
	}

	// #3933 probe: delegate via the variables.super<name> alias.
	public any function findAll() {
		variables.superFindAllDelegated = true;
		return variables.superFindAll(argumentCollection = arguments);
	}

	public boolean function wasDelegated() {
		return StructKeyExists(variables, "superFindAllDelegated") && variables.superFindAllDelegated;
	}

}
