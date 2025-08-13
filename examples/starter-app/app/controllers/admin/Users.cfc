component extends="app.controllers.Controller" {

	function config() {
		super.config(restrictAccess=true);
		verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
		filters(through="filterGetAllRoles", except="show");
	}

	/**
	* View all Users
	**/
	function index() {
		param name="params.q" default="";
		param name="params.roleid" default=0;
		param name="params.page" type="numeric" default=1;
		param name="params.perpage" type="numeric" default=50;
		param name="params.status" default="active";

		local.where=[];
		local.includeSoftDeletes=false;

		if(params.roleid > 0){
			arrayAppend(local.where, "roleid = #params.roleid#");
		}

		switch(params.status) {
		    case "pending":
				arrayAppend(local.where, "verified = 0");
		        break;
		    case "disabled":
		    	local.includeSoftDeletes = true;
				arrayAppend(local.where, "deletedAt IS NOT NULL");
		        break;
		    case "all":
		    	local.includeSoftDeletes = true;
		    	break;
		    default:
				arrayAppend(local.where, "verified = 1");
		}

		if(len(params.q)){
			local.qWhere=[];
			var sanitizedQ=stripTags(params.q);

			if(len(params.q) GT 50){
				params.q = "";
			} else {
				arrayAppend(local.qWhere, "firstname LIKE '%#sanitizedQ#%'");
				arrayAppend(local.qWhere, "lastname LIKE '%#sanitizedQ#%'");
				arrayAppend(local.qWhere, "email LIKE '%#sanitizedQ#%'");
				arrayAppend(local.where, whereify(local.qWhere, "OR"));
			}
		}
		users=model("user").getUsers(local.where, local.includeSoftDeletes, params.page, params.perpage);
	}

	/**
	* View User
	**/
	function show() {
		user=model("user").getUserRoleById(params.key);
		if(!isObject(user)){
			objectNotFound();
		}
	}

	/**
	* Add New User
	**/
	function new() {
		user=model("user").new();
	}

	/**
	* Create User
	**/
	function create() {
		try {
			created = model("user").createUser(params.user)
			if(created){
				redirectTo(action="index", success="User successfully created");
			} else {
				renderView(action="new");
			}
		} catch (any e) {
			redirectTo(action="new", error="Error: #e.message#");
		}	
	}

	/**
	* Edit User
	**/
	function edit() {
		user=model("user").getUserById(params.key);
		if(!isObject(user)){
			objectNotFound();
		}
	}

	/**
	* Update User
	**/
	function update() {
		try {
			updated = model("user").updateUserByKey(params.key, params.user);
			if(updated){
				redirectTo(action="index", success="User successfully updated");
			} else {
				renderView(action="edit");
			}
		} catch (any e) {
			redirectTo(action="new", error="Error: #e.message#");
		}	
	}

	/**
	* Disable / Soft Delete User
	**/
	function delete() {
		try{
			if(model("user").softDeleteUser(params.key)){
				redirectTo(action="index", success="User successfully disabled");
			} else {
				redirectTo(action="index", error="Couldn't disable user");
			}
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	 * Destroy (Permanent Delete) User
	 */
	function destroy() {
		try{
			if(model("user").deleteUser(params.key)){
				redirectTo(action="index", success="User successfully deleted");
			} else {
				redirectTo(action="index", error="Couldn't delete user");
			}	
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	 * Recover User
	 */
	function recover() {
		try{
			if(model("user").recoverUser(key=params.key)){
				redirectTo(action="index", success="User successfully recovered");
			} else {
				redirectTo(action="index", error="Couldn't recover user");
			}	
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	 * Reset a user's password. Generates a new one and emails it to them. Forces them to change it on login
	 * NB Due to current bug in 2.x, we can't name this action resetPassword as it clashes with the plugin method
	 * See https://github.com/cfwheels/cfwheels/issues/841
	 */
	function reset() {
		try{
			user=model("user").getUserById(params.key);
			user.resetPassword();
			// password is currently in plaintext as it's skipped validation
			// Grab it so we can use it in emails
			tempPassword = user.password;
			// Now hash it and send email
			user.hashPassword();
			if(user.save()){
				addLogLine(type="security", severity="warning", message="User issued new temporary password");
				// Send Reset Email
				if(getSetting("email_send")){
					sendEmail(
						to=user.email,
						from=getSetting("email_fromAddress"),
						subject="Your Password has been reset",
						template="/emails/passwordResetAdmin,/emails/passwordResetAdminPlain",
						user=user,
						tempPassword=tempPassword);
				}
			}
			redirectTo(back=true, info="New temp password sent to user");	
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	 * Assume User: This is a high powered function which allows you to login "as" another user.
	 * Take care that you only permit the highest role access.
	 */
	function assume() {
		try{
			requestedUser=model("user").getUserById(params.key);
			if(isObject(requestedUser)){
				addLogLine(type="security", severity="danger", message="User assumed user id: #requesteduser.id#: #requesteduser.email#");
				assignPermissions(requestedUser);
				// Redirect to the root here, as otherwise if you assume a user with lower permissions, you'll throw a 403 if you try
				// and access the user index
				redirectTo(route="root", success="You have assumed a different account");
			} else {
				objectNotFound();
			}	
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	* Redirect away if verifies fails, or if an object can't be found
	**/
	private function objectNotFound() {
		redirectTo(action="index", error="That User wasn't found");
	}
}
