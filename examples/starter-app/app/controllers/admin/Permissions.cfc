component extends="app.controllers.Controller" {

	function config() {
		super.config(restrictAccess=true);
		verifies(except="index", params="key", paramsTypes="integer", handler="objectNotFound");
		filters(through="filterGetAllRoles");
	}

	/**
	* View all permissions
	**/
	function index() {
		try{
			allroles=model("role").getRolesOrderBy();
			allpermissions=model("permission").getPermissions();
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
		
	}

	/**
	* Edit permission
	**/
	function edit() {
		try{
			permission=model("permission").getRolePermissionByKey(params.key);
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	* Update permission
	**/
	function update() {
		try {
		updated = model("Permission").updatePermissionByKey(params.key, params.permission);
			if(updated){
				redirectTo(action="index", success="Permission successfully updated: you must reload the application for these to take effect.");
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
		redirectTo(action="index", error="That permission wasn't found");
	}

}
