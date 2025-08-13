component extends="app.models.Model"
/*
	Authentication Tableless Model
	All these actions need to operate outside the central permissions system
*/
{
	function config() {
		table(false);
		property(name="name", defaultValue="Local Authentication Gateway");
		property(name="rememberme", defaultValue=false);
		property(name="allowPasswordReset", defaultValue=true);
		property(name="allowRememberMe", defaultValue=true);
		property(name="allowUserRegistration", defaultValue=true);
		validatesPresenceOf(properties="email,password");
		validatesFormatOf(property="email", allowBlank=true, type="email");
		// authenticateThis(required=false);
	}

	// Authenticates
	boolean function login(){
		if(this.valid() && this.authenticate()){
			if(!structKeyExists(request, "isTestingMode")){
				// Call SessionRotate() after a successful login to prevent session fixation attacks
				sessionRotate();
			}
			return true;
		} else {
			return false;
		}
	}

	function logout(){
		// Called when attempting to log a user out: it might be that an external/other authentiation method
		// Needs to do something else here. For local auth we'll just log the action probably
	}


	// Returns true is authentication is successful
	// For an external auth method, this might include LDAP/Remote stuff
	boolean function authenticate(){
		// Find the local user account
		local.user=model("user").findOne(where="email = '#this.email#'");
		if(!isObject(local.user)){
			this.addError(property="email", message="Sorry, we couldn't log you in");
			return false;
		} else {
			// Check this account isn't pending verification
			if(!local.user.verified){
				this.addErrorToBase(message="Sorry, your account is still pending verification");
				return false;
			}

			// Check the pw
			if(local.user.checkPassword(this.password)){
				assignPermissions(local.user);
				postLogin(local.user);
				return true;
			} else {
				this.addError(property="password", message="Sorry, we couldn't log you in");
				return false;
			}
		}
	}

	/**
	* Runs after a successful login, but before redirection
	**/
	function postLogin(user){
		// Check for "remember me" checkbox and assign cookie
		if(this.allowRememberMe && this.rememberme){
			 setCookieRememberEmail(arguments.user.email);
		}
		// This isn't a true "keep me logged in" system, simply remembers the email address used to sign in.
		// Update User's last login time
		arguments.user.Loggedinat=now();

		// If the user has requested a password reset email, but then managed to login normally (i.e, ignored the email),
		// then remove the Password reset token, as there's a potential 2 hour window of attack
		arguments.user.clearPasswordResetToken();
		arguments.user.save();

		// Check for password reset requirement: this might have been triggered by an admin resetting the password
		// Or perhaps some other condition such as time since last reset
		if(arguments.user.passwordchangerequired){
			createPasswordResetBlock();
		}

	}

}
