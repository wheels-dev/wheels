component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
	}

	// #3933 probe: delegate a finder override and capture the delegated result
	// in-fixture (null-safe) so the spec can prove the framework query came back,
	// not just that the override ran. RustCFML's super.<name> delegation runs but
	// returns null — recordCount() reports -1 there so the spec can characterise it.
	public any function findAll() {
		variables.superFindAllDelegated = true;
		var delegated = super.findAll(argumentCollection = arguments);
		var ok = StructKeyExists(local, "delegated") && !IsNull(local.delegated) && IsQuery(local.delegated);
		variables.superFindAllReturnedQuery = ok;
		variables.superFindAllCount = ok ? local.delegated.recordCount : -1;
		if (ok) {
			return local.delegated;
		}
		return QueryNew("id");
	}

	public boolean function wasDelegated() {
		return StructKeyExists(variables, "superFindAllDelegated") && variables.superFindAllDelegated;
	}

	public boolean function returnedQuery() {
		return StructKeyExists(variables, "superFindAllReturnedQuery") && variables.superFindAllReturnedQuery;
	}

	public numeric function delegatedCount() {
		return StructKeyExists(variables, "superFindAllCount") ? variables.superFindAllCount : -1;
	}

}
