# User Authentication Model

## Description
Comprehensive user authentication and profile management model demonstrating advanced Wheels patterns including security, validation, callbacks, and role-based permissions.

## Full Implementation Example

### Complete User Authentication Model
```cfm
/**
 * User Model - User authentication and profile management
 */
component extends="Model" {

    function config() {
        // Associations
        hasOne("profile");
        hasMany("posts", foreignKey="authorid");
        hasMany("comments");
        hasMany("sessions");
        hasMany("loginAttempts");
        hasMany("userRoles");
        hasMany("roles", through="userRoles");

        // Validations
        validatesPresenceOf("email,username");
        validatesUniquenessOf("email,username");
        validatesLengthOf(property="username", minimum=3, maximum=50);
        validatesLengthOf(property="password", minimum=8, when="onCreate");
        validatesFormatOf(property="email", with="^[^\s@]+@[^\s@]+\.[^\s@]+$");
        validatesConfirmationOf(property="password", when="onCreate");

        // Custom validations
        validate(method="validatePasswordStrength", when="onCreate");
        validate(method="validateUsernameFormat");

        // Custom properties
        property(name="isactive", type="boolean", defaultValue=true);
        property(name="lastloginat", type="timestamp");
        property(name="logincount", type="integer", defaultValue=0);
        property(name="failedloginattempts", type="integer", defaultValue=0);
        property(name="lockeduntil", type="timestamp");
        property(name="emailverifiedat", type="timestamp");
        property(name="twofactorenabled", type="boolean", defaultValue=false);

        // Virtual properties
        property(name="fullName", sql=false);
        property(name="isLocked", sql=false);
        property(name="isEmailVerified", sql=false);

        // Callbacks
        beforeCreate("generateVerificationToken");
        beforeSave("hashPasswordIfChanged");
        afterCreate("sendVerificationEmail");
        afterUpdate("logProfileChanges");

        // Soft delete enabled automatically if deletedat column exists

        // Automatic timestamps
        set(timeStampOnCreateProperty="createdAt");
        set(timeStampOnUpdateProperty="updatedAt");
    }

    /**
     * Authenticate user with email/username and password
     */
    static function authenticate(required string identifier, required string password) {
        // Find user by email or username
        local.user = model("User").findOne(
            where="(email = '#arguments.identifier#' OR username = '#arguments.identifier#') AND deletedat IS NULL"
        );

        if (!isObject(local.user)) {
            return {success: false, error: "Invalid credentials"};
        }

        // Check if account is locked
        if (local.user.getIsLocked()) {
            return {success: false, error: "Account is temporarily locked"};
        }

        // Verify password
        if (local.user.verifyPassword(arguments.password)) {
            // Update login statistics
            local.user.recordSuccessfulLogin();
            return {success: true, user: local.user};
        } else {
            // Record failed attempt
            local.user.recordFailedLogin();
            return {success: false, error: "Invalid credentials"};
        }
    }

    /**
     * Verify password against stored hash
     */
    function verifyPassword(required string password) {
        return hash(arguments.password & this.salt, "SHA-256") == this.passwordHash;
    }

    /**
     * Get user's full display name
     */
    function getFullName() {
        if (len(this.firstname) && len(this.lastname)) {
            return this.firstname & " " & this.lastname;
        } else if (len(this.firstname)) {
            return this.firstname;
        } else if (len(this.lastname)) {
            return this.lastname;
        } else {
            return this.username;
        }
    }

    /**
     * Check if account is locked
     */
    function getIsLocked() {
        return isDate(this.lockeduntil) && this.lockeduntil > now();
    }

    /**
     * Check if email is verified
     */
    function getIsEmailVerified() {
        return isDate(this.emailverifiedat);
    }

    /**
     * Check if user has specific role
     */
    function hasRole(required string roleName) {
        return this.roles().exists(where="name = '#arguments.roleName#'");
    }

    /**
     * Check if user has any of the specified roles
     */
    function hasAnyRole(required string roleNames) {
        local.roleList = listToArray(arguments.roleNames);
        return this.roles().exists(where="name IN (#roleList#)");
    }

    /**
     * Check if user has permission
     */
    function hasPermission(required string permission) {
        return this.roles().joins("INNER JOIN rolePermissions rp ON roles.id = rp.roleid")
                          .joins("INNER JOIN permissions p ON rp.permissionId = p.id")
                          .exists(where="p.name = '#arguments.permission#'");
    }

    /**
     * Add role to user
     */
    function addRole(required string roleName) {
        local.role = model("Role").findOne(where="name = '#arguments.roleName#'");
        if (isObject(local.role) && !this.hasRole(arguments.roleName)) {
            model("UserRole").create(userid=this.id, roleid=local.role.id);
        }
    }

    /**
     * Remove role from user
     */
    function removeRole(required string roleName) {
        local.role = model("Role").findOne(where="name = '#arguments.roleName#'");
        if (isObject(local.role)) {
            model("UserRole").deleteAll(where="userid = '#this.id#' AND roleid = '#local.role.id#'");
        }
    }

    /**
     * Generate password reset token
     */
    function generatePasswordResetToken() {
        this.passwordResetToken = createUUID();
        this.passwordResetExpires = dateAdd("h", 2, now()); // 2 hour expiry
        return this.save();
    }

    /**
     * Reset password with token
     */
    function resetPassword(required string token, required string newPassword) {
        if (this.passwordResetToken != arguments.token ||
            !isDate(this.passwordResetExpires) ||
            this.passwordResetExpires < now()) {
            return {success: false, error: "Invalid or expired reset token"};
        }

        // Validate new password
        this.password = arguments.newPassword;
        this.passwordConfirmation = arguments.newPassword;

        if (!this.valid()) {
            return {success: false, errors: this.allErrors()};
        }

        // Clear reset token and save
        this.passwordResetToken = "";
        this.passwordResetExpires = "";

        if (this.save()) {
            return {success: true, message: "Password updated successfully"};
        } else {
            return {success: false, error: "Failed to update password"};
        }
    }

    /**
     * Verify email with token
     */
    function verifyEmail(required string token) {
        if (this.emailVerificationToken == arguments.token) {
            this.emailverifiedat = now();
            this.emailVerificationToken = "";
            return this.save();
        }
        return false;
    }

    /**
     * Record successful login
     */
    function recordSuccessfulLogin() {
        this.lastloginat = now();
        this.logincount = this.logincount + 1;
        this.failedloginattempts = 0;
        this.lockeduntil = "";
        this.save();

        // Clean up old login attempts
        this.loginAttempts().deleteAll(where="createdat < '#dateAdd("d", -7, now())#'");
    }

    /**
     * Record failed login attempt
     */
    function recordFailedLogin() {
        this.failedloginattempts = this.failedloginattempts + 1;

        // Lock account after 5 failed attempts
        if (this.failedloginattempts >= 5) {
            this.lockeduntil = dateAdd("n", 30, now()); // 30 minutes
        }

        this.save();

        // Log failed attempt
        model("LoginAttempt").create(
            userid = this.id,
            ipAddress = getClientIP(),
            success = false,
            attemptedAt = now()
        );
    }

    /**
     * Find active users only
     */
    function findActive() {
        return findAll(where="isactive = 1 AND deletedat IS NULL");
    }

    /**
     * Find email verified users
     */
    function findEmailVerified() {
        return findAll(where="emailverifiedat IS NOT NULL");
    }

    /**
     * Find users with specific role
     */
    function findWithRole(required string roleName) {
        return findAll(
            include="userRoles(role)",
            where="roles.name = '#arguments.roleName#'"
        );
    }

    // Callback methods

    /**
     * Callback: Generate email verification token
     */
    private void function generateVerificationToken() {
        this.emailVerificationToken = createUUID();
        this.salt = generateSalt();
    }

    /**
     * Callback: Hash password if it has changed
     */
    private void function hashPasswordIfChanged() {
        if (hasChanged("password") && len(this.password)) {
            this.passwordHash = hash(this.password & this.salt, "SHA-256");
            // Clear plain text password
            this.password = "";
            this.passwordConfirmation = "";
        }
    }

    /**
     * Callback: Send verification email after creation
     */
    private void function sendVerificationEmail() {
        local.mailer = createObject("component", "mailers.UserMailer");
        local.mailer.emailVerification(
            user = this,
            token = this.emailVerificationToken
        );
    }

    /**
     * Callback: Log significant profile changes
     */
    private void function logProfileChanges() {
        local.significantFields = "email,username,isactive";
        local.changedFields = changedProperties();

        for (local.field in local.changedFields) {
            if (listFindNoCase(local.significantFields, local.field)) {
                model("UserAuditLog").create(
                    userid = this.id,
                    action = "profile_change",
                    field = local.field,
                    oldValue = local.changedFields[local.field].oldValue,
                    newValue = local.changedFields[local.field].newValue,
                    changedAt = now()
                );
            }
        }
    }

    // Validation methods

    /**
     * Custom validation: Password strength
     */
    private void function validatePasswordStrength() {
        if (len(this.password)) {
            local.errors = [];

            // Check length
            if (len(this.password) < 8) {
                arrayAppend(local.errors, "must be at least 8 characters long");
            }

            // Check for uppercase letter
            if (!reFindNoCase("[A-Z]", this.password)) {
                arrayAppend(local.errors, "must contain at least one uppercase letter");
            }

            // Check for lowercase letter
            if (!reFindNoCase("[a-z]", this.password)) {
                arrayAppend(local.errors, "must contain at least one lowercase letter");
            }

            // Check for number
            if (!reFindNoCase("[0-9]", this.password)) {
                arrayAppend(local.errors, "must contain at least one number");
            }

            // Check for special character
            if (!reFindNoCase("[^A-Za-z0-9]", this.password)) {
                arrayAppend(local.errors, "must contain at least one special character");
            }

            if (arrayLen(local.errors)) {
                addError(property="password", message="Password #arrayToList(local.errors, ', ')#");
            }
        }
    }

    /**
     * Custom validation: Username format
     */
    private void function validateUsernameFormat() {
        if (len(this.username)) {
            // Check for valid characters
            if (reFindNoCase("[^A-Za-z0-9_-]", this.username)) {
                addError(property="username", message="Username can only contain letters, numbers, hyphens, and underscores");
            }

            // Check for reserved usernames
            local.reserved = "admin,administrator,root,system,api,www,mail,ftp";
            if (listFindNoCase(local.reserved, this.username)) {
                addError(property="username", message="This username is not available");
            }
        }
    }

    // Helper methods

    /**
     * Generate cryptographic salt
     */
    private string function generateSalt() {
        return hash(createUUID() & now() & randRange(1, 100000), "MD5");
    }

    /**
     * Get client IP address
     */
    private string function getClientIP() {
        if (structKeyExists(cgi, "http_x_forwarded_for") && len(cgi.http_x_forwarded_for)) {
            return listFirst(cgi.http_x_forwarded_for);
        } else {
            return cgi.remote_addr ?: "0.0.0.0";
        }
    }
}
```

## Key Features Demonstrated

### Advanced Security
- Password hashing with salt
- Account locking after failed attempts
- Email verification workflow
- Password reset with token expiration
- Role-based permissions
- Audit logging for profile changes

### Comprehensive Validation
- Built-in validations (presence, uniqueness, format)
- Custom password strength validation
- Username format validation
- Reserved username prevention

### User Management
- Authentication with email or username
- Role assignment and permission checking
- Profile management with change tracking
- Login attempt tracking and statistics

### Database Design
Virtual properties for calculated fields and complex associations through join tables for role management.

## Usage Examples

### Authentication
```cfm
// In controller
result = model("User").authenticate(params.email, params.password);
if (result.success) {
    session.user = result.user;
    redirectTo(route="dashboard");
} else {
    flash.error = result.error;
    renderView(action="login");
}
```

### Role Management
```cfm
user = model("User").findByKey(params.key);
user.addRole("administrator");
if (user.hasPermission("users.delete")) {
    // Allow user deletion
}
```

### Password Reset
```cfm
user = model("User").findByEmail(params.email);
user.generatePasswordResetToken();
// Send reset email with token
```

## Related Documentation
- [Model Associations](./associations.md)
- [Model Validations](./validations.md)
- [Model Callbacks](./callbacks.md)
- [Security Best Practices](../../security/authentication.md)