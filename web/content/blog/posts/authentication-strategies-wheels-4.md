---
title: 'One Authenticator, Three Doors: Sessions, Tokens, and JWTs in Wheels 4'
slug: authentication-strategies-wheels-4
publishedAt: '2026-07-10T14:00:00.000Z'
updatedAt: '2026-07-06T05:06:04.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - authentication
  - security
  - jwt
categories: []
excerpt: >-
  Wheels 4 ships session, API-token, and JWT authentication as pluggable
  strategies behind one Authenticator registry. Wiring up all three doors —
  with the sharp edges: private filters, dynamic finders, the 32-byte JWT
  secret minimum, and the inline-closure constructor that crashes Adobe
  ColdFusion.
coverImage: null
---

Every Wheels app eventually grows the same three doors: a login form for humans, an API key for the reporting script somebody wrote in finance, and a JWT for the mobile app that marketing swears is launching this quarter. In Wheels 3 you built all three doors yourself, usually as three different filters with three different ideas about what "the current user" means.

Wheels 4 ships the pattern as first-class components: one `Authenticator` registry, three strategies, one result shape. This post wires up all three — with the sharp edges called out, including one that crashes Adobe ColdFusion's compiler if you hold it wrong.

## The pieces

Four components under `wheels.auth.*`:

| Component | Role |
|-----------|------|
| `Authenticator` | Registry that tries registered strategies in order and returns the first success |
| `SessionStrategy` | Reads a principal struct from the `session` scope; handles login/logout |
| `TokenStrategy` | Validates an `Authorization: Bearer <token>` header against a validator callback or a static token map |
| `JwtStrategy` | Validates a signed JWT via `JwtService` |

Each strategy implements a small interface — `getName()`, `supports(request)`, `authenticate(request)`. The authenticator walks its registry, picks the first strategy whose `supports()` returns true, runs it, and hands back one result shape no matter which door the request came through:

```cfm
{
    success: true,
    principal: { id: 42, email: "alice@example.com", role: "admin" },
    strategy: "session",
    error: "",
    statusCode: 200
}
```

Your controllers read `result.success` and `result.principal` and never care which strategy fired. That indirection is the entire value proposition: adding a fourth door later means registering one more strategy, not touching a single controller.

## Door one: sessions

Register both components in `config/services.cfm` — the DI container makes them singletons, which is correct because the authenticator keeps its registry in instance state:

```cfm
local.di = injector();

local.di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
local.di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();
```

Wire the strategy into the authenticator at app init:

```cfm
if (StructKeyExists(application, "wheelsdi") && application.wheelsdi.containsInstance("authenticator")) {
    var auth = service("authenticator");
    if (!auth.hasStrategy("session")) {
        auth.registerStrategy(name="session", strategy=service("sessionStrategy"));
    }
}
```

Then your login controller verifies credentials however you like and calls `login()` with whatever principal struct you want round-tripped:

```cfm
function create() {
    // Dynamic finder — binds the value for you; never interpolate params into where=
    user = model("User").findOneByEmail(LCase(Trim(params.email ?: "")));
    if (IsObject(user) && user.authenticate(params.password ?: "")) {
        service("sessionStrategy").login(principal={id: user.id, email: user.email});
        redirectTo(route="posts", success="Welcome back.");
    } else {
        flashInsert(error="Invalid email or password");
        redirectTo(route="login");
    }
}

function delete() {
    service("sessionStrategy").logout();
    redirectTo(route="login", success="Logged out.");
}
```

Protecting actions is a filter that asks the authenticator:

```cfm
function config() {
    filters(through="authenticate", except="index,show");
}

private function authenticate() {
    var result = service("authenticator").authenticate(request);
    if (!result.success) {
        flashInsert(error="Please log in first");
        redirectTo(route="login");
    }
}
```

**Sharp edge #1: the filter must be `private`.** A `public` function on a controller is a routable action — Wheels will cheerfully serve `/posts/authenticate` and execute your filter body as a page. This is the single most common auth mistake in Wheels code review, and it's invisible until someone finds the URL.

**Sharp edge #2: use the dynamic finder for the email lookup.** `findOneByEmail(value)` binds the value as a query parameter. The tempting alternative — `findOne(where="email='#params.email#'")` — interpolates user input straight into SQL. There is no parameterized `values={}` argument on `findOne()`; the injection-safe options are dynamic finders and the [chainable query builder](https://guides.wheels.dev/v4-0-0/basics/query-builder-and-scopes/).

## Door two: API tokens

`TokenStrategy` extracts a bearer token and hands it to your validator, which returns a principal struct on success or `false` on failure. Any lookup works — database, cache, remote call. Keep it fast; it runs on every authenticated request.

```cfm
if (!auth.hasStrategy("token")) {
    // Hoist the closure into a variable first — an inline function literal as a
    // constructor named argument crashes Adobe ColdFusion's compiler.
    var tokenValidator = function(token) {
        // Dynamic finder binds the token; the extra where= condition is merged in with AND.
        var apiKey = model("ApiKey").findOneByToken(value=arguments.token, where="revokedAt IS NULL");
        if (IsObject(apiKey)) {
            return {id: apiKey.userId, role: apiKey.role, source: "api-key"};
        }
        return false;
    };
    var tokenStrategy = new wheels.auth.TokenStrategy(validator=tokenValidator);
    auth.registerStrategy(name="token", strategy=tokenStrategy);
}
```

**Sharp edge #3, and it's cross-engine:** that hoisted `tokenValidator` variable is not a style preference. Passing an inline function literal as a *constructor named argument* — `new TokenStrategy(validator=function(token){...})` — compiles fine on Lucee and BoxLang and crashes Adobe ColdFusion with an `ArrayStoreException`. Assign the closure to a variable, then pass the variable. If your app only ever runs Lucee you'll never see it; if it ever touches Adobe, you will.

For test fixtures and seeded keys, the strategy also accepts a static map — `new wheels.auth.TokenStrategy(tokens={"dev-key-alice": {id: 1, role: "admin"}})` — which is fine for local development and exactly as dangerous as it sounds anywhere else.

By default the token is read from the `Authorization: Bearer` header only. There's an opt-in `queryParam` constructor argument if you need `?token=` for a legacy client — leave it off unless you do, because query strings end up in access logs.

## Door three: JWTs

Two components split the job: `JwtService` signs and verifies, `JwtStrategy` adapts it to the authenticator interface.

```cfm
// Issue on login (an API sessions controller)
function create() {
    var user = model("User").findOneByEmail(params.email ?: "");
    if (IsObject(user) && user.authenticate(params.password ?: "")) {
        var jwtService = new wheels.auth.JwtService(secretKey=env("JWT_SECRET"));
        var token = jwtService.encode({sub: user.id, email: user.email, role: user.role});
        renderWith({token: token, expiresIn: 3600});
    } else {
        renderWith(data={error: "invalid credentials"}, status=401);
    }
}
```

```cfm
// Verify on every request — register once at init
var jwtService = new wheels.auth.JwtService(secretKey=env("JWT_SECRET"));
auth.registerStrategy(name="jwt", strategy=new wheels.auth.JwtStrategy(jwtService=jwtService));
```

The constructor signatures are worth knowing precisely, because getting them wrong fails at runtime:

- `JwtService(secretKey, defaultExpiry=3600, issuer="", allowedClockSkew=0)` — and **the secret must be at least 32 bytes**. HMAC-SHA256 requires a 256-bit key per RFC 7518, and the constructor enforces it: an empty key throws `Wheels.Auth.JWT.InvalidSecretKey`, a short one throws `Wheels.Auth.JWT.WeakSecretKey` at construction time, not at first verify. That fail-fast is a feature — a brute-forceable signing key means every token you've ever issued is forgeable.
- `JwtStrategy(jwtService, queryParam="")` — it takes the *service object*, not the secret. `new JwtStrategy(secret=...)` is not a constructor that exists.

Set `issuer` if you run multiple token-issuing apps against shared services, and `allowedClockSkew` (seconds) if your servers' clocks drift — both are verified on decode.

## One app, all three doors

Because the authenticator tries strategies in registration order and each strategy's `supports()` checks what's actually on the request, combining them is just registering all three. A request with a session cookie authenticates via session; one with `Authorization: Bearer` hits token or JWT. Your HTML controllers and your `/api/*` controllers call the identical `service("authenticator").authenticate(request)` — the branching you used to write by hand is now the registry's job.

Route-scoped [middleware](https://guides.wheels.dev/v4-0-0/core-concepts/middleware-pipeline/) is the natural place to enforce API auth wholesale — one `ApiAuth` middleware on `.scope(path="/api", ...)` instead of a filter in every API controller.

## The honest part: password hashing

None of the strategies hash passwords — they round-trip principals after *you've* verified credentials. And here Wheels 4 has a real gap you should plan around: **bcrypt is not bundled**. `hash(pw, "BCRYPT")` throws on the stock Lucee runtime. Salted SHA-256 — what the tutorial demonstrates — is educational, not production-grade, because SHA-256 is fast and password hashes should be slow.

For production today: add a Java bcrypt library to your app, or use a CFX tag. The mechanism (salt, hash, compare) is identical; only the function changes. A bundled answer is on the framework's radar — watch the [releases page](https://github.com/wheels-dev/wheels/releases).

## The cheat sheet

1. Register `Authenticator` + strategies as **singletons** in `config/services.cfm`; wire the registry at init with a `hasStrategy()` guard.
2. Filters that gate actions are **`private`**, always.
3. Look up users with **dynamic finders** (`findOneByEmail`), never interpolated `where=` strings.
4. **Hoist closures** before passing them to constructors, or Adobe CF's compiler will make you regret it.
5. JWT secrets: **32 bytes minimum**, from the environment, never from source control.
6. `JwtStrategy` takes a **`jwtService` object**, not a secret.
7. Bearer tokens live in headers; `queryParam` is opt-in for a reason.
8. Bcrypt: **bring your own** until the framework bundles one.

The full walkthrough — including the hand-rolled version that teaches the mental model before the built-ins replace it — is [Tutorial Part 6](https://guides.wheels.dev/v4-0-0/start-here/tutorial/06-authentication/) and the [Authentication Patterns guide](https://guides.wheels.dev/v4-0-0/digging-deeper/authentication-patterns/).

