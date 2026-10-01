---
title: 'Wheels 4.1.2: deploy that builds and pushes, honest CLI exit codes, and four security fixes'
slug: wheels-4-1-2-released
publishedAt: '2026-10-01T12:47:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
  - security
categories:
  - Releases
excerpt: >-
  Wheels 4.1.2 is a patch release on 4.1.x: `wheels deploy` now builds and
  pushes the image it deploys, failing CLI commands exit non-zero, migrations
  can opt out of the per-step transaction, a new `baseUrl` setting, migrator and
  model fixes, tighter gates on the development tools, and four security fixes.
  Upgrading is recommended; a few generated-app files need small edits.
coverImage: '/blog-images/4-1/wheels-4-1-2-released.png'
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/3917'
  title: 'Wheels 4.1.2 is out'
  body: |
    **[Wheels 4.1.2 is released](https://blog.wheels.dev/blog/wheels-4-1-2-released)**, a patch release on the 4.1.x line.

    - `wheels deploy` and `wheels deploy setup` now build and push the image before deploying it
    - Failing CLI commands exit non-zero, and the MCP tools report them as errors
    - Migrations can opt out of the per-step transaction with `this.useTransaction = false`
    - New `baseUrl` setting for canonical absolute URLs
    - Includes four security fixes; upgrade recommended

    Some apps need small edits after upgrading; the blog post lists them.

    - Blog post: https://blog.wheels.dev/blog/wheels-4-1-2-released
    - GitHub Release: https://github.com/wheels-dev/wheels/releases/tag/v4.1.2

    **Upgrade:** `brew upgrade wheels` / `scoop update wheels` / `apt upgrade wheels` / `dnf upgrade wheels`, then `wheels upgrade check` and `wheels upgrade apply`.

    Questions or anything that doesn't behave as described: reply here or [open an issue](https://github.com/wheels-dev/wheels/issues/new/choose).
---

Wheels 4.1.2 is out. It's a patch release on the 4.1.x line: **CLI commands that report failure through their exit code, a `wheels deploy` that actually builds and pushes the image it deploys, migrator and model fixes, tighter gates on the development tools, and four security fixes.** It's available on Homebrew, Scoop, apt and yum/dnf now, and we recommend upgrading.

Full notes: [GitHub Release v4.1.2](https://github.com/wheels-dev/wheels/releases/tag/v4.1.2) · [CHANGELOG](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md)

## Security fixes

4.1.2 includes four security fixes, each with its own advisory:

- **CLI name and value validation** ([GHSA-cghp-86c6-6fjc](https://github.com/wheels-dev/wheels/security/advisories/GHSA-cghp-86c6-6fjc)). The Wheels CLI now validates the names and values it turns into paths and commands: `wheels deploy` versions and destinations, deploy config images and hosts, `wheels packages` names, and every name `wheels generate` and `wheels destroy` write. `wheels generate` refuses to write any file outside the project, including through a symlink. Values from `.kamal/secrets` are redacted from dry-run and printed deploy commands, and `wheels deploy init` creates `.kamal/secrets` owner-only (0600). Scaffolded and admin views now HTML-encode record data.
- **Error email recipient** ([GHSA-8gcv-3v9h-7gj2](https://github.com/wheels-dev/wheels/security/advisories/GHSA-8gcv-3v9h-7gj2)). Error emails no longer go to an address derived from the request. `errorEmailAddress` used to default to `webmaster@` plus the last two labels of the Host header; it now defaults to `""`, and with no recipient configured no error email is sent. Wheels writes a one-time warning to `wheels.log` instead.
- **Finder values bound as parameters** ([GHSA-96rm-h22v-925x](https://github.com/wheels-dev/wheels/security/advisories/GHSA-96rm-h22v-925x)). Values passed to dynamic finders, the query builder's `where()`, `findByKey()` / `updateByKey()` / `deleteByKey()` on string and UUID keys, and `validatesUniquenessOf()` are now bound as query parameters. Before, a value containing a quote could change the shape of the WHERE clause. A value with an apostrophe (`O'Brien`) still matches as before, and numeric columns were not affected.
- **IP-based debug access scoped to the request** ([GHSA-8r22-vwcc-v55m](https://github.com/wheels-dev/wheels/security/advisories/GHSA-8r22-vwcc-v55m)). IP-based debug access now grants the debug GUI and error details to the allowed client's own request only, instead of switching them on in the shared `application.wheels` scope. Apps with the setting off (the default) are unaffected.

Three of these come with app edits; see "If you're upgrading" below.

## Deploy builds and pushes

`wheels deploy` and `wheels deploy setup` now build and push the image before deploying it, as the guides describe ([#3874](https://github.com/wheels-dev/wheels/pull/3874)). They log in to the registry on your machine and on every host (the password travels only on stdin), run `docker buildx build --push`, then pull on the hosts. Pass `--skip-push` when that version's image is already pushed.

The same PR passes the `host` and `ssl` settings to kamal-proxy (TLS and host-based routing were silently dropped before), fixes `wheels deploy rollback` on worker hosts, and makes `--destination=<name>` fail when `config/deploy.<name>.yml` doesn't exist.

## A CLI you can script against

- **Failures exit non-zero** ([#3863](https://github.com/wheels-dev/wheels/pull/3863)). `wheels generate` refusals, missing arguments, `wheels doctor` at CRITICAL and more no longer report success, including through the MCP tools. Scripts that relied on exit 0 after printing usage need the arguments they were missing.
- **`wheels generate app --dry-run` writes nothing** ([#3858](https://github.com/wheels-dev/wheels/pull/3858)). It used to print "Dry run — nothing will be written" and then create the whole app.
- **`wheels upgrade`** no longer silently downgrades the framework when `vendor/wheels/` is newer than the CLI's copy; pass `--allow-downgrade` if you mean it ([#3831](https://github.com/wheels-dev/wheels/pull/3831)). `upgrade check` reaches GitHub again ([#3854](https://github.com/wheels-dev/wheels/pull/3854)), exits non-zero when the lookup fails ([#3827](https://github.com/wheels-dev/wheels/pull/3827)), and accepts `--offline` ([#3871](https://github.com/wheels-dev/wheels/pull/3871)).
- **`wheels test` runs a single spec file** by dotted path or bare name ([#3797](https://github.com/wheels-dev/wheels/pull/3797)).
- **The apt/dnf launcher** ignores a `JAVA_HOME` older than Java 21 and uses the Java 21 the package installed ([#3766](https://github.com/wheels-dev/wheels/pull/3766)).
- **`wheels docs fetch`** verifies the bundle's SHA-512 checksum before unpacking ([#3823](https://github.com/wheels-dev/wheels/pull/3823)), and **`wheels coverage`** no longer reports 0% on a warm dev server ([#3859](https://github.com/wheels-dev/wheels/pull/3859)).

## Model and migrator

- Migrations can opt out of the per-step transaction with `this.useTransaction = false`, so a migration that touches a second datasource runs on Adobe ColdFusion ([#3792](https://github.com/wheels-dev/wheels/pull/3792)).
- `reload()` no longer truncates decimals (`149.25` became `149`, and the next `save()` wrote it back) ([#3818](https://github.com/wheels-dev/wheels/pull/3818)).
- An invalid `transaction` mode no longer leaves the connection marked as in a transaction ([#3817](https://github.com/wheels-dev/wheels/pull/3817)).
- The per-request query cache keys on the datasource a query actually runs against, after tenant resolution ([#3846](https://github.com/wheels-dev/wheels/pull/3846)).
- On SQLite and H2, new boolean columns from migrations are real `BOOLEAN` columns ([#3870](https://github.com/wheels-dev/wheels/pull/3870)).
- On Oracle, `whereBetween()` on a date column no longer fails ([#3877](https://github.com/wheels-dev/wheels/pull/3877)).

## Controllers, URLs and status codes

- A new **`baseUrl`** setting gives absolute URLs a canonical host, so emailed links and links built in background jobs no longer depend on how the request arrived ([#3838](https://github.com/wheels-dev/wheels/pull/3838)).
- A request for a format the action doesn't provide answers **406** instead of an empty 200 ([#3866](https://github.com/wheels-dev/wheels/pull/3866)).
- Error pages return status codes monitoring can trust: missing table, datasource or column is **500**, a bad CSRF token is **403** ([#3862](https://github.com/wheels-dev/wheels/pull/3862)), and 404 is an allow-list of client-triggerable not-found types ([#3872](https://github.com/wheels-dev/wheels/pull/3872)).
- `dateField()` emits a bare `yyyy-mm-dd` value, so `datetime` properties no longer show a blank date control ([#3856](https://github.com/wheels-dev/wheels/pull/3856)).

## If you're upgrading

These items ask for an edit in your app:

1. **Scaffolded controllers** ([#3868](https://github.com/wheels-dev/wheels/pull/3868)). In `requireRecord()`, replace the `Throw(` call with `$throwErrorOrShow404Page(` (same arguments), and wrap the `findByKey()` lookup so `Wheels.InvalidValue` is treated as a missing record. Make the same change in `app/snippets/CRUDContent.txt` if you keep it.
2. **Scaffolded and admin views** ([GHSA-cghp-86c6-6fjc](https://github.com/wheels-dev/wheels/security/advisories/GHSA-cghp-86c6-6fjc)). Wrap the `<h1>` value in `app/views/<plural>/show.cfm` and the field values in `index.cfm` in `encodeForHTML()`. Regenerate admin views with `wheels generate admin <Model> --force`.
3. **Session cookie** ([#3830](https://github.com/wheels-dev/wheels/pull/3830)). Apps created with 4.0.6-4.1.1 should update `this.sessionCookie.secure` in `public/Application.cfc`:

   ```cfm
   secure: (structKeyExists(variables, "currentEnv") && currentEnv == "production")
   	|| (IsBoolean(cgi.server_port_secure) && cgi.server_port_secure)
   	|| cgi.https == "on"
   	|| cgi.http_x_forwarded_proto == "https"
   ```

4. **`generate auth` logout** ([#3819](https://github.com/wheels-dev/wheels/pull/3819)). Add `if (!isPost() && !isDelete()) { redirectTo(route="login"); return; }` at the top of `delete()` in `app/controllers/Sessions.cfc`.
5. **IP-based debug access** ([GHSA-8r22-vwcc-v55m](https://github.com/wheels-dev/wheels/security/advisories/GHSA-8r22-vwcc-v55m)). If you use it, replace the IP-based access block in `onRequestStart()` with `application.wo.$applyIPDebugAccess();`, and in `onRequestEnd()` replace `application.wheels.showDebugInformation &&` with `application.wo.$get("showDebugInformation") &&`.
6. **Error emails** ([GHSA-8gcv-3v9h-7gj2](https://github.com/wheels-dev/wheels/security/advisories/GHSA-8gcv-3v9h-7gj2)). Apps that relied on the default must set `errorEmailAddress` (or `errorEmailToAddress`) explicitly.
7. **Startup error page** ([#3795](https://github.com/wheels-dev/wheels/pull/3795)). Copy the updated `$renderMinimalError()` and related helpers from the current `wheels new` template into `public/Application.cfc`.
8. **Custom local hostnames** ([#3850](https://github.com/wheels-dev/wheels/pull/3850)). If you reach the dev tools as something like `myapp.test`, allow it with `set(devToolsAllowedHosts="myapp.test")`.
9. **Behind a TLS proxy** ([#3835](https://github.com/wheels-dev/wheels/pull/3835)). Wheels 4.2 will require `trustProxyHeaders=true` to honour `X-Forwarded-Proto`; set it now if you're behind a trusted reverse proxy.

## Install / upgrade

```bash
brew upgrade wheels                                          # Homebrew
scoop update wheels                                          # Scoop
sudo apt update && sudo apt install --only-upgrade wheels    # apt
sudo dnf upgrade wheels                                      # dnf
```

Then confirm:

```bash
wheels --version   # 4.1.2
```

In each app, run `wheels upgrade check`, then `wheels upgrade apply` to swap `vendor/wheels/`. Happy shipping.
