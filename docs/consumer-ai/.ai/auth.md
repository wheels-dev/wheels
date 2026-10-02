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
