# Wheels Framework: Competitive Gap Analysis & Priority Recommendations

## Executive Summary

After comparing Wheels against six leading modern frameworks (Laravel, Rails 8, Django 6, NestJS, Phoenix 1.8, AdonisJS 6), the **#1 highest priority item** is:

**Authentication & Authorization Scaffolding Generator** (`wheels generate auth`)

This is the single most impactful gap. Every competing framework now ships a built-in auth generator, making it table-stakes for 2025-2026. Wheels currently has documentation patterns, a legacy plugin (`authenticateThis`), and example code — but no CLI generator that produces a working auth system out of the box.

---

## Gap Analysis: What Wheels Has vs. What's Missing

### Table-Stakes Features (Must-Have in 2025-2026)

| Feature | Wheels Status | Competitor Status |
|---------|--------------|-------------------|
| Authentication scaffolding/generator | **MISSING** — manual patterns only | Every framework has this |
| Authorization system (policies/gates) | **MISSING** — ad-hoc filters only | Laravel Gates+Policies, AdonisJS Bouncer, Rails Pundit |
| Database migrations + ORM | **HAS** | All frameworks |
| Background job system | **HAS** (database-backed) | All frameworks |
| Caching abstraction | **HAS** (page/action/partial/query) | All frameworks |
| CSRF/XSS/SQLi protection | **HAS** | All frameworks |
| CLI generators | **HAS** (model, controller, scaffold, migration) | All frameworks |
| Testing framework | **HAS** (TestBox-based BDD) | All frameworks |
| RESTful routing | **HAS** | All frameworks |
| Rate limiting | **HAS** (documented patterns) | All frameworks |
| File storage abstraction | **MISSING** — no unified API | Laravel Flysystem, Rails Active Storage, AdonisJS Drive |
| Event/listener system | **PARTIAL** — `app/events/` exists | All frameworks |
| Structured logging | **HAS** (basic) | All frameworks |

### Highly Desirable Features (Competitive Differentiators)

| Feature | Wheels Status | Best-in-Class |
|---------|--------------|---------------|
| Multi-channel notifications | **MISSING** | Laravel (mail, SMS, Slack, DB, broadcast) |
| Model factories for testing | **MISSING** | Laravel (built-in), Rails (FactoryBot) |
| Health check endpoints | **MISSING** | NestJS Terminus |
| OpenTelemetry/observability | **MISSING** | Phoenix LiveDashboard, Laravel Pulse/Telescope |
| OpenAPI/Swagger generation | **MISSING** | NestJS (first-party), Django (drf-spectacular) |
| WebSocket support | **MISSING** (has SSE only) | Phoenix Channels, Rails Action Cable, Laravel Reverb |
| REPL/interactive console | **MISSING** | Laravel Tinker, Rails Console, Django shell |
| Full-text search | **MISSING** | Laravel Scout, Django built-in (PostgreSQL) |
| Real-time (LiveView equivalent) | **MISSING** | Phoenix LiveView, Laravel Livewire |
| API versioning tooling | **PARTIAL** (convention only) | NestJS (built-in), Django DRF |

### Features Where Wheels Excels

| Feature | Wheels Advantage |
|---------|-----------------|
| Query Scopes + Chainable Builder | Comparable to Laravel/Rails scopes |
| Enums with auto-generated methods | Clean implementation with boolean checkers + scopes |
| Batch Processing | `findEach` / `findInBatches` — comparable to Rails |
| SSE (Server-Sent Events) | Built-in; most frameworks don't have first-party SSE |
| Database breadth | SQLite, Oracle, MySQL, PostgreSQL, SQL Server, H2 |
| Engine breadth | Adobe CF, Lucee, BoxLang — unique multi-runtime |
| MCP Integration | Unique AI-IDE integration, no competitor has this |
| Background Jobs (DB-backed) | Follows Rails 8 / Django 6 trend of no-Redis jobs |

---

## Priority Ranking: What to Build Next

### Priority 1 (RECOMMENDED): Authentication & Authorization Generator

**Why this is #1:**

1. **Every competitor has it** — It's the clearest table-stakes gap
   - Laravel: Breeze + Jetstream (full UI scaffolding with 2FA, API tokens)
   - Rails 8: `rails generate authentication` (built-in since Rails 8)
   - Phoenix 1.8: `mix phx.gen.auth` (with magic links and sudo mode)
   - Django: `django.contrib.auth` (built-in module)
   - AdonisJS: Built-in auth module with session + token guards

2. **First thing developers need** — Nearly every web app requires auth. Having to manually implement it (or use a Wheels 2.0-era plugin) creates immediate friction for new adopters.

3. **Foundation for other features** — Authorization, API tokens, and multi-channel notifications all build on having a solid auth layer.

4. **Existing building blocks** — Wheels already has:
   - `authenticateThis` plugin (BCrypt hashing, password validation)
   - Comprehensive documentation patterns (`.ai/wheels/patterns/authentication.md`)
   - Controller filter system (before/after filters)
   - Session management
   - Flash messages
   - Mailer system (`app/mailers/`)
   - CSRF protection
   - Starter app examples

**What `wheels generate auth` should produce:**

| Component | Files Generated |
|-----------|----------------|
| Migration | `[timestamp]_create_users_table.cfc` — users table with email, passwordHash, salt, rememberToken, emailVerifiedAt, timestamps |
| Model | `app/models/User.cfc` — validations, BCrypt hashing, authenticate(), roles |
| Controller | `app/controllers/Sessions.cfc` — login/logout actions with filters |
| Controller | `app/controllers/Registrations.cfc` — signup flow |
| Controller | `app/controllers/Passwords.cfc` — forgot/reset password |
| Views | Login form, registration form, forgot password form, reset password form |
| Routes | Auth routes in `config/routes.cfm` |
| Mailer | `app/mailers/AuthMailer.cfc` — verification + password reset emails |
| Tests | `tests/models/UserTest.cfc`, `tests/controllers/SessionsTest.cfc` |
| Global helper | `app/global/auth.cfm` — `currentUser()`, `isLoggedIn()`, `requireAuth()` |

**Stretch goals for v1:**
- `--api` flag for token-based API authentication (like Laravel Sanctum)
- `--2fa` flag for TOTP two-factor authentication
- Remember me / persistent sessions
- Account lockout after failed attempts
- Email verification flow

### Priority 2: File Storage Abstraction

**Why:** Table-stakes feature. Every modern app handles file uploads. Currently Wheels has no unified API for local/S3/cloud storage.

**Reference:** Laravel's Flysystem integration, Rails Active Storage, AdonisJS Drive

**Scope:** `put()`, `get()`, `delete()`, `url()`, `exists()` with local + S3 drivers. `fileField()` view helper integration.

### Priority 3: Multi-Channel Notification System

**Why:** Laravel's notification system is a massive DX win. A single `Notification` class that can send via email, database, SMS, and Slack simultaneously.

**Reference:** Laravel Notifications (the gold standard in this category)

**Scope:** `app/notifications/` directory, channel drivers (mail, database), `user.notify()` method, database notification storage with read/unread.

### Priority 4: Model Factories for Testing

**Why:** Testing productivity multiplier. Creating test data is painful without factories.

**Reference:** Laravel Eloquent Factories, Rails FactoryBot

**Scope:** `tests/factories/UserFactory.cfc` with `factory("User").create()`, `factory("User").make()`, state modifiers, relationships.

### Priority 5: Interactive Console (REPL)

**Why:** Every major framework has one. Essential for debugging and exploring models.

**Reference:** Laravel Tinker, Rails Console, Django shell

**Scope:** `wheels console` command that boots the app and lets you run `model("User").findAll()` interactively.

### Priority 6: Authorization System (Policies)

**Why:** Structured authorization beyond ad-hoc filter methods. Especially important once auth scaffolding exists.

**Reference:** Laravel Gates + Policies, AdonisJS Bouncer

**Scope:** `app/policies/UserPolicy.cfc` with `can("update", post)` helpers, automatic policy resolution.

### Priority 7: Health Check Endpoints

**Why:** Essential for production monitoring and container orchestration (Docker, Kubernetes).

**Reference:** NestJS Terminus, Laravel health packages

**Scope:** `/health` endpoint checking database, disk space, memory, custom checks.

### Priority 8: Observability Dashboard

**Why:** Phoenix LiveDashboard and Laravel Telescope/Pulse show how valuable built-in observability is.

**Reference:** Phoenix LiveDashboard, Laravel Telescope

**Scope:** Built-in route showing recent requests, slow queries, job status, cache hit rates.

---

## Competitive Positioning Summary

```
Feature Maturity Comparison (approximate coverage of table-stakes features):

Laravel      ████████████████████ 95%  — most complete ecosystem
Rails 8      ██████████████████░░ 90%  — Solid trifecta, Kamal 2
Django 6     █████████████████░░░ 85%  — built-in tasks, CSP
Phoenix 1.8  ████████████████░░░░ 80%  — LiveView, real-time king
AdonisJS 6   ██████████████░░░░░░ 70%  — TypeScript-native, growing
Wheels 3.1   ██████████░░░░░░░░░░ 55%  — strong ORM, missing auth/storage/notifications
```

**Wheels' unique strengths** (multi-runtime CFML, MCP integration, database breadth) differentiate it, but the auth/storage/notification gaps are what new developers notice first when evaluating the framework.

**Closing the auth gap alone would move Wheels to ~65%** and remove the single most visible friction point for new adoption.

---

## Recommended Next Step

Build `wheels generate auth` as the next framework feature. It has the highest impact-to-effort ratio, builds on existing infrastructure, and addresses the most visible competitive gap.
