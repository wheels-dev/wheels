/**
 * User Authentication Model
 * Template for user model with password hashing and authentication
 */
component extends="Model" {

    function config() {
        // Associations
        hasMany(name="sessions");

        // Validations
        validatesPresenceOf(property="email,password");
        validatesUniquenessOf(property="email", message="Email already registered");
        validatesFormatOf(
            property="email",
            regEx="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
            message="Please enter a valid email address"
        );
        validatesLengthOf(property="password", minimum=8, message="Password must be at least 8 characters");
        validatesConfirmationOf(property="password", message="Password confirmation doesn't match");

        // Callbacks
        beforeSave("hashPassword");
    }

    /**
     * Hash password before saving
     */
    private void function hashPassword() {
        if (structKeyExists(this, "password") && len(this.password) && !isHashed(this.password)) {
            this.password = hash(this.password, "SHA-512");
        }
    }

    /**
     * Check if password is already hashed
     */
    private boolean function isHashed(required string password) {
        return len(arguments.password) == 128; // SHA-512 hash length
    }

    /**
     * Authenticate user with email and password
     */
    public any function authenticate(required string email, required string password) {
        var user = this.findOne(where="email = '#arguments.email#'");

        if (!isObject(user)) {
            return false;
        }

        var hashedAttempt = hash(arguments.password, "SHA-512");

        if (user.password == hashedAttempt) {
            return user;
        }

        return false;
    }

    /**
     * Get user display name
     */
    public string function displayName() {
        if (structKeyExists(this, "firstName") && structKeyExists(this, "lastName")) {
            return this.firstName & " " & this.lastName;
        }
        return this.email;
    }

    /**
     * Check if user is active
     */
    public boolean function isActive() {
        return structKeyExists(this, "active") && this.active;
    }
}
