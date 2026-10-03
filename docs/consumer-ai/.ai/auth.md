# Authentication & Authorization

Part of the Wheels application guide; start with `../CLAUDE.md`.

One-command scaffold (4.0.6+): `wheels generate auth` emits a `User` model (PBKDF2 hashing via the `passwordHasher` service), `Sessions`/`Passwords`/`Registrations` controllers + views, a create-users migration, and wiring. Flags: `--model=<Name>` (default `User`), `--strategy=session|token|jwt`, `--registration`/`--no-registration`, `--force`.

Built-in strategies under `wheels.auth.*`: `Authenticator` (registry that tries strategies in order), `SessionStrategy`, `TokenStrategy`, `JwtStrategy`. Wire by hand in `config/services.cfm`, or collapse session wiring to one line:

```cfm
// config/services.cfm — registers + wires SessionStrategy (idempotent)
enableSession(sessionKey = "wheels.auth");
```

Password hashing: `wheels.auth.PasswordHasher` (PBKDF2-SHA256, 600k iterations; `hash()` / `verify()` / `needsRehash()`), and global pure-CFML bcrypt helpers (OpenBSD/jBCrypt-compatible):

```cfm
hash = bcryptHash(plaintext);                // cost defaults to 10
ok = bcryptVerify(plaintext, hash);          // constant-time
if (bcryptNeedsRehash(hash)) { /* rehash + save */ }
```

Authorization policies (4.0.6+): `wheels.Policy` base class + `app/policies/<Model>Policy.cfc`, generated with `wheels generate policy <Model>`. Helpers: `authorize(model)` (throws `Wheels.NotAuthorized` → 403 on deny, returns the record on allow), `can("action", model)` (boolean), `policyScope(model("Post"))` (no-rows scope on deny). Default-deny: every action denies unless the policy defines it.

## Return-to URLs after sign-in

`redirectTo(url=…)` refuses another host. Unless `allowExternalRedirects` is `true` (it's `false` by default), it throws `Wheels.UnsafeRedirect` for anything other than a relative URL or a URL on the current host. So you can pass a user-supplied `return_to` straight to it and fall back when it throws:

```cfm
// app/controllers/Sessions.cfc
function create() {
    // ... sign the user in ...
    if (Len(params.return_to ?: "")) {
        try {
            redirectTo(url = params.return_to);
            return;
        } catch (Wheels.UnsafeRedirect e) {
            // Another host: ignore it and land on the default page.
        }
    }
    redirectTo(route = "root");
}
```

- Catch `Wheels.UnsafeRedirect` rather than `any`, so other errors still surface.
- Keep the `return`. With delayed redirects (`delay=true`, which test runs use), the action would otherwise go on to call `redirectTo` a second time.
- Don't set `allowExternalRedirects=true` to make a return-to link work: it turns the check off for every redirect in the app.
- `redirectTo(back=true)` applies the same check to the referrer. If the referrer is on another host, it falls back to the `route` / `controller` / `action` you pass, or to the site root.
