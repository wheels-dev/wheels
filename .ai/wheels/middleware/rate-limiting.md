# Rate Limiting Middleware — AI Reference

## Constructor API

```cfm
new wheels.middleware.RateLimiter(
    maxRequests = 60,         // numeric — max requests per window
    windowSeconds = 60,       // numeric — window duration in seconds
    strategy = "fixedWindow", // string — fixedWindow | slidingWindow | tokenBucket
    storage = "memory",       // string — memory | database
    keyFunction = "",         // closure(request) => string, or empty for IP-based
    headerPrefix = "X-RateLimit", // string — response header prefix
    trustProxy = true         // boolean — use X-Forwarded-For
)
```

Throws `Wheels.RateLimiter.InvalidStrategy` or `Wheels.RateLimiter.InvalidStorage` on bad input.

## Strategy Algorithms

### Fixed Window
- Discrete time buckets: `windowId = Int(now / windowSeconds)`
- Store key: `clientKey:windowId`
- Counter incremented per request
- Resets when windowId changes

### Sliding Window
- Timestamp log per client key
- Prune entries older than `now - windowSeconds`
- Count remaining entries vs maxRequests
- More memory per client, more accurate

### Token Bucket
- Bucket with `capacity = maxRequests`
- Refill rate: `maxRequests / windowSeconds` tokens/sec
- Each request consumes 1 token
- Allows bursts up to capacity

## Method Inventory

| Method | Visibility | Purpose |
|--------|-----------|---------|
| `init()` | public | Constructor — validates strategy/storage, initializes store |
| `handle()` | public | MiddlewareInterface — check limit, set headers, pass/block |
| `$resolveKey()` | private | Client identification from keyFunction or IP |
| `$getClientIp()` | private | IP from request struct, X-Forwarded-For, or CGI |
| `$checkFixedWindow()` | private | Fixed window algorithm |
| `$checkSlidingWindow()` | private | Sliding window with timestamp log |
| `$checkTokenBucket()` | private | Token bucket algorithm |
| `$maybeCleanup()` | private | Throttled memory cleanup (1x/min) |
| `$dbIncrement()` | private | DB: fixed window counter |
| `$dbSlidingWindow()` | private | DB: sliding window entries |
| `$dbTokenBucket()` | private | DB: token bucket state |
| `$ensureTable()` | private | Auto-create wheels_rate_limits table |

## Storage

### Memory
- `java.util.concurrent.ConcurrentHashMap`
- Per-key `cflock` (name=`wheels-ratelimit-{key}`, timeout=1, exclusive)
- Fail-open on lock timeout
- Cleanup throttled to 1x/min

### Database
- Table: `wheels_rate_limits` (auto-created)
- Columns: `id`, `store_key`, `counter`, `expires_at`
- Parameterized queries via `QueryExecute()`
- Try-insert/catch-update for portability

## Response Headers

Always set:
- `{prefix}-Limit` — maxRequests
- `{prefix}-Remaining` — requests left
- `{prefix}-Reset` — Unix timestamp of window reset

On 429:
- `Retry-After` — seconds until reset
- Status: 429 Too Many Requests
- Body: "Rate limit exceeded. Try again later."

## Usage Patterns

```cfm
// Global — 60 req/min per IP
set(middleware = [new wheels.middleware.RateLimiter()]);

// Route-scoped — strict auth limit
.scope(path="/auth", middleware=[
    new wheels.middleware.RateLimiter(maxRequests=10, windowSeconds=60)
])

// API key-based limiting
new wheels.middleware.RateLimiter(
    keyFunction=function(req) { return req.cgi.http_x_api_key; }
)

// Multi-server with DB storage
new wheels.middleware.RateLimiter(storage="database")
```
