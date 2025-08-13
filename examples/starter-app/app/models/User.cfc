component extends="Model" {

	function config() {

		super.config(logChanges=true);

		// Associations
		belongsTo("role");
		hasMany("userpermissions");

		// Properties
		validatesPresenceOf("firstname,lastname,email");
		validatesUniquenessOf("email");
		validatesFormatOf(property="email", allowBlank=true, type="email");

		// More Password Checks
		validate("additionalPasswordValidation");

		// When a user is created by registration (i.e, not being created by an authenticated user)
		// Then require the prescence of a checked terms and conditions box
		validatesPresenceOf(
			property="terms", when="onCreate", unless="isAuthenticated()",
			message="You must agree to the terms and conditions");

		// Protected certain properties from mass assignment
		protectedProperties("roleid,verified");

		// Callbacks
		beforeValidation("sanitize,setIgnoreLogProperties");
		beforeUpdate("setPasswordLastChanged");

		// Authenticate This Plugin
		// Handles passwordHash and passwordConfirmations
		authenticateThis();

	}

	/**
	* Sanitizes the user object
	*/
	function sanitize() {
		if(structKeyExists(this, "firstname"))
			this.firstname = sanitizeInput(this.firstname);
		if(structKeyExists(this, "lastname"))
			this.lastname = sanitizeInput(this.lastname);
		if(structKeyExists(this, "email"))
			this.email = sanitizeInput(this.email);
	}

	/**
	 * Check Password doesn't exist within Email
	 */
	function additionalPasswordValidation() {
		if(structKeyExists(this, "password")
			&& structKeyExists(this, "email")
			&& this.email CONTAINS this.password
		)
			this.addError(property="password", message="Your password should not be part of your email address");
	}

	/**
	* Generates a verification token on register
	*/
	function generateVerificationToken() {
		this.verificationToken	= $generateToken();
	}

	/**
	* Marks a user as verified
	*/
	function verifyUser() {
		this.verificationToken	= "";
		this.verified = 1;
	}

	/**
	* Generates a password reset token and sets the time token was created
	*/
	function generatePasswordResetToken() {
		this.passwordResetToken 	= $generateToken();
		this.passwordResetTokenAt 	= Now();
	}

	/**
	* Runs on successful password update via passwordresettoken
	* Will also get cleared on successful login
	*/
	function clearPasswordResetToken(){
		this.passwordResetToken = "";
		this.passwordResetTokenAt = "";
	}

	/**
	* When using the super.config() logging changed values feature, we might not want to log datasensitive values
	* Such as password hashes; it can be useful for development to leave this out so you can see exactly where things
	* are changing in more complex callbacks
	**/
	function setIgnoreLogProperties(){
		this.ignoreLogProperties = "password,passwordConfirmation,passwordHash,loggedinat";
	}

	/**
	* Update the passwordReset timestamp when the password changes: done as a call back so we don't have to duplicate
	* ourselves in password resets vs account resets
	**/
	function setPasswordLastChanged(){
		if(structKeyExists(this, "passwordHash") && this.hasChanged("passwordHash"))
			this.passwordResetAt = now();
	}

	/**
	* Internal: Generate a token for use in password reset emails
	**/
	function $generateToken() {
		return Replace(LCase(CreateUUID()), "-", "", "all");
	}

	function getUsers(required array where, required bool includeSoftDeletes, required number page, required number perpage) {
		return findAll(where=whereify(arguments.where), page=arguments.page, includeSoftDeletes=arguments.includeSoftDeletes, perpage=arguments.perpage, include="role");
	}

	function getUserById(required string key) {
		return findByKey(arguments.key);
	}

	function getUserRoleById(required string key) {
		return findByKey(key=arguments.key, include="role");
	}

	function createUser(required struct userData) {
		user=new(arguments.userData);
		// Protected properties we need to set manually
		user.roleid = arguments.userData.roleid;
		user.verified = arguments.userData.verified;
		if(user.save()) {
			return true;
		} else {
		  return false;
		}
	}

	function updateUserByKey(required string key, required struct userData) {
		user=getUserById(arguments.key);
		// Protected properties we need to set manually
		user.roleid = arguments.userData.roleid;
		user.verified = arguments.userData.verified;
		if (user.update(arguments.userData)) {
			return true;
		} else {
		  return false;
		}
	}

	function softDeleteUser(required string key) {
		if (deleteByKey(arguments.key)) {
			return true;
		} else {
			return false;
		}
	}
	
	function deleteUser(required string key) {
		if (deleteByKey(key=arguments.key, includeSoftDeletes=true, softDelete=false)) {
			return true;
		} else {
			return false;
		}
	}
	
	function recoverUser(required string key) {
		if (updateByKey(key=arguments.key, includeSoftDeletes=true, deletedAt = "")) {
			return true;
		} else {
			return false;
		}
	}

}
