---
title: >-
  wheels.dev Goes Public: A Production Wheels 3.0 Application You Can Actually
  Study
slug: >-
  wheels-dev-goes-public-a-production-wheels-3-0-application-you-can-actually-study
publishedAt: '2026-03-05T14:00:00.000Z'
updatedAt: '2026-03-04T00:53:06.560Z'
author: Peter Amiri
tags:
  - launch
  - open-source
  - wheels-dev
  - production
  - docker-swarm
categories:
  - Community
  - Releases
  - Website
excerpt: >-
  Most framework documentation tells you how to build something. The Wheels
  community site at wheels.dev is something different -- it's a production
  application built with Wheels 3.0 that you can act...
coverImage: null
legacyId: '1151027108231184385'
---

Most framework documentation tells you _how_ to build something. The Wheels community site at wheels.dev is something different -- it's a production application built with Wheels 3.0 that you can actually look at, poke around, and learn from. We've made the source public, and this article walks through how the site is built, how it's deployed, and how it comes to life inside a Docker Swarm.

## Why Make the Site Public?

Framework examples tend to be toy applications. They show you the syntax but not the patterns. They demonstrate a feature in isolation but never show you how thirty features work together in something real.

wheels.dev is a real application with real users. It has a blog system with moderation workflows, user authentication with role-based access control, a documentation viewer, newsletter management, an admin dashboard, and a full API layer. It handles file uploads, session clustering across multiple replicas, transactional email, and error tracking. It's the kind of application that exposes the decisions frameworks force you to make -- and shows how Wheels 3.0 handles them.

By making the source public, we're turning the community site into the most comprehensive Wheels 3.0 example that exists.

## The Architecture

At its core, wheels.dev follows the MVC pattern that Wheels is built around, but scaled to production complexity.

### Models: 31 ActiveRecord Components

The data layer uses Wheels' ActiveRecord ORM with 31 model components. The `Blog` model alone demonstrates associations (`belongsTo` User, `hasMany` Comments, Tags, Categories, and ReadingHistory), validations, callbacks, and soft deletes tracked through `deletedAt` and `deletedBy` columns. The `User` model handles password hashing via bcrypt, role associations, and relationships to everything a user can create or interact with.

Other models handle the supporting infrastructure: `RememberToken` for persistent login sessions, `PasswordReset` for email-based recovery flows, `LoginAttempt` for security tracking, `Newsletter` and `NewsletterSubscriber` for email campaigns, `Testimonial` with an approval workflow, and `CachedRelease` for caching ForgeBox release data.

The database runs on CockroachDB, accessed through a standard PostgreSQL JDBC driver -- CockroachDB speaks the PostgreSQL wire protocol, so Wheels connects to it like any other Postgres database. The schema is managed entirely through timestamped migration files -- over 20 of them covering 25+ tables with foreign key constraints, indexes, and referential integrity.

And yes, we're dogfooding here. Wheels currently supports six databases: MySQL, PostgreSQL, SQL Server, H2, Oracle, and SQLite. Running the community site on CockroachDB is our way of putting a seventh database adapter through its paces in production. Anybody hear a seventh supported database coming?

### Controllers: Three Namespaces

Controllers are organized into three distinct namespaces, each serving a different concern:

- **`web.*`** handles public-facing pages -- the homepage, blog listing and detail views, guides, documentation, community pages, and authentication flows
- **`admin.*`** powers the dashboard for content moderation, user management, settings, newsletter administration, and testimonial approval
- **`api.*`** exposes RESTful endpoints for blog content, downloads, and authentication

A base `Controller.cfc` provides shared infrastructure: CSRF protection via `protectsFromForgery()`, authentication helpers, role-based access checks, and reusable query methods for fetching blogs with their associated tags, categories, and attachments.

### Routing: RESTful by Convention

The routing configuration in `config/routes.cfm` demonstrates Wheels' mapper DSL at scale. API routes live under `/api/v1/` with proper REST verb mapping. The blog supports filtering by category, author, and tag through clean URLs like `/blog/categories/[slug]`. Admin routes are grouped under `/admin/` with consistent CRUD patterns. The guides system supports versioned paths (`/3.0.0/guides/[path]`) for serving documentation across framework releases.

### Views: Server-Rendered with HTMX

The view layer uses CFML templates with a main `layout.cfm` that handles page titles, meta tags, and content-specific rendering. Where dynamic interactivity is needed -- loading comments, filtering blog posts, toggling UI states -- the site uses HTMX rather than a JavaScript framework. This keeps the architecture simple: the server renders HTML fragments, and HTMX swaps them into the page without full reloads.

## Features Worth Studying

Several features in the codebase demonstrate patterns that go beyond what you'd find in a tutorial.

### Authentication and Session Management

User authentication supports registration with email verification, login with bcrypt password hashing, and a "Remember Me" system that stores hashed tokens with user-agent validation. If someone's token doesn't match their current browser fingerprint, the token is invalidated -- a practical defense against session theft.

Sessions are configured with a 2-hour timeout and a 30-minute idle logout, with session storage backed by CockroachDB so that sessions persist across container restarts and are shared across all Swarm replicas. The `onRequestStart` event handler checks for idle timeouts and validates remember-me tokens on every request.

### Role-Based Access Control

The permission system uses a `User -> Role -> Permission` hierarchy. Controllers check access through methods like `checkAdminAccess()` and `checkRoleAccess()`, gating entire controller actions based on the authenticated user's role. The admin namespace uses before-filters to enforce this consistently.

### Blog Content Workflow

Blog posts follow a multi-status lifecycle: Draft, Pending Approval, Approved, and Rejected. Authors create and submit posts; administrators moderate them through the admin dashboard with bulk actions. Comments have their own moderation queue. Reading history and bookmarks are tracked per user. The system generates XML sitemaps and RSS-compatible comment feeds.

### Caching Strategy

The site uses a 10-minute RAM cache for frequently accessed queries and a dedicated cache for contributor data that's expensive to fetch from external sources. This caching layer is configured in `config/app.cfm` and works transparently with the ORM.

## How the Site is Deployed

The deployment pipeline is triggered by any push to the `main` branch of the wheels.dev repository. Here's what happens.

### Building the Container

A GitHub Actions workflow runs on a standard Ubuntu runner. It generates an environment file from encrypted GitHub Secrets -- connection details for the CockroachDB cluster, SMTP credentials for Postmark (transactional email), a Sentry DSN for error tracking, an ID salt for obfuscating database identifiers in URLs, and admin passwords.

The workflow installs CommandBox (a CFML build tool and dependency manager), runs `box install` to pull all dependencies including the Wheels core framework, and builds a Docker image. The Dockerfile starts from `ortussolutions/commandbox:lucee6`, adds a PostgreSQL JDBC driver, copies in the application code and a production-tuned `server.json`, and disables the browser auto-launch that CommandBox includes for local development.

The image is tagged with both `:latest` and the Git commit SHA, then pushed to GitHub Container Registry.

### Deploying to the Swarm

A self-hosted GitHub Actions runner inside the Docker Swarm cluster picks up the deployment job. It authenticates with the container registry and runs `docker stack deploy`, which reconciles the running state with the desired state defined in `docker-compose.yml`.

The stack deploys **three replicas** of the application. Rolling updates proceed one container at a time with a 15-second delay, using a start-first strategy -- the new replica must be running and healthy before the old one is removed. Rollbacks follow the same one-at-a-time pattern with a 10-second delay.

Each replica gets up to 2 CPUs and 4 GB of memory, with the JVM tuned to a 2 GB minimum and 3 GB maximum heap. A Traefik reverse proxy handles load balancing and routing based on the `Host` header. Because sessions are stored in CockroachDB with clustering enabled, any replica can serve any request -- there's no need for sticky sessions or session affinity cookies.

### Shared Storage

One of the trickier aspects of running a stateful web application across multiple replicas is file storage. Uploaded images, file attachments, generated sitemaps, versioned documentation, and API JSON responses all need to be accessible from every replica.

The solution is CephFS-backed volumes mounted into each container at specific paths: `/app/public/images`, `/app/public/files`, `/app/public/sitemap`, `/app/docs/3.0.0/guides`, and `/app/public/json`. When a user uploads an image through replica 1, replicas 2 and 3 can serve it immediately.

A separate `/data` volume provides general application state storage that persists across deployments.

### The Warmup Sequence

This is one of the most important parts of the deployment, and it's easy to overlook. CFML applications running on the JVM suffer from cold-start latency -- the first request to any template triggers compilation, class loading, and JIT warm-up. In a user-facing application, that first request could take several seconds.

The `server.json` configuration includes a warmup directive that fires immediately after the server starts, before it begins accepting external traffic:

```
/index.cfm, /blog, /blog/list, /blog/Categories, /guides,
/3.0.0/guides, /api, /api/3.0.0/, /docs, /community,
/news, /downloads, /login
```

These 13 URLs are hit sequentially with a 5-minute timeout window using a queued request strategy. By the time the replica joins the Swarm's load balancer rotation, every major route has been compiled, the template cache is warm, database connection pools are established, and the JVM has had a chance to JIT-compile the hot paths.

The result: users never hit a cold replica.

### The Network Edge

External traffic reaches the application through a Cloudflare tunnel, which handles TLS termination, DDoS protection, and edge caching. Inside the Swarm, Traefik routes requests to the three replicas over an overlay network. A middleware rule redirects `www.wheels.dev` to the apex `wheels.dev` domain.

## What Makes It a "Model" Application

The term "model application" means something specific here. It's not just that wheels.dev runs on Wheels -- it's that every architectural decision in the codebase represents a recommended pattern.

The controller namespacing (`web`, `admin`, `api`) shows how to organize a growing application. The base controller demonstrates cross-cutting concerns like authentication and CSRF protection. The model layer shows associations, validations, and soft deletes working together in a real schema. The routing configuration demonstrates RESTful conventions, versioned API paths, and clean URL patterns. The migration files show incremental schema evolution.

The deployment configuration shows how a Wheels application transitions from development to production: environment-specific config overrides, container-based deployment, session clustering, shared storage, and zero-downtime updates.

It's the complete picture -- not a tutorial, not a toy, but a running application that developers can study, fork, and learn from.

## Get Involved

The wheels.dev source is public. Browse the code, open issues, suggest improvements, or use it as a reference for your own Wheels 3.0 projects. The repository includes a `CLAUDE.md` with AI-assisted development guidance and a comprehensive README to help you get oriented.

If the best documentation is working code, then wheels.dev is the best Wheels 3.0 documentation we could write.
