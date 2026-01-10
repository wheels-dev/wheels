component extends="app.controllers.Controller" {

	function config() {
		super.config(restrictAccess=true);
		filters(through="getCurrentlyLoggedInUser");
	}

	/**
	* The Users account page
	**/
	function show(){}

	/**
	 * Load User account update form
	 */
	function edit() {}

	/**
	 * Save user account details
	 * We're being more explicit in what properties the user can update on their own account here
	 */
	function update() {
		try{
			user.firstname = params.user.firstname;
			user.lastname = params.user.lastname;
			user.email = params.user.email;
			if(user.save()){
				redirectTo(action="show", success="Account successfully updated");
			} else {
				renderView(action="edit");
			}	
		}catch (any e) {
			redirectTo(action="edit", error="Error: #e.message#");
		}
	}

	/**
	 * The Reset Password Form
	 */
	function resetPassword() {}

	/**
	 * Reset password action
	 */
	function updatePassword() {
		try{
			// Check old password
			if(!user.checkPassword(params.user.oldpassword))
				redirectTo(back=true, error="Your old password was incorrect");
			// Carry on
			user.password=params.user.password;
			user.passwordConfirmation=params.user.passwordConfirmation;

			if(user.save()){

				// If this has been completed as part of a forced password change, reset all the flags; don't do this until
				// the password change has been successful.
				if(hasPasswordResetBlock()){
					user.passwordChangeRequired=0;
					user.save();
					clearPasswordResetBlock();
				}

				redirectTo(action="show", success="Password successfully updated");
			} else {
				renderView(action="resetPassword");
			}	
		}catch (any e) {
			redirectTo(action="resetPassword", error="Error: #e.message#");
		}
	}

	/**
	* Gets the currently logged in user via their session ID (NOT via url params!)
	**/
	private function getCurrentlyLoggedInUser(){
		user =model("user").findOneByID(getSession().user.properties.id);
		if(!isObject(user)){
			objectNotFound();
		}
	};

	/**
	* Redirect away if object can't be found
	**/
	private function objectNotFound() {
		redirectTo(action="index", error="Sorry, your account can't be retrieved");
	}

}
