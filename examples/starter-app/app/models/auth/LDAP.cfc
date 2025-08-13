component extends="app.models.Model"
/*
	LDAP Authentication Tableless Model
	All these actions need to operate outside the central permissions system
*/
{
	function config() {
		table(false);
		property(name="name", defaultValue="LDAP Authentication Gateway");
		property(name="allowPasswordReset", defaultValue=false);
		property(name="allowRememberMe", defaultValue=false);
		validatesPresenceOf(properties="email,password");
	}

	// Authenticates
	boolean function login(){
		if(this.valid() && this.authenticate()){
			// Call SessionRotate() after a successful login to prevent session fixation attacks
			sessionRotate();
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
		doLDAPCall();
		// Find the local user account
		//local.user=model("user").findOne(where="email = '#this.email#'");
		//if(!isObject(local.user)){
		//	this.addError(property="email", message="Sorry, we couldn't log you in");
		//	return false;
		//} else {
			// If Found, check the pw
			// Hash password for AuthenticateThis
			//this.hashPassword();

			//if(local.user.checkPassword(this.passwordHash)){
				//assignPermissions(local.user);
				//local.user.Loggedinat=now();
				//local.user.save();
				//return true;
			//} else {
				//this.addError(property="password", message="Sorry, we couldn't log you in");
				//return false;
			//}
		//}
	}

	/**
		TEST LDAP Server Information (read-only access):

		Server: ldap.forumsys.com
		Port: 389

		Bind DN: cn=read-only-admin,dc=example,dc=com
		Bind Password: password

		All user passwords are password.

		You may also bind to individual Users (uid) or the two Groups (ou) that include:

		ou=mathematicians,dc=example,dc=com

		riemann
		gauss
		euler
		euclid
		ou=scientists,dc=example,dc=com

		einstein
		newton
		galieleo
		tesla

		Obviously, you will need to alter this function significantly to match your LDAP server environment
	*/
	function doLDAPCall(){

		local.server    = "ldap.forumsys.com";
		local.port      = 389;
		local.dn        = "cn=read-only-admin,dc=example,dc=com";
		local.start     = "dc=example,dc=com";
		local.username  = "einstein";
		local.password  = "password";

		cfldap(
			server = local.server,
			port = local.port,
			dn = local.dn,
			action = "QUERY",
			name = "qLDAPLookup",
			password = local.password,
			start = local.start,
			attributes = "*",
			scope = "subtree",
			filter = "(sn=#local.username#)"
		);

		writeDump(qLDAPLookup);
		abort;
		if (qLDAPLookup.recordCount) {
			userAuthenticated = true;
		}
	}

}
