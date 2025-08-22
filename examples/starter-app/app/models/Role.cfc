component extends="Model" {

	function config() {
		// Associations
		hasMany(name="rolepermissions", foreignKey="roleid");
        hasMany(
            name="permission",
            through="rolepermissions"
        );

		// Properties
		validatesPresenceOf("name");
		validatesUniquenessOf(properties="name", message="Role name must be unique");
	}

	function getRoles(){
		return findAll();
	}
	
	function getRolesOrderBy(){
		return findAll(order="name");
	}
	
	function getRoleById(required string key){
		return findByKey(key=arguments.key);
	}

	function createRole(required struct roleData) {
		role = create(arguments.roleData)
		return role;
	}

	function updateRoleByKey(required string key, required struct roleData) {
		role=getRoleById(arguments.key);
		if (role.update(arguments.roleData)) {
			return true;
		} else {
		  return false;
		}
	}

}
