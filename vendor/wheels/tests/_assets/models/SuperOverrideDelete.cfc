component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
	}

	/**
	 * Overrides the delete() model mixin to prove the sanctioned 4.1.0
	 * delegation path — the parent-method call `super.delete()` (#3519). The
	 * legacy `variables.superdelete` alias is no longer invocable for a
	 * `delete` override, so this fixture delegates the way the upgrade guide
	 * now documents.
	 */
	public boolean function delete() {
		variables.superDeleteInvoked = true;
		return super.delete(argumentCollection = arguments);
	}

	public boolean function wasSuperDeleteInvoked() {
		return StructKeyExists(variables, "superDeleteInvoked") && variables.superDeleteInvoked;
	}

}
