#!/usr/bin/env bash
#
# Creates all 8 framework competitive gap issues on GitHub.
# Prerequisites: gh CLI authenticated (`gh auth login`)
# Usage: bash .github/issues/create-all-issues.sh
#
set -euo pipefail

REPO="wheels-dev/wheels"

echo "Creating 8 framework competitive gap issues on $REPO..."
echo ""

# ─────────────────────────────────────────────────────────────
# Issue 1: Authentication & Authorization Generator
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 1/8: Authentication & Authorization Generator..."
gh issue create --repo "$REPO" \
  --title "[Feature] Authentication & Authorization Scaffolding Generator (\`wheels generate auth\`)" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a `wheels generate auth` CLI command that produces a complete, working authentication system out of the box — covering user registration, login/logout, password reset, email verification, and session management.

## Priority: #1 — Highest priority competitive gap

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

Nearly every web app requires authentication. Having to manually wire it up (or use a Wheels 2.0-era plugin) creates immediate friction for new adopters. When a developer runs `wheels new myapp`, the next question is almost always "how do I add login?" — and right now, the answer is "figure it out yourself."

### Foundation for other features

Authorization policies, API tokens, multi-channel notifications, and role-based access control all depend on having a solid, standardized auth layer. Building auth first unblocks multiple downstream features.

### Existing building blocks are already in place

Wheels already has all the pieces — they just need to be wired into a single generator:

- **`authenticateThis` plugin** — BCrypt hashing, password validation
- **Documentation patterns** — `.ai/wheels/patterns/authentication.md`
- **Controller filter system** — `filters(through="requireLogin")`
- **Session management** — `session.userId`, flash messages
- **Mailer system** — `app/mailers/` for password reset and verification emails
- **CSRF protection** — Built-in token verification
- **Background jobs** — `app/jobs/` for async email delivery

## What `wheels generate auth` should produce

| Component | Files Generated |
|-----------|----------------|
| **Migration** | `[timestamp]_create_users_table.cfc` — users table with email, passwordHash, salt, rememberToken, emailVerifiedAt, timestamps |
| **Model** | `app/models/User.cfc` — validations, BCrypt hashing, `authenticate()`, role association |
| **Controller** | `app/controllers/Sessions.cfc` — login/logout actions with before filters |
| **Controller** | `app/controllers/Registrations.cfc` — registration/signup flow |
| **Controller** | `app/controllers/Passwords.cfc` — forgot/reset password flow |
| **Views** | Login, registration, forgot/reset password forms |
| **Routes** | Auth routes injected into `config/routes.cfm` |
| **Mailer** | `app/mailers/AuthMailer.cfc` — verification + password reset emails |
| **Tests** | Model and controller tests |
| **Global helper** | `app/global/auth.cfm` — `currentUser()`, `isLoggedIn()`, `requireAuth()` |

## Stretch Goals

- `--api` flag for token-based API authentication (like Laravel Sanctum)
- `--2fa` flag for TOTP two-factor authentication
- Remember me / persistent sessions
- Account lockout after N failed attempts
- Email verification flow

## Impact

Closing this gap alone would move Wheels from ~55% to ~65% feature parity with competitors and remove the #1 friction point for new adoption.

See full specification: `.github/issues/01-auth-generator.md`
EOF
)"
echo "  ✓ Issue 1 created"

# ─────────────────────────────────────────────────────────────
# Issue 2: File Storage Abstraction
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 2/8: File Storage Abstraction..."
gh issue create --repo "$REPO" \
  --title "[Feature] File Storage Abstraction Layer" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a unified file storage abstraction providing a consistent API for local filesystem, Amazon S3, Google Cloud Storage, and Azure Blob Storage — allowing developers to swap storage backends without changing application code.

## Priority: #2 — Table-stakes gap

## Justification

### Table-stakes feature that every modern framework provides

| Framework | Storage Solution | Details |
|-----------|-----------------|---------|
| **Laravel** | Flysystem integration | Local, S3, GCS, Azure, FTP — unified `Storage` facade |
| **Rails** | Active Storage | Direct uploads, variants, mirrors, S3/GCS/Azure |
| **Django** | `django.core.files.storage` | Pluggable backends, `FileField`/`ImageField` model integration |
| **AdonisJS 6** | Drive | Local, S3, GCS — fluent API with streaming support |
| **Wheels** | **Nothing** | Raw `<cffile>` calls with no abstraction |

### Every modern web app handles file uploads

User avatars, document attachments, product images, CSV imports — file storage is universal. Without a framework-level abstraction, developers must build their own S3 integration from scratch and rewrite everything when changing storage backends.

### Cloud storage is the default in 2025

Modern deployments (Docker, Kubernetes, serverless) have ephemeral filesystems. Files stored locally are lost on redeployment. A storage abstraction with cloud backends is required for modern deployment.

## Specification

### Core API

```cfm
storage().put(path="avatars/user-123.jpg", contents=fileContent);
storage().putFile(path="documents/", file=params.file);
contents = storage().get(path="avatars/user-123.jpg");
url = storage().url(path="avatars/user-123.jpg");
exists = storage().exists(path="avatars/user-123.jpg");
storage().delete(path="avatars/user-123.jpg");
storage(disk="s3").put(path="backups/db.sql", contents=sqlDump);
```

### Model Integration

```cfm
component extends="Model" {
    function config() {
        hasAttachment(name="avatar", disk="s3", directory="avatars/");
    }
}
user.attachAvatar(params.avatar);
avatarUrl = user.avatarUrl();
```

### Drivers

| Driver | Priority | Backend |
|--------|----------|---------|
| **Local** | P0 | Local filesystem with public/private visibility |
| **S3** | P0 | Amazon S3 (also MinIO, DigitalOcean Spaces, Backblaze B2) |
| **GCS** | P1 | Google Cloud Storage |
| **Azure** | P1 | Azure Blob Storage |

See full specification: `.github/issues/02-file-storage-abstraction.md`
EOF
)"
echo "  ✓ Issue 2 created"

# ─────────────────────────────────────────────────────────────
# Issue 3: Multi-Channel Notification System
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 3/8: Multi-Channel Notification System..."
gh issue create --repo "$REPO" \
  --title "[Feature] Multi-Channel Notification System" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a multi-channel notification system allowing notifications through multiple channels (email, database, SMS, Slack, webhooks) from a single notification class — inspired by Laravel's notification system.

## Priority: #3 — Highly desirable competitive differentiator

## Justification

### Laravel's notification system is a massive DX win

A single `Notification` class simultaneously sends email, stores a database record (in-app notification), fires a Slack message, sends SMS, and triggers webhooks. No CFML framework offers anything comparable.

### Current state

Wheels has `app/mailers/` for email, but no unified notification concept. Developers who need database notifications, Slack alerts, or SMS must build each channel from scratch with no shared infrastructure for routing, queueing, or formatting.

### Natural evolution of existing infrastructure

Wheels already has mailers (`app/mailers/`), background jobs (`app/jobs/`), database migrations, and model callbacks — all of which become channels/infrastructure for the notification system.

## Specification

### Notification Class

```cfm
// app/notifications/OrderShippedNotification.cfc
component extends="wheels.Notification" {
    function config() { via(["mail", "database", "slack"]); }

    struct function toMail(required any notifiable) {
        return { subject: "Your order shipped!", template: "emails/order-shipped",
                 data: { orderId: this.data.orderId } };
    }

    struct function toDatabase(required any notifiable) {
        return { title: "Order Shipped", body: "Order shipped...", icon: "truck" };
    }
}
```

### Usage

```cfm
notify(notifiable=user, notification="OrderShipped", data={orderId: order.id});
notifyLater(notifiable=user, notification="OrderShipped", data={orderId: order.id});  // queued
```

### Model Integration

```cfm
hasNotifications();  // Adds notifications relationship + helpers
user.notifications(page=1, perPage=20);
user.unreadNotificationCount();
user.markAllNotificationsAsRead();
```

### Channels (Implementation Priority)

| Channel | Priority | Description |
|---------|----------|-------------|
| **Database** | P0 | In-app notifications with read/unread |
| **Mail** | P0 | Integration with existing mailer system |
| **Slack** | P1 | Webhook-based Slack messages |
| **SMS** | P1 | Twilio/Vonage integration |
| **Webhook** | P1 | Generic HTTP POST to any URL |

See full specification: `.github/issues/03-notification-system.md`
EOF
)"
echo "  ✓ Issue 3 created"

# ─────────────────────────────────────────────────────────────
# Issue 4: Model Factories for Testing
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 4/8: Model Factories for Testing..."
gh issue create --repo "$REPO" \
  --title "[Feature] Model Factories for Testing" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a model factory system providing a fluent API for generating test data — eliminating boilerplate in test setup and making tests more readable and maintainable.

## Priority: #4 — Testing productivity multiplier

## Justification

### Testing without factories is painful

Every Wheels test that needs model instances must manually construct them with all required fields. This is verbose (10+ lines per setup), brittle (adding a required column breaks every test), duplicated (same setup across dozens of files), and obscures the intent of what's being tested.

### Every major framework has solved this

| Framework | Solution | Key Feature |
|-----------|----------|-------------|
| **Laravel** | Eloquent Factories | `User::factory()->count(3)->create()` |
| **Rails** | FactoryBot | `create(:user, :admin)` |
| **Django** | Factory Boy / Model Bakery | `baker.make(User)` |
| **AdonisJS 6** | Lucid Factories | `UserFactory.merge({role: 'admin'}).create()` |
| **Wheels** | **Nothing** | Manual `model("X").create()` with all fields |

## Specification

### Factory Definition

```cfm
// tests/factories/UserFactory.cfc
component extends="wheels.Factory" {
    function definition() {
        return { email: fake("email"), firstName: fake("firstName"),
                 lastName: fake("lastName"), password: "password123",
                 role: "member", status: "active" };
    }
    function admin() { return { role: "admin" }; }
    function unverified() { return { emailVerifiedAt: "" }; }
}
```

### Usage in Tests

```cfm
var user = factory("User").create();                    // defaults
var admin = factory("User").admin().create();            // with state
var users = factory("User").count(5).create();           // multiple
var unsaved = factory("User").make();                    // without persisting
var custom = factory("User").create(email="vip@ex.com"); // override
```

### Features

- **States** — Named attribute overrides (`.admin()`, `.suspended()`)
- **Sequences** — Auto-incrementing unique values (`user_1@example.com`)
- **Fake data** — Built-in generators for email, name, phone, address, etc.
- **Relationships** — `.withOrders(3).create()` creates related records
- **Transaction cleanup** — Factory data auto-rolled back after each test
- **Generator** — `wheels generate factory User` scaffolds from model schema

See full specification: `.github/issues/04-model-factories.md`
EOF
)"
echo "  ✓ Issue 4 created"

# ─────────────────────────────────────────────────────────────
# Issue 5: Interactive Console (REPL)
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 5/8: Interactive Console (REPL)..."
gh issue create --repo "$REPO" \
  --title "[Feature] Interactive Console / REPL (\`wheels console\`)" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a `wheels console` command that boots the Wheels application and provides an interactive REPL where developers can run model queries, test code snippets, inspect data, and debug issues — without writing a controller action or refreshing a browser.

## Priority: #5 — Essential developer tool

## Justification

### Every major framework has an interactive console

| Framework | Console | Details |
|-----------|---------|---------|
| **Laravel** | `php artisan tinker` | PsySH-based, auto-imports models |
| **Rails** | `rails console` | IRB/Pry, full app context, sandbox mode |
| **Django** | `python manage.py shell` | IPython support, `shell_plus` |
| **Phoenix** | `iex -S mix` | Elixir REPL with full app context |
| **Wheels** | **Nothing** | Must create throw-away controller actions |

### The development workflow gap

Without a console, testing a model query requires creating a controller action, reloading the app, hitting the URL, reading output, and deleting the controller. A REPL provides **instant feedback** — type a query, see results immediately.

## Specification

### Usage

```bash
$ wheels console

wheels> model("User").findAll(maxRows=3)
╔════╦═══════════════════╦═══════════╦════════╗
║ id ║ email             ║ firstName ║ role   ║
║  1 ║ admin@example.com ║ Admin     ║ admin  ║
║  2 ║ jane@example.com  ║ Jane      ║ member ║
╚════╩═══════════════════╩═══════════╩════════╝

wheels> user = model("User").findByKey(1)
=> User#1 (admin@example.com)

wheels> user.valid()
=> true
```

### Modes

- **Standard** — Read/write access to database
- **Sandbox** (`--sandbox`) — All changes rolled back on exit
- **Production** (`--environment=production`) — Requires explicit confirmation

### Built-in Commands

- `model("Name")` — Access any model
- `reload` — Reload the application
- `routes` — Display all routes
- `schema("table")` — Show table schema
- `sql("SELECT ...")` — Run raw SQL
- `benchmark { code }` — Time execution

### Implementation Approach (Recommended)

Extend the existing Wheels CLI (CommandBox-based) to boot the app and evaluate CFML expressions with full application context. Leverage existing Lucee/BoxLang runtime evaluation capabilities.

See full specification: `.github/issues/05-interactive-console.md`
EOF
)"
echo "  ✓ Issue 5 created"

# ─────────────────────────────────────────────────────────────
# Issue 6: Authorization System (Policies)
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 6/8: Authorization System (Policies)..."
gh issue create --repo "$REPO" \
  --title "[Feature] Authorization System with Policies" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a policy-based authorization system providing structured, testable, reusable authorization logic — replacing ad-hoc controller filter checks with declarative policy classes that answer "can this user perform this action on this resource?"

## Priority: #6 — Structured authorization beyond ad-hoc filters

## Justification

### Ad-hoc authorization doesn't scale

Current Wheels authorization is scattered `if` statements in controller filters — duplicated across controllers, untestable without HTTP, inconsistent between developers, and with no central audit point.

### Competitors have structured solutions

| Framework | Authorization System | Key Feature |
|-----------|---------------------|-------------|
| **Laravel** | Gates + Policies | `$this->authorize('update', $post)` |
| **Rails** | Pundit | `authorize @post, :update?` |
| **AdonisJS 6** | Bouncer | `bouncer.authorize('editPost', post)` |
| **Django** | Permissions + django-rules | `has_perm('blog.change_post')` |
| **Wheels** | **Nothing** | Ad-hoc `if` statements in controller filters |

### Auth without authorization is incomplete

The Authentication Generator (Issue #1) establishes "who is this user?" — but authorization answers "what can this user do?" Without structured authorization, auth only solves half the problem.

## Specification

### Policy Definition

```cfm
// app/policies/PostPolicy.cfc
component extends="wheels.Policy" {
    boolean function view(required any user, required any post) {
        if (post.isPublished()) return true;
        return post.userId == user.id;
    }
    boolean function update(required any user, required any post) {
        return post.userId == user.id || user.isAdmin();
    }
    boolean function delete(required any user, required any post) {
        return user.isAdmin() || (post.userId == user.id && post.isDraft());
    }
}
```

### Controller Integration

```cfm
function edit() {
    authorize("update", post);  // Checks PostPolicy.update() — throws if denied
    renderView();
}
```

### View Integration

```cfm
<cfif can("update", post)>
    #linkTo(text="Edit", route="editPost", key=post.id)#
</cfif>
```

### Gates (Simple Rules)

```cfm
// config/authorization.cfm
gate(name="accessDashboard", callback=function(user) {
    return ArrayFindNoCase(["admin", "editor"], user.role);
});
```

### Features

- **Policy auto-resolution** — `model("Post")` → `app/policies/PostPolicy.cfc`
- **Before filter** — Super-admin bypass via `before()` method
- **Denial messages** — `deny("You can only delete your own posts.")`
- **Testable** — Policies are plain CFCs, easily unit tested
- **Generator** — `wheels generate policy Post`

See full specification: `.github/issues/06-authorization-policies.md`
EOF
)"
echo "  ✓ Issue 6 created"

# ─────────────────────────────────────────────────────────────
# Issue 7: Health Check Endpoints
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 7/8: Health Check Endpoints..."
gh issue create --repo "$REPO" \
  --title "[Feature] Health Check Endpoints" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add built-in health check endpoints (`/health`, `/health/ready`, `/health/live`) reporting application health — including database connectivity, disk space, memory usage, and custom checks. Essential for Docker, Kubernetes, load balancers, and monitoring systems.

## Priority: #7 — Essential for production and container orchestration

## Justification

### Required for modern deployment

- **Kubernetes** — `livenessProbe` and `readinessProbe` determine pod lifecycle
- **Docker** — `HEALTHCHECK` instruction determines container health
- **AWS ELB/ALB** — Health checks determine instance routing
- **Cloud Run / ECS** — Container health monitoring
- **Uptime monitors** — Pingdom, UptimeRobot, DataDog

Without health checks, orchestrators can't distinguish a crashed app from a healthy one.

### Competitors provide this

| Framework | Health Checks | Details |
|-----------|--------------|---------|
| **NestJS** | `@nestjs/terminus` | Configurable health indicators |
| **Rails** | Built-in since 7.1 | `get "up"` route |
| **Django** | `django-health-check` | Pluggable backends |
| **Spring Boot** | Actuator `/health` | Industry standard |
| **Wheels** | **Nothing** | Must build from scratch |

## Specification

### Endpoints

```
GET /health          → Full health check (all checks, 200/503)
GET /health/live     → Liveness probe (is the app running?)
GET /health/ready    → Readiness probe (can the app serve traffic?)
```

### Response Format

```json
{
    "status": "healthy",
    "checks": {
        "database": { "status": "healthy", "responseTime": "3ms" },
        "diskSpace": { "status": "healthy", "free": "32GB" },
        "memory": { "status": "healthy", "usagePercent": "25%" },
        "migrations": { "status": "healthy", "pending": 0 }
    }
}
```

### Custom Health Checks

```cfm
// app/health/RedisCheck.cfc
component extends="wheels.HealthCheck" {
    struct function check() {
        var redis = getRedisConnection();
        redis.ping();
        return healthy(details={ responseTime: "3ms" });
    }
}
```

### Built-in Checks

| Check | What It Monitors | Healthy Criteria |
|-------|-----------------|------------------|
| **Database** | Connection pool | Can execute `SELECT 1` |
| **Disk Space** | Available storage | Free space above threshold |
| **Memory** | JVM heap usage | Below configured threshold |
| **Migrations** | Pending migrations | No pending migrations |

### Status Levels: `healthy` (200), `degraded` (200), `unhealthy` (503)

See full specification: `.github/issues/07-health-check-endpoints.md`
EOF
)"
echo "  ✓ Issue 7 created"

# ─────────────────────────────────────────────────────────────
# Issue 8: Observability Dashboard
# ─────────────────────────────────────────────────────────────
echo "Creating Issue 8/8: Observability Dashboard..."
gh issue create --repo "$REPO" \
  --title "[Feature] Built-in Observability Dashboard" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

Add a built-in observability dashboard displaying recent requests, slow queries, background job status, cache hit rates, and error logs — accessible via a web UI at `/wheels/dashboard`.

## Priority: #8 — Valuable for debugging and production monitoring

## Justification

### "What is my application doing?" — the unanswered question

When a Wheels application misbehaves, developers have no built-in way to see what's happening. They must tail logs, run raw SQL, or add temporary debug output — all time-consuming and error-prone.

### Competitors show what's possible

| Framework | Observability Tool | Key Features |
|-----------|-------------------|--------------|
| **Phoenix** | LiveDashboard | Real-time metrics, process list, request logging — built-in |
| **Laravel** | Telescope / Pulse | Request inspector, query log, job monitor, exception viewer |
| **Django** | Debug Toolbar | SQL queries, template rendering, cache — per-request |
| **Wheels** | **Nothing** | Debug information toggle only |

### Wheels already collects the data — it just needs a UI

Request/response info, database queries, background jobs, cache operations, and errors are all tracked by the framework. The data exists — it just needs a dashboard.

## Specification

### Dashboard Sections

1. **Request Monitor** — Recent requests with method, path, status code, duration, query count
2. **Slow Query Log** — Queries exceeding threshold with source and missing index detection
3. **Background Jobs** — Queue status, pending/processing/failed counts, retry controls
4. **Cache Performance** — Hit/miss rates for page, action, query, and partial caches
5. **Error Tracker** — Recent errors with stack traces, grouped by type
6. **Application Info** — Environment, versions, uptime, routes, models, plugins

### Configuration

```cfm
set(observabilityEnabled=true);
set(observabilityPath="/wheels/dashboard");
set(observabilityAccess="development");  // "development", "authenticated", "always"
set(observabilityCollect={ requests: true, queries: true, slowQueryThreshold: 100,
                           jobs: true, cache: true, errors: true });
```

### Real-Time Updates

Dashboard uses SSE (Server-Sent Events) for live updates, leveraging existing Wheels SSE infrastructure.

### Implementation Phases

- **Phase 1 (MVP):** Request monitor, slow queries, errors, app info
- **Phase 2:** Job dashboard, cache stats, SSE live updates
- **Phase 3:** N+1 detection, missing index suggestions, trend graphs, OpenTelemetry export

See full specification: `.github/issues/08-observability-dashboard.md`
EOF
)"
echo "  ✓ Issue 8 created"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  All 8 issues created successfully!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Issues created:"
echo "  1. Authentication & Authorization Generator (Priority #1)"
echo "  2. File Storage Abstraction (Priority #2)"
echo "  3. Multi-Channel Notification System (Priority #3)"
echo "  4. Model Factories for Testing (Priority #4)"
echo "  5. Interactive Console / REPL (Priority #5)"
echo "  6. Authorization System with Policies (Priority #6)"
echo "  7. Health Check Endpoints (Priority #7)"
echo "  8. Observability Dashboard (Priority #8)"
