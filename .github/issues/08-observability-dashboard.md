# [Feature] Built-in Observability Dashboard

**Priority:** #8 — Valuable for debugging and production monitoring
**Labels:** `enhancement`, `feature-request`, `devops`, `monitoring`

## Summary

Add a built-in observability dashboard that displays recent requests, slow queries, background job status, cache hit rates, error logs, and application metrics — accessible via a web UI at `/wheels/dashboard` (development) with optional production access behind authentication.

## Justification

### "What is my application doing?" — the unanswered question

When a Wheels application misbehaves — slow page loads, mysterious errors, job queue backing up — developers have no built-in way to see what's happening. They must:

1. Tail log files manually
2. Run raw SQL to inspect job queues
3. Add temporary debug output to controllers
4. Set up external monitoring tools (APM)
5. Guess and check

### Competitors show what's possible

| Framework | Observability Tool | Key Features |
|-----------|-------------------|--------------|
| **Phoenix** | LiveDashboard | Real-time metrics, process list, ETS tables, request logging — built-in |
| **Laravel** | Telescope / Pulse | Request inspector, query log, job monitor, exception viewer, mail log |
| **Rails** | Web Console + mission_control-jobs | In-browser console, Solid Queue dashboard |
| **Django** | Django Debug Toolbar | SQL queries, template rendering, cache, signals — per-request |
| **Wheels** | **Nothing** | Debug information toggle only (basic request details) |

Phoenix LiveDashboard is particularly noteworthy — it ships with the framework and is immediately useful. Laravel Telescope has become essential for Laravel debugging workflows. Both prove that first-party observability tools dramatically improve developer experience.

### Wheels already collects some of this data

- Request/response information (when debug mode is on)
- Database queries (query logging)
- Background jobs (in the jobs table)
- Cache operations (framework-level caching)
- Error information (cfcatch/error handlers)

The data exists — it just needs a UI to surface it.

## Specification

### Dashboard Sections

#### 1. Request Monitor
```
Recent Requests                                        [Auto-refresh: 5s]
╔══════════╦════════╦════════════════════╦══════╦══════════╦════════╗
║ Time     ║ Method ║ Path               ║ Code ║ Duration ║ Queries║
╠══════════╬════════╬════════════════════╬══════╬══════════╬════════╣
║ 14:30:02 ║ GET    ║ /users             ║ 200  ║ 45ms     ║ 3     ║
║ 14:30:01 ║ POST   ║ /users             ║ 302  ║ 120ms    ║ 5     ║
║ 14:29:58 ║ GET    ║ /products?page=2   ║ 200  ║ 230ms    ║ 12    ║
║ 14:29:55 ║ GET    ║ /api/orders/42     ║ 404  ║ 8ms      ║ 1     ║
╚══════════╩════════╩════════════════════╩══════╩══════════╩════════╝

Click any request for details: headers, params, session, queries, response
```

#### 2. Slow Query Log
```
Slow Queries (> 100ms)                                [Last 24 hours]
╔══════════╦════════╦══════════════════════════════════════════╦═══════╗
║ Time     ║ Duration║ Query                                   ║ Source║
╠══════════╬════════╬══════════════════════════════════════════╬═══════╣
║ 14:22:10 ║ 1,240ms║ SELECT * FROM orders WHERE status...    ║ N+1   ║
║ 14:15:33 ║ 890ms  ║ SELECT u.*, COUNT(o.id) FROM users...   ║ Report║
║ 13:58:01 ║ 350ms  ║ UPDATE products SET viewCount = ...     ║ Show  ║
╚══════════╩════════╩══════════════════════════════════════════╩═══════╝

Missing indexes detected: orders.status, products.categoryId
```

#### 3. Background Jobs Dashboard
```
Job Queue Status                                      [Live]
╔═════════════╦═════════╦════════════╦════════╦════════╦═══════╗
║ Queue       ║ Pending ║ Processing ║ Failed ║ Rate   ║ Avg   ║
╠═════════════╬═════════╬════════════╬════════╬════════╬═══════╣
║ default     ║ 12      ║ 2          ║ 0      ║ 45/hr  ║ 1.2s  ║
║ mailers     ║ 3       ║ 1          ║ 1      ║ 120/hr ║ 3.5s  ║
║ reports     ║ 0       ║ 0          ║ 0      ║ 5/hr   ║ 45s   ║
╚═════════════╩═════════╩════════════╩════════╩════════╩═══════╝

Failed Jobs:
- SendWelcomeEmail #4521 — "SMTP connection timeout" — [Retry] [Delete]
```

#### 4. Cache Performance
```
Cache Statistics                                      [Last hour]
╔══════════════╦══════╦════════╦══════════╦═══════════╗
║ Type         ║ Hits ║ Misses ║ Hit Rate ║ Size      ║
╠══════════════╬══════╬════════╬══════════╬═══════════╣
║ Page Cache   ║ 1,240║ 180    ║ 87.3%    ║ 45 items  ║
║ Action Cache ║ 890  ║ 67     ║ 93.0%    ║ 23 items  ║
║ Query Cache  ║ 3,400║ 450    ║ 88.3%    ║ 156 items ║
║ Partial Cache║ 2,100║ 120    ║ 94.6%    ║ 78 items  ║
╚══════════════╩══════╩════════╩══════════╩═══════════╝
```

#### 5. Error Tracker
```
Recent Errors                                         [Last 24 hours]
╔══════════╦═══════════════════════════════════╦═══════╦═══════════╗
║ Time     ║ Error                             ║ Count ║ Last Seen ║
╠══════════╬═══════════════════════════════════╬═══════╬═══════════╣
║ 14:22:10 ║ Expression: Variable X undefined  ║ 3     ║ 14:30:00  ║
║ 13:15:33 ║ Database: Deadlock detected        ║ 1     ║ 13:15:33  ║
╚══════════╩═══════════════════════════════════╩═══════╩═══════════╝

Click for full stack trace, request context, and local variables
```

#### 6. Application Info
```
Application Overview
├── Environment: development
├── Wheels Version: 3.2.0
├── CFML Engine: Lucee 6.1.0.123
├── Java: OpenJDK 21.0.2
├── Database: MySQL 8.0.35 (myapp_dev)
├── Uptime: 3d 14h 22m
├── Routes: 47 defined
├── Models: 12 loaded
└── Plugins: 3 active (authenticateThis, flashMessages, dbMigrate)
```

### Configuration

```cfm
// config/settings.cfm
set(observabilityEnabled=true);
set(observabilityPath="/wheels/dashboard");

// What to collect
set(observabilityCollect={
    requests: true,         // Log all requests
    queries: true,          // Log all SQL queries
    slowQueryThreshold: 100,// Flag queries slower than 100ms
    jobs: true,             // Monitor background jobs
    cache: true,            // Track cache hit/miss
    errors: true,           // Capture errors with context
    memory: true            // Track memory usage
});

// Data retention
set(observabilityRetention={
    requests: 24,   // hours
    queries: 24,
    errors: 168     // 7 days
});

// Access control
set(observabilityAccess="development");  // "development", "authenticated", "always"
set(observabilityPassword=GetEnvironmentValue("DASHBOARD_PASSWORD", ""));
```

### Storage Backend

```cfm
// Dashboard data stored in-memory by default (fast, ephemeral)
set(observabilityStorage="memory");

// Optional: persist to database for production use
set(observabilityStorage="database");
// Requires migration: wheels generate migration CreateObservabilityTables
```

### Real-Time Updates

```cfm
// Dashboard uses SSE (Server-Sent Events) for live updates
// Leverages existing Wheels SSE infrastructure
// Auto-refresh intervals configurable per section
```

### API Endpoints (for external monitoring)

```
GET /wheels/dashboard/api/requests     → JSON request log
GET /wheels/dashboard/api/queries      → JSON slow query log
GET /wheels/dashboard/api/jobs         → JSON job queue status
GET /wheels/dashboard/api/cache        → JSON cache statistics
GET /wheels/dashboard/api/errors       → JSON error log
GET /wheels/dashboard/api/metrics      → JSON application metrics
```

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **Controller** | `wheels/dashboard/DashboardController.cfc` | Dashboard routes and data |
| **Collector** | `wheels/observability/RequestCollector.cfc` | Request/response logging |
| **Collector** | `wheels/observability/QueryCollector.cfc` | SQL query logging |
| **Collector** | `wheels/observability/ErrorCollector.cfc` | Error capture |
| **Storage** | `wheels/observability/MemoryStore.cfc` | In-memory ring buffer |
| **Storage** | `wheels/observability/DatabaseStore.cfc` | Persistent storage |
| **Views** | `wheels/dashboard/views/` | Dashboard HTML/CSS/JS |
| **Config** | `config/observability.cfm` | Dashboard configuration |
| **Routes** | Auto-registered `/wheels/dashboard/*` | Dashboard endpoints |

### Implementation Phases

**Phase 1 (MVP):**
- Request monitor with query count and duration
- Slow query log
- Error tracker
- Application info panel
- In-memory storage only

**Phase 2:**
- Background job dashboard
- Cache statistics
- Real-time SSE updates
- Database storage backend

**Phase 3:**
- N+1 query detection
- Missing index suggestions
- Performance trend graphs
- Custom metric registration
- OpenTelemetry export

## Impact Assessment

- **Debugging speed:** Instantly see what's happening without log tailing or SQL queries
- **Performance optimization:** Slow query log and cache stats surface bottlenecks automatically
- **Developer experience:** Phoenix LiveDashboard and Laravel Telescope are beloved features — this would be a major DX win
- **Production confidence:** Real-time visibility into application health and behavior
- **Uniqueness in CFML:** No CFML framework has anything like this built-in

## References

- Phoenix LiveDashboard: https://github.com/phoenixframework/phoenix_live_dashboard
- Laravel Telescope: https://laravel.com/docs/telescope
- Laravel Pulse: https://laravel.com/docs/pulse
- Django Debug Toolbar: https://django-debug-toolbar.readthedocs.io/
- Spring Boot Actuator: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html
