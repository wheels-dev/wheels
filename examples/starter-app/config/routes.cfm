<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.cfwheels.org/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/routing for more info.

	mapper()
		// CLI-Appends-Here

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		// .wildcard()

		//=====================================================================
		//= 	Authentication Routes
		//=====================================================================
		.get(name="login", to="sessions##new")
		.get(name="logout", to="sessions##delete")
		.post(name="authenticate", to="sessions##create")
		.get(name="forgetme", to="sessions##forget")
		//=====================================================================
		//= 	User Registration
		//=====================================================================
		.get(name="register", pattern="register", to="register##new")
		.post(name="register", pattern="register", to="register##create")
		.get(name="verify", pattern="verify/[token]", to="register##verify")
		//=====================================================================
		//= 	Password Resets via Email
		//=====================================================================
		.scope(controller="passwordresets", path="password")
			.get(name="Passwordreset", pattern="forgot", action="new")
			.post(name="Passwordreset", pattern="forgot", action="create")
			.get(name="editPasswordreset", pattern="recover/[token]", action="edit")
			.put(name="updatePasswordreset", pattern="reset/[token]", action="update")
		.end()
		//=====================================================================
		//= 	Account
		//=====================================================================
		// Note: resource (singular!) to avoid [key], as this is specific to the logged in user
		.resource(name="account", only="show,edit,update")
		// So User can change their own password outside of a password reset email or if has been flagged by admin
		.get(name="accountPassword", pattern="/account/password", to="accounts##resetPassword")
		.put(name="accountPassword", pattern="/account/password", to="accounts##updatePassword")
		//=====================================================================
		//= 	Administration
		//=====================================================================
		.scope(path="admin", package="admin")
			.resources(name="users", nested=true)
				// userpermissions are nested in the user controller as they always act on a user
				.resources(name="permissions", controller="userpermissions", only="index,create,delete")
				// member() acts on an existing user
				.member()
					// These should never be GET, otherwise you have a possible CSRF attack
					.post("assume")
					.put("reset")
					.put("recover")
					.delete("destroy")
				.end()
			.end()
			.resources(name="settings", only="edit,update,index")
			.resources(name="permissions", only="edit,update,index")
			.resources(name="roles", except="show")
			.resources(name="logs", controller="auditlogs", only="index,show")
		.end()

		// The root route below is the one that will be called on your application's home page (e.g. http://127.0.0.1/).
		.root(to = "main##index", method = "get")
		.root(method = "get")
	.end();
</cfscript>
