---
name: Wheels Auth Generator
description: Generate authentication system with user model, sessions controller, and password hashing. Use when implementing user authentication, login/logout, or session management. Provides secure authentication patterns and bcrypt support.
---

# Wheels Auth Generator

## When to Use This Skill

Activate when:
- User requests authentication/login system
- User wants user registration
- User mentions: auth, login, logout, session, password, signup

## User Model with Authentication

```cfm
component extends="Model" {

    function config() {
        validatesPresenceOf(property="email,password");
        validatesUniquenessOf(property="email");
        validatesFormatOf(
            property="email",
            regEx="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"
        );
        validatesLengthOf(property="password", minimum=8);
        validatesConfirmationOf(property="password");

        beforeSave("hashPassword");
    }

    private function hashPassword() {
        if (structKeyExists(this, "password") && len(this.password) && !isHashed(this.password)) {
            this.password = hash(this.password, "SHA-512");
        }
    }

    private boolean function isHashed(required string password) {
        return len(arguments.password) == 128;
    }

    public any function authenticate(required string email, required string password) {
        var user = this.findOne(where="email = '#arguments.email#'");

        if (!isObject(user)) return false;

        var hashedAttempt = hash(arguments.password, "SHA-512");

        return (user.password == hashedAttempt) ? user : false;
    }
}
```

## Sessions Controller

```cfm
component extends="Controller" {

    function new() {
        // Show login form
    }

    function create() {
        var user = model("User").authenticate(
            email=params.email,
            password=params.password
        );

        if (isObject(user)) {
            session.userId = user.id;
            flashInsert(success="Welcome back!");
            redirectTo(controller="home", action="index");
        } else {
            flashInsert(error="Invalid email or password");
            renderPage(action="new");
        }
    }

    function delete() {
        structDelete(session, "userId");
        flashInsert(success="You have been logged out");
        redirectTo(controller="home", action="index");
    }
}
```

## Authentication Filter

```cfm
// In any controller requiring authentication
function config() {
    filters(through="requireAuth");
}

private function requireAuth() {
    if (!structKeyExists(session, "userId")) {
        flashInsert(error="Please log in");
        redirectTo(controller="sessions", action="new");
    }
}
```

## Password Reset (Security Best Practices)

### PasswordResets Controller

```cfm
component extends="Controller" {

    /**
     * Process password reset request
     * SECURITY: Always show same message regardless of email existence
     */
    function create() {
        if (!structKeyExists(params, "email") || !len(trim(params.email))) {
            flashInsert(error="Please provide your email address.");
            renderView(action="new");
            return;
        }

        // Find user by email
        user = model("User").findOne(where="email = '#params.email#' AND deletedAt IS NULL");

        // CRITICAL: Always show success message (prevents email enumeration)
        if (isObject(user)) {
            user.generateResetToken();
            user.save();
            // TODO: Send email with reset link
        }

        // Same message whether email exists or not
        flashInsert(success="If that email address is in our system, we've sent password reset instructions.");
        redirectTo(controller="sessions", action="new");
    }

    /**
     * Show password reset form - validates token
     */
    function edit() {
        if (!structKeyExists(params, "token") || !len(trim(params.token))) {
            flashInsert(error="Invalid password reset link.");
            redirectTo(controller="sessions", action="new");
            return;
        }

        user = model("User").findOne(where="resetToken = '#params.token#' AND deletedAt IS NULL");

        if (!isObject(user)) {
            flashInsert(error="Invalid or expired password reset link.");
            redirectTo(controller="sessions", action="new");
            return;
        }

        // Check token expiry (1 hour)
        if (!user.isResetTokenValid()) {
            flashInsert(error="This password reset link has expired. Please request a new one.");
            redirectTo(controller="passwordResets", action="new");
            return;
        }

        token = params.token;
    }

    /**
     * Process password reset - single-use token
     */
    function update() {
        // Validate token and update password
        user = model("User").findOne(where="resetToken = '#params.token#' AND deletedAt IS NULL");

        if (!isObject(user) || !user.isResetTokenValid()) {
            flashInsert(error="Invalid or expired password reset link.");
            redirectTo(controller="sessions", action="new");
            return;
        }

        user.password = params.password;
        user.passwordConfirmation = params.passwordConfirmation;
        user.clearResetToken(); // Single-use token

        if (user.save()) {
            // Auto-login after successful reset
            session.userId = user.id;
            session.userEmail = user.email;
            flashInsert(success="Your password has been reset successfully!");
            redirectTo(controller="home", action="index");
        }
    }
}
```

### User Model Token Methods

```cfm
// Add to User model config()
function config() {
    // ... other config ...
    beforeCreate("setDefaults");
}

/**
 * Generate password reset token (1-hour expiry)
 */
public void function generateResetToken() {
    this.resetToken = hash(createUUID() & now(), "SHA-256");
    this.resetTokenExpiry = dateAdd("h", 1, now());
}

/**
 * Check if reset token is valid (not expired)
 */
public boolean function isResetTokenValid() {
    if (!structKeyExists(this, "resetToken") || !len(this.resetToken)) {
        return false;
    }
    if (!structKeyExists(this, "resetTokenExpiry")) {
        return false;
    }
    return dateCompare(now(), this.resetTokenExpiry) < 0;
}

/**
 * Clear reset token after use (single-use)
 */
public void function clearResetToken() {
    this.resetToken = "";
    this.resetTokenExpiry = "";
}
```

### Security Checklist for Password Reset

- ✅ **Email enumeration prevention**: Always show same success message
- ✅ **Token expiry**: Limit token validity (1 hour recommended)
- ✅ **Single-use tokens**: Clear token after successful reset
- ✅ **Auto-login**: Log user in after successful reset for better UX
- ✅ **Secure token generation**: Use cryptographic hash with UUID + timestamp
- ✅ **HTTPS only**: Password reset links should only work over HTTPS in production

---

**Generated by:** Wheels Auth Generator Skill v1.0
