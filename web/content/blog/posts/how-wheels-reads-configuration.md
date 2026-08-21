---
title: How Wheels Actually Reads Your Configuration
slug: how-wheels-reads-configuration
publishedAt: '2026-07-15T14:00:00.000Z'
updatedAt: '2026-07-06T05:06:04.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - configuration
  - environments
  - deployment
categories: []
excerpt: >-
  Why exporting WHEELS_ENV=production doesn't flip your app into production —
  and everything else about the config pipeline: the three-file load order,
  the .env chain that shadows OS variables, what production mode really
  changes, and the reload gate's fail-closed mechanics.
coverImage: null
---

Here's a support thread we've seen a dozen times, most recently in our own issue tracker: someone exports `WHEELS_ENV=production` on their server, deploys, and the app comes up in development mode — debug bar, stack traces, the works. The variable is set. They can `echo` it. Wheels ignores it.

That's not a bug. It's the collision of two configuration systems that look related and aren't — and once you see how Wheels actually reads configuration, top to bottom, the behavior is predictable every time. This post is that top-to-bottom: the load order, the `.env` pipeline, the `env()` lookup chain, what production mode really changes, and the reload mechanics that apply any of it to a running app.

## The three-file load order

At application start, Wheels reads exactly three configuration surfaces, in a fixed order:

1. **`config/environment.cfm`** — decides *which environment this deployment is*. The scaffold writes a hardcoded `set(environment="development")` here.
2. **`config/settings.cfm`** — your shared settings, every environment.
3. **`config/<environment>/settings.cfm`** — per-environment overrides. Loaded *after* the shared file, so whatever you `set()` here wins.

That's the whole precedence model: later wins, environment folder beats shared file. A per-environment datasource looks like this and nothing more:

```cfm
// config/settings.cfm — the shared default
set(dataSourceName = "myapp_dev");

// config/production/settings.cfm — production shadows it
set(dataSourceName = "myapp_production");
set(dataSourceUserName = env("DB_USER"));
set(dataSourcePassword = env("DB_PASSWORD"));
```

`set()` writes a value; `get()` reads it back anywhere in the app. Everything the framework itself configures — caching flags, debug flags, the reload password — lives in the same namespace and follows the same precedence.

## The `.env` pipeline (and who runs it)

Wheels 4's scaffolded `public/Application.cfc` gives you dotenv behavior with no dotenv library. At startup it:

1. Reads `.env` at the app root into a struct.
2. Resolves the current environment *name* — from `.env`'s `WHEELS_ENV` first, then the OS environment.
3. Layers `.env.<environment>` on top if present — so `.env.production` overrides `.env`.
4. Interpolates `${VAR}` references between entries.
5. Copies the merged struct to `application.env` when the application starts.

Then `env()` — the accessor you use in config files — looks things up in this exact order:

```
application.env             (the merged .env pipeline above)
        ↓ miss
server.system.environment   (real OS environment variables)
        ↓ miss
your default                env("DB_USER", "wheels")
```

Two consequences of that chain are worth pinning to the wall:

**`.env` beats the OS.** If a key exists in `.env`, an exported environment variable with the same name is never consulted. This is what bites the `WHEELS_ENV=production` deployer: the scaffolded `.env` ships with `WHEELS_ENV=development` in it, and that line shadows the export forever.

**Secrets stay out of source control by structure.** `.env` is git-ignored by the scaffold; `env("DB_PASSWORD")` in a committed config file is a *reference*, and the value lives on the box. Never write the literal.

## The misconception, resolved

So why doesn't `WHEELS_ENV=production` flip the app into production? Because — read step 1 of the load order again — **the environment is whatever `config/environment.cfm` sets**, and the scaffold hardcodes it. `WHEELS_ENV`'s only built-in effect is selecting which `.env.<name>` overlay loads. The environment *name* and the environment *setting* are two different systems that happen to share a word.

If you want the export to work the way you assumed — one artifact, environment decided by the machine — wire it yourself, and it's two edits:

```cfm
// config/environment.cfm
set(environment = env("WHEELS_ENV", "development"));
```

…and **delete the `WHEELS_ENV=development` line from `.env`**, because otherwise (see above) it shadows the OS export and you're back where you started. With both edits in place, `WHEELS_ENV=production` in your systemd unit, Dockerfile, or deploy script does exactly what it says. This is the recommended shape for anyone deploying the same artifact to multiple environments — and the [Environments and Configuration guide](https://guides.wheels.dev/v4-0-0/core-concepts/environments-and-configuration/) walks the same wiring with the gotchas annotated.

## What production mode actually changes

Flipping to `environment="production"` isn't cosmetic. The framework changes its own defaults:

- `showErrorInformation` → `false` — error pages stop leaking stack traces; visitors get your error page.
- `showDebugInformation` → `false` — the debug bar disappears.
- `cacheActions`, `cachePages`, `cachePartials`, `cacheQueries` → `true` — which is why "caching doesn't work" on your laptop and "my edits don't show up" on the server are the same fact wearing two costumes.
- `sendEmailOnError` → enabled — set `errorEmailToAddress` or the mail fails silently.
- URL-based environment switching → disabled (details below).
- Migrations refuse to run `down` — rollbacks in production are a deliberate act, not a URL away.
- The `/wheels/*` developer surfaces (migrator GUI, test runners, routes/info pages) → 404, behind a development-only allowlist that no setting overrides.

The [Production Configuration guide](https://guides.wheels.dev/v4-0-0/deployment/production-config/) has the full pre-boot checklist; the point here is that the environment name is load-bearing. "It works locally" and "it's broken in prod" often just means the two environments are running two different framework behaviors — as designed.

## Reload: applying config to a running app

Config files are read once, at application start. Changing them requires a restart — or the URL reload:

```
https://yourapp.example.com/?reload=true&password=<your-reload-password>
```

This re-runs the application start (and with it, all three config files) without touching the server. It's gated by `reloadPassword`, which the scaffold reads from `.env`:

```cfm
set(reloadPassword = env("WHEELS_RELOAD_PASSWORD", ""));
```

The gate's mechanics are stricter than they look, and each rule exists for a reason:

- **An empty password disables URL reload entirely** — fails closed, so a missing `.env` on a new box can't leave the door open.
- The comparison is **constant-time**, so the password can't be guessed a character at a time via timing.
- Failed attempts are **rate-limited** — five failures per client IP per five minutes — and every attempt, accepted or rejected, is logged to `wheels_security.log`.

There's a second form — `?reload=production&password=…` — which *switches* the running app into another environment. Powerful for staging boxes; alarming for production, which is why the gate on it, `allowEnvironmentSwitchViaUrl`, defaults to `false` in `production`, `testing`, and `maintenance`. Leave it that way. A leaked reload password plus URL switching plus production is a very bad afternoon. (In production and maintenance, `redirectAfterReload` also defaults on, so a successful reload 302s to a URL with the password stripped — it stays out of proxy logs and browser history.)

And that `maintenance` environment in the list is a real, first-class mode worth knowing: `set(environment="maintenance")` responds 503 and renders `app/events/onmaintenance.cfm` instead of running requests — except for IPs you list in `ipExceptions`, who see the real app. Planned downtime with a professional face, no server config involved.

## The mental model on a sticky note

```
WHICH env?    config/environment.cfm          (hardcoded, unless you wire env())
WHAT values?  settings.cfm → <env>/settings.cfm   (later wins)
SECRETS?      env() → application.env → OS env → default   (.env shadows OS!)
APPLY?        restart, or ?reload=true&password=…          (fails closed)
```

Four lines, and every "why is my config being ignored" mystery in Wheels resolves against one of them. The full reference — including the environment-switch mechanics and the per-environment artifact strategy — is the [Environments and Configuration guide](https://guides.wheels.dev/v4-0-0/core-concepts/environments-and-configuration/).

