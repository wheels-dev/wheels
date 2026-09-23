---
name: Wheels Auth Generator
description: Generate authentication system with user model, sessions controller, and password hashing. Use when implementing user authentication, login/logout, or session management. Uses the framework PasswordHasher (PBKDF2-SHA256) for password storage.
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
        // Only hash a newly supplied plaintext password
        if (structKeyExists(this, "password") && len(this.password)) {
            this.passwordHash = service("passwordHasher").hash(this.password);
            structDelete(this, "password");
        }
    }

    public any function authenticate(required string email, required string password) {
        var user = this.findOne(where = "email = '#arguments.email#'");
        if (!isObject(user)) return false;
        return service("passwordHasher").verify(arguments.password, user.passwordHash) ? user : false;
    }
}
```

Register the hasher once in `config/services.cfm`: `injector().map("passwordHasher").to("wheels.auth.PasswordHasher").asSingleton();`. Store the hash in a `passwordHash` column, never the plaintext `password`.

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

