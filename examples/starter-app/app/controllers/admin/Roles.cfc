component extends="app.controllers.Controller" {

	function config() {
		super.config(restrictAccess=true);
		verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
	}

	/**
	* View all roles
	**/
	function index() {
		try{
			roles=model("role").getRoles();
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}
	/**
	* Add New Role
	**/
	function new() {
		role=model("Role").new();
	}

	/**
	* Create Role
	**/
	function create() {
		try {
			role=model("Role").createRole(params.Role);
			if(role.hasErrors()){
				renderView(action="new");
			} else {
				redirectTo(action="index", success="Role successfully created");
			}
		} catch (any e) {
			redirectTo(action="new", error="Error: #e.message#");
		}	
	}
	/**
	* Edit role
	**/
	function edit() {
		try{
			role=model("role").getRoleById(params.key);
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	* Update role
	**/
	function update() {
		try {
			updated = model("role").updateRoleByKey(params.key, params.role);
			if(updated){
				redirectTo(action="index", success="Role successfully updated");
			} else {
				renderView(action="edit");
			}
		} catch (any e) {
			redirectTo(action="edit", error="Error: #e.message#");
		}
	}

	/**
	* Redirect away if verifies fails, or if an object can't be found
	**/
	private function objectNotFound() {
		redirectTo(action="index", error="That Role wasn't found");
	}

}
