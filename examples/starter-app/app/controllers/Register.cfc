component extends="app.controllers.Controller"
{
	function config() {
		super.config(redirectAuthenticatedUsers=true);
		verifies(post=true, only="create");
		verifies(only="verify", params="token", paramsTypes="string", handler="badToken");
		filters(through="checkTokenAndGetUser", only="verify");
		filters(through="checkRegistrationIsAllowed");
	}

	/**
	* New Registration form
	**/
	function new(){
		user=model("user").new();
	}

	/**
	* New Registration form submission
	**/
	function create(){
		try{
			user=model("user").new();

			// Terms and Conditions checkbox
			if(structKeyExists(params.user, "terms") && params.user.terms)
				user.terms = 1;

			// Set properties manually
			user.firstname = params.user.firstname;
			user.lastname = params.user.lastname;
			user.email = params.user.email;
			user.password = params.user.password;
			user.passwordConfirmation = params.user.passwordConfirmation;

			// Role is protected property so we need to set it manually: Use the default role setting
			user.roleid = getSetting("authentication_defaultRole");

			// Whilst this should be default for a new user, let's implicitedly set it anyway.
			user.verified = 0;

			// Create verification token
			user.generateVerificationToken();

			if(user.save()){
				// Send Verification email and notify user
				sendEmail(to=user.email,
					from=getSetting("email_fromAddress"),
					subject="Account Verification",
					template="/emails/verify,/emails/verifyPlain",
					user=user
				);
				addlogline(type="email",  message="Account Verification Email Sent to #user.email#");
				redirectTo(route="root", success="Thank you for registering: please check your email for a link to complete your account registration");
			} else {
				renderView(action="new");
			}	
		}catch (any e) {
			redirectTo(action="new", error="Error: #e.message#");
		}
	}

	/**
	* Requires token: when a user clicks on a verify link in the verification email, this is what's loaded
	**/
	function verify(){
		try{
			user.verifyUser();
			user.save();
			redirectTo(route="login", success="Thank you for verifying your email address. You are now free to login");	
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	* Additional token checks, and get the user we're dealing with
	**/
	private function checkTokenAndGetUser() {
		user=model("user").findOneByVerificationtoken(params.token);
		if(!isObject(user)){
			badToken();
		}
	}

	/**
	* Check registration is allowed in the settings
	**/
	private function checkRegistrationIsAllowed() {
		 if(!getSetting("authentication_allowRegistration")){
		 	redirectTo(route="root", info="Registration is disabled. Please contact an administrator");
		 }
	}
	

	/**
	* This error gets thrown if the token is too old, not found, or simply malformed.
	**/
	private function badToken() {
		return redirectTo(route="root", error="You have followed an outdated or incorrect verification code");
	}

}
