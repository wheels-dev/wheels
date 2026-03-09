# Rate Limiting

Rate limiting protects your application from abuse by restricting how many requests a client can make within a time window. Wheels provides a built-in `RateLimiter` middleware with multiple strategies and storage backends.

## Quick Start

Add the rate limiter to your global middleware stack in `config/settings.cfm`:

```cfm
set(middleware = [
    new wheels.middleware.RateLimiter(maxRequests=60, windowSeconds=60)
]);
```

This allows 60 requests per minute per client IP, using the fixed window strategy with in-memory storage.

## Configuration Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxRequests` | `60` | Maximum requests allowed per window |
| `windowSeconds` | `60` | Duration of the rate limit window in seconds |
| `strategy` | `"fixedWindow"` | Algorithm: `"fixedWindow"`, `"slidingWindow"`, or `"tokenBucket"` |
| `storage` | `"memory"` | Backend: `"memory"` or `"database"` |
| `keyFunction` | `""` | Closure `function(request)` returning a string key. Defaults to client IP |
| `headerPrefix` | `"X-RateLimit"` | Prefix for rate limit response headers |
| `trustProxy` | `true` | Use `X-Forwarded-For` for client IP resolution |

## Strategies

### Fixed Window

Divides time into discrete buckets (e.g., 0:00–0:59, 1:00–1:59). Simple and memory-efficient.

```cfm
new wheels.middleware.RateLimiter(strategy="fixedWindow")
```

**Best for**: Most applications. Simple to understand and debug.

**Trade-off**: A client could send `maxRequests` at the end of one window and `maxRequests` at the start of the next, effectively doubling throughput at the boundary.

### Sliding Window

Maintains a log of request timestamps per client. More accurate than fixed window — the window slides with each request.

```cfm
new wheels.middleware.RateLimiter(strategy="slidingWindow")
```

**Best for**: Applications requiring precise rate enforcement without boundary spikes.

**Trade-off**: Uses more memory per client (stores individual timestamps).

### Token Bucket

Each client has a bucket that fills with tokens at a steady rate. Each request consumes one token. Allows controlled bursts up to `maxRequests`.

```cfm
new wheels.middleware.RateLimiter(strategy="tokenBucket")
```

**Best for**: APIs where you want to allow occasional bursts while maintaining a long-term average rate.

**Trade-off**: Slightly more complex state per client (token count + last refill time).

## Storage Backends

### In-Memory (Default)

Uses a `ConcurrentHashMap` for thread-safe storage. Stale entries are automatically cleaned up once per minute.

```cfm
new wheels.middleware.RateLimiter(storage="memory")
```

**Note**: Counters are lost on server restart and are not shared across multiple application servers. Suitable for single-server deployments or when approximate limiting is acceptable.

### Database

Stores rate limit data in a `wheels_rate_limits` table that is auto-created on first use.

```cfm
new wheels.middleware.RateLimiter(storage="database")
```

**Note**: Shared across all servers in a cluster. Adds a database query per request. Suitable for multi-server deployments where consistent limiting is required.

## Route-Scoped Rate Limiting

Apply different limits to different parts of your application using route middleware:

```cfm
// config/routes.cfm
mapper()
    // Strict limit on authentication endpoints.
    .scope(path="/auth", middleware=[
        new wheels.middleware.RateLimiter(maxRequests=10, windowSeconds=60)
    ])
        .post(name="login", to="sessions##create")
        .post(name="register", to="users##create")
    .end()

    // More generous limit on API endpoints.
    .scope(path="/api", middleware=[
        new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=60)
    ])
        .resources("users")
        .resources("products")
    .end()
.end();
```

## Custom Key Functions

By default, the rate limiter identifies clients by IP address. You can customize this with a `keyFunction`:

```cfm
// Rate limit by API key from request header.
new wheels.middleware.RateLimiter(
    keyFunction=function(request) {
        if (StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "http_x_api_key")) {
            return "api:" & request.cgi.http_x_api_key;
        }
        return "anon:" & cgi.remote_addr;
    }
)

// Rate limit by authenticated user ID.
new wheels.middleware.RateLimiter(
    keyFunction=function(request) {
        if (StructKeyExists(session, "userId")) {
            return "user:" & session.userId;
        }
        return "anon:" & cgi.remote_addr;
    }
)
```

## Response Headers

Every response includes rate limit headers:

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Maximum requests allowed per window |
| `X-RateLimit-Remaining` | Requests remaining in the current window |
| `X-RateLimit-Reset` | Unix timestamp when the window resets |

When a request is rate limited, the response includes:

| Header | Description |
|--------|-------------|
| `Retry-After` | Seconds until the client can retry |

The status code is `429 Too Many Requests` with a plain text body.

The header prefix can be customized:

```cfm
new wheels.middleware.RateLimiter(headerPrefix="X-MyApp-RateLimit")
// Produces: X-MyApp-RateLimit-Limit, X-MyApp-RateLimit-Remaining, etc.
```

## Multi-Server Deployments

With in-memory storage, each server maintains its own counters. If you have 3 servers behind a load balancer, a client could theoretically make `maxRequests × 3` total requests.

For consistent rate limiting across servers, use database storage:

```cfm
new wheels.middleware.RateLimiter(
    storage="database",
    maxRequests=60,
    windowSeconds=60
)
```

The `wheels_rate_limits` table is auto-created on first use. No migration needed.

## Thread Safety

The in-memory implementation uses per-client locking (`cflock`) to ensure accurate counting under concurrent requests. If a lock cannot be acquired within 1 second (indicating extreme contention), the request is allowed through (fail-open). This prevents the rate limiter itself from becoming a bottleneck.
