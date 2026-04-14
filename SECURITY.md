# Security Policy

## Reporting Security Issues

**Do not report security vulnerabilities through public GitHub issues.**

Please report security issues via our [Responsible Disclosure Program](mailto:webmaster@wheels.dev?subject=Responsible%20Disclosure%20Program) or through [GitHub Security Advisories](https://github.com/wheels-dev/wheels/security/advisories/new).

Include as much detail as possible: steps to reproduce, affected versions, and potential impact. We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation timeline within 7 days.

## Security Architecture Overview

Wheels includes several built-in security features:

- **Parameterized queries** — The QueryBuilder and ORM automatically parameterize values, preventing SQL injection.
- **XSS protection** — HTML encoding is enabled by default for all output helpers.
- **CSRF protection** — Encrypted, per-session CSRF tokens with configurable cookie encryption.
- **Path traversal prevention** — View rendering validates template paths to prevent directory traversal.
- **CORS validation** — The CORS middleware enforces safe defaults (no wildcard origins with credentials).
- **Rate limiting middleware** — Configurable strategies (fixed window, sliding window, token bucket) with memory or database-backed storage.
- **Security headers middleware** — Sets `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, and optional CSP/HSTS.
- **Console eval endpoint** — Protected by 7 defense layers: localhost-only, development-mode-only, password, rate limiting, content-type validation, POST-only, and `X-Forwarded-For` rejection.

## Security Recommendations for Application Developers

### 1. Use QueryBuilder for User Input

The framework's `where` argument on `findAll()` and `findOne()` uses regex-based parsing to extract and parameterize values from WHERE strings. While this works correctly in practice, the chainable QueryBuilder is the safer choice for complex conditions involving user input:

```cfml
// Prefer this for user-controlled values:
model("User").where("status", params.status).where("role", params.role).get()

// Over this:
model("User").findAll(where="status='#params.status#' AND role='#params.role#'")
```

The QueryBuilder guarantees parameterization regardless of input shape, whereas the regex-based parser depends on the input matching expected patterns.

### 2. Dynamic Finders and Property Names

Dynamic finders like `findOneByEmail()` or `findAllByStatus()` extract property names from the method name. CFML constrains method names to alphanumeric characters and underscores, which limits injection risk. However, property names from dynamic finders are not validated against the model's actual property list before being used in SQL. This is extremely low risk but worth noting -- always prefer explicit `findAll(where=...)` or the QueryBuilder for untrusted input.

### 3. Session Fixation

The framework does not automatically regenerate session IDs after authentication. Application developers should rotate the session after successful login to prevent session fixation attacks:

```cfml
// After successful login in Lucee:
sessionRotate();

// Adobe CF does not have sessionRotate(). Workaround:
// Invalidate the current session and redirect to obtain a new session ID.
structClear(session);
sessionInvalidate();
redirectTo(route="login");
```

### 4. JSON Request Body Size

The framework's Dispatch component deserializes JSON request bodies without depth or size limits. While CFML's `DeserializeJSON()` is safe (no code execution), deeply nested or very large JSON payloads could cause memory pressure. Configure your web server to limit request body size:

```nginx
# nginx
client_max_body_size 1m;
```

```apache
# Apache
LimitRequestBody 1048576
```

### 5. Reload Password

Always set a strong `reloadPassword` in `config/settings.cfm`. If the password is empty, URL-based environment switching and application reload are disabled by default. Never use a weak or guessable password:

```cfml
// config/settings.cfm
set(reloadPassword="a-strong-random-string-here");
```

### 6. CSRF Cookie Encryption Key

Always configure `csrfCookieEncryptionSecretKey` in your `.env` or `config/settings.cfm`. In production, the framework will throw an error if this is not set. Use a strong random key:

```cfml
// config/settings.cfm (via environment variable)
set(csrfCookieEncryptionSecretKey=get("env").csrfSecret);
```

### 7. Security Headers

Enable all security headers in production via the SecurityHeaders middleware. Consider adding HSTS and a Content Security Policy:

```cfml
// config/settings.cfm
set(middleware=[
    new wheels.middleware.SecurityHeaders(
        environment=get("environment"),
        contentSecurityPolicy="default-src 'self'",
        strictTransportSecurity="max-age=31536000; includeSubDomains"
    )
]);
```

## Known Limitations

- **GROUP BY and SELECT clauses** — While the framework validates ORDER BY strictly, developers should avoid passing user input directly to `group` or `select` arguments on finder methods.
- **Plugin and package loading** — All CFCs in `plugins/` and `vendor/` directories are trusted and loaded automatically. Restrict filesystem write access to these directories in production.
- **`allowEnvironmentSwitchViaUrl`** — This setting defaults to `false` in production but is `true` in development. Never enable it in production.
