# [Feature] Authentication & Authorization Scaffolding Generator (`wheels generate auth`)

**Priority:** #1 — Highest priority competitive gap
**Labels:** `enhancement`, `feature-request`, `priority-high`

## Summary

Add a `wheels generate auth` CLI command that produces a complete, working authentication system out of the box — covering user registration, login/logout, password reset, email verification, and session management.

## Justification

### Every competitor has this — it's table-stakes for 2025-2026

| Framework | Auth Generator | Details |
|-----------|---------------|---------|
| **Laravel** | `Breeze` / `Jetstream` | Full UI scaffolding with 2FA, API tokens, team management |
| **Rails 8** | `rails generate authentication` | Built-in since Rails 8 — session-based with password reset |
| **Phoenix 1.8** | `mix phx.gen.auth` | Magic links, sudo mode, token-based |
| **Django** | `django.contrib.auth` | Built-in module — always been included |
| **AdonisJS 6** | Built-in auth module | Session + token guards, social auth |
| **Wheels** | **Nothing** | Manual patterns + legacy `authenticateThis` plugin |

### First thing developers need

Nearly every web app requires authentication. Having to manually wire it up (or use a Wheels 2.0-era plugin) creates immediate friction for new adopters evaluating the framework. When a developer runs `wheels new myapp`, the next question is almost always "how do I add login?" — and right now, the answer is "figure it out yourself."

### Foundation for other features

Authorization policies (#6), API tokens, multi-channel notifications (#3), and role-based access control all depend on having a solid, standardized auth layer. Building auth first unblocks multiple downstream features.

### Existing building blocks are already in place

Wheels already has all the pieces — they just need to be wired into a single generator:

- **`authenticateThis` plugin** — BCrypt hashing, password validation
- **Documentation patterns** — `.ai/wheels/patterns/authentication.md`
- **Controller filter system** — `filters(through="requireLogin")` with before/after support
- **Session management** — `session.userId`, flash messages
- **Mailer system** — `app/mailers/` for password reset and verification emails
- **CSRF protection** — Built-in token verification
- **Background jobs** — `app/jobs/` for async email delivery
- **Starter app examples** — Reference implementations

## Specification

### Files `wheels generate auth` should produce

| Component | File(s) Generated | Purpose |
|-----------|-------------------|---------|
| **Migration** | `[timestamp]_create_users_table.cfc` | Users table with email, passwordHash, salt, rememberToken, emailVerifiedAt, timestamps |
| **Model** | `app/models/User.cfc` | Validations, BCrypt hashing, `authenticate()` method, role association |
| **Controller** | `app/controllers/Sessions.cfc` | Login (`new`/`create`) and logout (`delete`) actions |
| **Controller** | `app/controllers/Registrations.cfc` | Registration/signup flow (`new`/`create`) |
| **Controller** | `app/controllers/Passwords.cfc` | Forgot password (`new`/`create`) and reset (`edit`/`update`) |
| **Views** | `app/views/sessions/new.cfm` | Login form with email/password |
| **Views** | `app/views/registrations/new.cfm` | Registration form |
| **Views** | `app/views/passwords/new.cfm` | Forgot password (enter email) |
| **Views** | `app/views/passwords/edit.cfm` | Reset password (enter new password) |
| **Email templates** | `app/views/mailers/auth/` | Password reset and email verification templates |
| **Routes** | Injected into `config/routes.cfm` | Named auth routes (see below) |
| **Mailer** | `app/mailers/AuthMailer.cfc` | `sendPasswordReset()`, `sendEmailVerification()` |
| **Tests** | `tests/models/UserTest.cfc` | Validation, hashing, and authentication tests |
| **Tests** | `tests/controllers/SessionsTest.cfc` | Login/logout integration tests |
| **Global helper** | `app/global/auth.cfm` | `currentUser()`, `isLoggedIn()`, `requireAuth()` |

### Routes Generated

```cfm
// Injected into config/routes.cfm
.get(name="login", to="sessions##new")
.post(name="authenticate", to="sessions##create")
.delete(name="logout", to="sessions##delete")
.get(name="register", to="registrations##new")
.post(name="createRegistration", to="registrations##create")
.get(name="forgotPassword", to="passwords##new")
.post(name="sendPasswordReset", to="passwords##create")
.get(name="resetPassword", to="passwords##edit")
.patch(name="updatePassword", to="passwords##update")
```

### Core Authentication Flow

```
Registration:  Form → Create user (BCrypt hash) → Auto-login → Redirect to dashboard
Login:         Form → Verify credentials (BCrypt compare) → Create session → Redirect to intended URL
Logout:        Delete session → Flash "logged out" → Redirect to login
Forgot:        Form → Generate secure token → Store hashed token in DB → Send reset email
Reset:         Link with token → Verify token (< 1 hour) → Update password → Auto-login
```

### User Model Structure

```cfm
component extends="Model" {
    function config() {
        // Validations
        validatesPresenceOf(properties="email,firstName,lastName");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");
        validatesLengthOf(property="password", minimum=8, when="onCreate");
        validatesConfirmationOf(property="password", when="onCreate");

        // Callbacks
        beforeSave("hashPassword");

        // Properties
        property(name="password", sql="''", label="Password");
        property(name="passwordConfirmation", sql="''", label="Password Confirmation");
    }

    public boolean function authenticate(required string password) {
        return BCrypt.checkpw(arguments.password, this.passwordHash);
    }

    private function hashPassword() {
        if (hasChanged("password") && Len(this.password)) {
            this.passwordHash = BCrypt.hashpw(this.password, BCrypt.gensalt(12));
        }
    }
}
```

### Global Auth Helpers

```cfm
// app/global/auth.cfm
public any function currentUser() {
    if (StructKeyExists(session, "userId") && !StructKeyExists(request, "_currentUser")) {
        request._currentUser = model("User").findByKey(session.userId);
    }
    return StructKeyExists(request, "_currentUser") ? request._currentUser : false;
}

public boolean function isLoggedIn() {
    return IsObject(currentUser());
}

public void function requireAuth() {
    if (!isLoggedIn()) {
        flashInsert(error="Please log in to continue.");
        redirectTo(route="login");
    }
}
```

### Stretch Goals (v1.1+)

- **`--api` flag:** Token-based API authentication (like Laravel Sanctum) — generates API token migration, token model, and Bearer auth middleware
- **`--2fa` flag:** TOTP two-factor authentication — generates secret key column, QR code setup view, verification step
- **Remember me:** Persistent sessions via secure cookie + database token
- **Account lockout:** Lock after N failed attempts with configurable cooldown
- **Email verification:** Confirmation link flow with `emailVerifiedAt` timestamp
- **Social auth:** OAuth2 integration with configurable providers

## Impact Assessment

- **Developer experience:** Removes the #1 friction point for new adopters
- **Competitive positioning:** Closes the most visible gap vs. Laravel, Rails, Phoenix, Django, and AdonisJS
- **Feature parity:** Moves Wheels from ~55% to ~65% of table-stakes features
- **Downstream enablement:** Unblocks authorization policies, API tokens, and notification systems

## References

- Laravel Breeze: https://laravel.com/docs/starter-kits
- Rails 8 Authentication: https://guides.rubyonrails.org/getting_started.html
- Phoenix phx.gen.auth: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
- Existing Wheels `authenticateThis` plugin
- `.ai/wheels/patterns/authentication.md` documentation
