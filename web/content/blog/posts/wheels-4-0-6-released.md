---
title: 'Wheels 4.0.6: generate auth, policies, and storage — plus the mixin-cache speed fix'
slug: wheels-4-0-6-released
publishedAt: '2026-08-21T01:00:00.000Z'
updatedAt: '2026-08-21T01:00:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
categories:
  - Releases
excerpt: >-
  Wheels 4.0.6 is the first 4.0 feature release after 4.0.5's hardening pass —
  one-command authentication (`wheels generate auth`), an authorization policy
  layer, pluggable local/S3 storage disks, query-builder chains that can start
  with `select()`, and the mixin-plan cache that was making 4.0.x feel slow.
  Also: Adobe `onApplicationEnd` teardown, tenant/pagination request-key
  collisions, test-runner isolation, and a production gate on `/wheels`.
---

Wheels 4.0.6 is out. After [4.0.5](https://blog.wheels.dev/posts/wheels-4-0-5-released/)'s hardening and install-anywhere work, this is the first 4.0 release that's about what you can build: **one-command authentication, an authorization policy layer, pluggable storage disks, and a query builder that finally lets `select()` start a chain.** It also lands the mixin-plan cache that was making 4.0.x apps and test suites feel slower than 2.x.

Full notes: [GitHub Release v4.0.6](https://github.com/wheels-dev/wheels/releases/tag/v4.0.6) · [CHANGELOG 4.0.6](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md)

## Authentication you can generate

`wheels generate auth` ([#3155](https://github.com/wheels-dev/wheels/issues/3155)) scaffolds a session-based auth stack on the `wheels.auth` primitives: a `User` model with PBKDF2 password hashing, `Sessions` / `Passwords` / `Registrations` controllers (registration on by default; `--no-registration` to turn it off), CSRF-safe views, a create-users migration with a unique email index, and the route / service / strategy blocks injected into `config/routes.cfm`, `config/services.cfm`, and `app/events/onapplicationstart.cfm`. Generated files are code you own — stamped headers, and `--force` replaces the injected blocks in place instead of duplicating them.

`--strategy=token` and `--strategy=jwt` emit an `api/Sessions.cfc` instead (opaque SHA-256 bearer tokens, or JWTs signed with `WHEELS_JWT_SECRET` that fail loudly at startup if the secret is missing).

Underneath is **`wheels.auth.PasswordHasher`**: PBKDF2-HMAC-SHA256 (600,000 iterations by default), a self-describing modular-crypt storage format, constant-time `verify()`, and `needsRehash()` for work-factor upgrades. Hashes are byte-identical across Lucee, Adobe CF, and BoxLang, so they survive an engine move.

## Policies and storage disks

Authorization is a default-deny `wheels.Policy` base class ([#3156](https://github.com/wheels-dev/wheels/issues/3156)): `authorize()` / `can()` / `policyScope()` in controllers and views, `wheels generate policy`, and a new Authorization Policies guide. A missing policy class throws in development/testing and silently denies in production. The current user resolves through the `currentUser` DI service, then the configured authenticator, then guest.

Storage is a named-disk abstraction ([#3157](https://github.com/wheels-dev/wheels/issues/3157)) — `LocalDisk` and `S3Disk` behind `put` / `get` / `exists` / `delete` / `url` / `signedUrl`. S3, including presigned URLs, is a from-scratch SigV4 signer over `cfhttp`. No AWS SDK, no JARs.

Auth, hasher, policies, and disks are the first slice of the [#2962](https://github.com/wheels-dev/wheels/issues/2962) epic.

## Query builder: `select()` can start the chain

`select()`, `include()`, `group()`, `distinct()`, and `forUpdate()` can now start a chain on the model class ([#3346](https://github.com/wheels-dev/wheels/issues/3346)):

```cfml
model("Person").select("id,firstName").where("department", "engineering").get()
```

That matches `where()` and the other entry-position builder methods. On 4.0.5, starting with `select()` threw `MethodNotFound`.

`findAll` / `findOne` / `findByKey` also take **`includeCalculated`** ([#3252](https://github.com/wheels-dev/wheels/issues/3252)) — opt a `select=false` calculated property back into a finder without replacing the default column list. Unknown names throw in development/testing and are ignored in production.

## The 4.0.x slowness

Model, controller, and mapper creation no longer re-scan the mixin folders on every materialization. The mixin-integration plan is built once per application and reused ([#3213](https://github.com/wheels-dev/wheels/issues/3213)). Model-instance creation is roughly half the cost — every `new()` and every finder row was paying the full directory-list + `createObject` + `getMetaData` tax. If 4.0.x felt slower than 2.x in tests or on the request path, this is that regression.

`vendor/wheels/Global.cfc` is no longer a 4,800-line monolith ([#3241](https://github.com/wheels-dev/wheels/issues/3241)): helpers live in focused `vendor/wheels/global/*.cfm` includes. The public `$`-prefixed mixin surface is unchanged.

## Fixes that bit people

- **Adobe `onApplicationEnd` teardown** ([#3379](https://github.com/wheels-dev/wheels/issues/3379)). On Adobe CF 2023, bare `application.wo` during `applicationStop()` could throw `Element wo is undefined in a Java object of type class [Ljava.lang.String;` and take the site down until a CF service restart. The template now goes through `arguments.applicationScope.wo` (guarded). Existing 4.0.5 apps need the same edit in `public/Application.cfc`.
- **Tenant and pagination request keys** ([#3336](https://github.com/wheels-dev/wheels/issues/3336), [#3339](https://github.com/wheels-dev/wheels/issues/3339)). Finder cache and pagination handles no longer sit in the same case-insensitive keyspace as `request.wheels.tenant` / `params` / `flashKeep`. A model named `Tenant` — the documented control-plane name — could wipe or impersonate the resolved tenant; `setPagination(handle="tenant")` could do the same.
- **Test-runner isolation** ([#3374](https://github.com/wheels-dev/wheels/issues/3374)). `/wheels/core/tests` and `/wheels/app/tests` bind a separate CFML application name when `Application.cfc` includes `vendor/wheels/events/testcontext.cfm`. The live `application.wheels` is no longer swapped for the run. The snippet ships in `wheels new`; existing apps keep the previous named-lock swap until they add the include.
- **`wheels packages add`** ([#3378](https://github.com/wheels-dev/wheels/issues/3378)). Docs, `--help`, and the packages site now agree: `wheels packages install` is intercepted by LuCLI and does not install anything. Copy Basecoat showcase files from `vendor/` after `add`, not from the raw GitHub tree.
- **`/wheels` welcome** is gated with `$blockInProduction()` like every other Public handler, so it no longer renders outside development when `enablePublicComponent` is on.

Cross-engine: Adobe `FileWrite()` trailing-LF on storage puts, BoxLang `Evaluate()` fall-through, and PostgreSQL / Yugabyte / Cockroach catalog bleed when an app table shares a name with `information_schema` (`sequences`, `columns`, …).

…and a long tail of association, migrator, CSRF-cookie, and test-runner fixes. The complete list is in the [changelog](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md).

## Install / upgrade

Same four channels as 4.0.5:

```bash
# macOS / Linux — Homebrew
brew install wheels-dev/wheels/wheels

# Windows — Scoop
scoop bucket add wheels https://github.com/wheels-dev/scoop-wheels
scoop install wheels

# Debian / Ubuntu — apt
curl -fsSL https://apt.wheels.dev/wheels.gpg | sudo gpg --dearmor -o /usr/share/keyrings/wheels.gpg
echo "deb [signed-by=/usr/share/keyrings/wheels.gpg] https://apt.wheels.dev stable main" | sudo tee /etc/apt/sources.list.d/wheels.list
sudo apt update && sudo apt install wheels

# RHEL / Fedora / Rocky / Alma — dnf
sudo dnf config-manager --add-repo https://yum.wheels.dev/wheels.repo
sudo dnf install wheels
```

Upgrade:

```bash
brew upgrade wheels                                          # Homebrew
scoop update wheels                                          # Scoop
sudo apt update && sudo apt install --only-upgrade wheels    # apt
sudo dnf upgrade wheels                                      # dnf
```

Then confirm:

```bash
wheels --version   # Wheels Version: 4.0.6
```

The framework itself lives in `vendor/wheels/` in your app — run `wheels upgrade check` to see anything worth adjusting before you bump a project, or `wheels upgrade apply` to swap it. Happy shipping.
