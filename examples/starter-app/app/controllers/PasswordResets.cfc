component extends="app.controllers.Controller"
{
	function config() {
		super.config(redirectAuthenticatedUsers=true);
		verifies(post=true, only="create");
		verifies(only="edit", params="token", paramsTypes="string", handler="badToken");
		verifies(only="create", params="email", paramsTypes="email", handler="genericError");
		filters(through="checkTokenAndGetUser", only="edit,update");
		filters(through="checkPasswordResetsAreAllowed");
	}

	/**
	* New Forgot password form
	**/
	function new(){}

	/**
	* New Forgot password form submission to create passwordReset
	**/
	function create(){
		try{
			user=model("user").findOneByEmail(params.email);
			if(!isObject(user)){
				genericError();
			} else {
				// Check this account isn't pending verification
				if(!user.verified){
					redirectTo(route="login", error="Sorry, your account is still pending verification");
				}

				// Generate and save token
				user.generatePasswordResetToken();
				if(!user.save()){
					genericError();
				} else {
					// Send Reset Email
					if(getSetting("email_send")){
						sendEmail(
							to=user.email,
							from=getSetting("email_fromAddress"),
							subject="Password Reset Request",
							template="/emails/passwordReset,/emails/passwordResetPlain",
							user=user);
					}
					return redirectTo(route="login", success="A password reset email has been sent to you!");
				}
			}	
		}catch (any e) {
			redirectTo(action="new", error="Error: #e.message#");
		}
	}

	/**
	* Requires token: when a user clicks on a reset password link in the password reset email, this is what's loaded
	**/
	function edit(){}

	/**
	* Reset the Password: still requires token, but passed through as a hidden form field
	* We're explicitedly setting values here rather than doing user.update(params) as that might enable them to update
	* Other properties. Which would be bad.
	**/
	function update(){
		try{
			user.password=params.user.password;
			user.passwordConfirmation=params.user.passwordConfirmation;
			if(user.save()){
				// Remove password reset token etc
				user.clearPasswordResetToken();
				// Resave
				user.save();
				redirectTo(route="login", success="Your password has been updated and you're free to login");
			} else {
				renderView(action="edit");
			}	
		}catch (any e) {
			redirectTo(action="edit", error="Error: #e.message#");
		}
	}

	/**
	* This error is deliberately generic. If we're too detailed, we might give away whether an account exists or not,
	* Which could help a potential attacker
	**/
	private function genericError() {
		return redirectTo(route="passwordreset", error="Sorry, we couldn't complete your request");
	}

	/**
	* Additional token checks, and get the user we're dealing with
	**/
	private function checkTokenAndGetUser() {
		user=model("user").findOneByPasswordresettoken(params.token);
		// Valid User? && Token age is less than two hours?
		if(!isObject(user) || DateDiff("h", user.passwordResetTokenAt, Now()) > 2 ){
			badToken();
		}
	}

	/**
	* Check registration is allowed in the settings
	**/
	private function checkPasswordResetsAreAllowed() {
		 if(!getSetting("authentication_allowPasswordResets")){
		 	redirectTo(route="root", info="This feature is disabled. Please contact an administrator");
		 }
	}


	/**
	* This error gets thrown if the token is too old, not found, or simply malformed.
	**/
	private function badToken() {
		return redirectTo(route="passwordreset", error="You have followed an outdated or incorrect reset code");
	}

}
