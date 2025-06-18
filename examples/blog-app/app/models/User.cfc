component extends="Model" {
	
	function config() {
		// Associations
		hasMany("posts", foreignKey: "userId", dependent: "deleteAll");
		hasMany("comments", foreignKey: "userId", dependent: "deleteAll");
		
		// Properties
		property(name: "fullName", sql: "first_name || ' ' || last_name");
		
		// Validations
		validatesPresenceOf("email,username,password");
		validatesUniquenessOf("email,username");
		validatesFormatOf(
			property: "email",
			pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
			message: "Please enter a valid email address"
		);
		validatesLengthOf(property: "username", minimum: 3, maximum: 20);
		validatesLengthOf(property: "password", minimum: 8);
		validatesConfirmationOf("password");
		
		// Callbacks
		beforeCreate("hashPassword");
		beforeUpdate("hashPasswordIfChanged");
	}
	
	// Authentication methods
	public function authenticate(required string password) {
		if (len(this.passwordHash)) {
			return BCrypt.checkPassword(arguments.password, this.passwordHash);
		}
		return false;
	}
	
	public function generateAuthToken() {
		this.authToken = createUUID();
		this.authTokenExpiresAt = dateAdd("d", 30, now());
		this.save(validate: false);
		return this.authToken;
	}
	
	public function clearAuthToken() {
		this.authToken = "";
		this.authTokenExpiresAt = "";
		this.save(validate: false);
	}
	
	// Role checking
	public function isAdmin() {
		return this.role == "admin";
	}
	
	public function canEdit(required any post) {
		return this.isAdmin() || this.id == arguments.post.userId;
	}
	
	// Scopes
	public function scopeActive() {
		return where("active = ?", true);
	}
	
	public function scopeAdmins() {
		return where("role = ?", "admin");
	}
	
	// Utility methods
	public function displayName() {
		if (len(this.firstName) && len(this.lastName)) {
			return this.firstName & " " & this.lastName;
		} else if (len(this.firstName)) {
			return this.firstName;
		} else {
			return this.username;
		}
	}
	
	public function avatarUrl(numeric size = 80) {
		var hash = lcase(hash(lcase(trim(this.email)), "MD5"));
		return "https://www.gravatar.com/avatar/#hash#?s=#arguments.size#&d=mp";
	}
	
	// Private callback methods
	private function hashPassword() {
		if (len(this.password)) {
			this.passwordHash = BCrypt.hashPassword(this.password);
			// Clear the plain text password
			structDelete(this, "password");
		}
	}
	
	private function hashPasswordIfChanged() {
		if (structKeyExists(this, "password") && len(this.password)) {
			hashPassword();
		}
	}
}