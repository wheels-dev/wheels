---
title: Wheels 4.2.1 is out
slug: wheels-4-2-1-released
publishedAt: '2026-11-04T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - release-notes
  - frameworks
  - adobe-coldfusion
  - lucee
  - databases
categories:
  - Releases
excerpt: >-
  Wheels 4.2.1 is a patch release on 4.2.x: fixes for Adobe CF 2023 update 26 /
  2025 update 14's regex replacement regression, a Lucee 7.0.5.41 pin with its
  ESAPI encoding change, and database fixes including migrator DDL quoting for
  reserved-word tables and columns.
coverImage: '/blog-images/4-2/wheels-4-2-1-released.png'
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4681'
  title: 'Wheels 4.2.1 is out'
  body: |
    **[Wheels 4.2.1 is out](https://blog.wheels.dev/posts/wheels-4-2-1-released/)** — a patch release on 4.2.x with Adobe CF 2023 u26 / 2025 u14 regex fixes, a Lucee 7.0.5.41 pin and its ESAPI encoding change, and database fixes including migrator DDL quoting for reserved-word tables and columns.

    If you run Adobe CF 2023 u26 / 2025 u14, install this release and confirm the names and labels look right.

    Full notes: [GitHub Release v4.2.1](https://github.com/wheels-dev/wheels/releases/tag/v4.2.1)
  category: Announcements
---

Wheels 4.2.1 is out. It's a patch release on the 4.2.x line: no new features, just fixes for things that broke, a Lucee update, and database corrections across supported engines.

Full notes: [GitHub Release v4.2.1](https://github.com/wheels-dev/wheels/releases/tag/v4.2.1) · [CHANGELOG](https://github.com/wheels-dev/wheels/blob/main/CHANGELOG.md)

## Adobe CF 2023 update 26 / 2025 update 14 regex fixes

Adobe's CF 2023 update 26 / 2025 update 14 changed regex **replacement** parsing: the case-escape flags `\u`, `\l` and `\U` are now emitted as literal letters. That made a controller named `main` resolve as `umain`, corrupted hyphenated controller and action names, and prefixed `/wheels/info` setting labels with a stray `u`.

Wheels now upper-cases those four sites by walking characters instead of using a replacement escape. The same regression also turned the `\l` and `\U` flags into literal letters in hyphenized route names, flash argument keys and named-route derivation; those paths now use engine-neutral equivalents and produce the same output on unpatched engines.

If you run Adobe CF 2023 update 26 or 2025 update 14, this is the release to install. Confirmation from patched builds is still welcome — if you see a name that still comes out wrong, please open an issue with the input and the output.

## Lucee 7.0.5.41 and the ESAPI encoding change

New apps from `wheels new`, the starter app and the framework's own `lucee.json` now pin **Lucee 7.0.5.41** (previously 7.0.0.395). The Lucee 7 test image and CI lanes run 7.0.5.41 too. Existing apps keep the version in their own `lucee.json` — change `lucee.version` to `7.0.5.41` to update.

Lucee 7.0.5 and later use ESAPI extension 3.x for the HTML that view helpers encode (`encode=true` or `encode="attributes"`). It encodes only the characters that matter in each context: `/`, `:`, `(`, `)`, `[`, `]` and spaces stay literal, and a double quote becomes `&#34;` rather than `&quot;`. Earlier Lucee releases encoded those as `&#x2f;`, `&#x3a;` and so on. `<`, `&` and quotes are still encoded wherever they were, and browsers render both forms the same. Its canonicalization also keeps a backslash that precedes a quote (`\"`) instead of dropping it, so the value renders as written.

Tests that compare helper output against hard-coded encoded strings may need updating. That is expected: the output is still encoded for the context, but the character references are shorter.

## Database fixes

### Migrator DDL quoting for reserved words

The H2, PostgreSQL, CockroachDB and Oracle migrators now quote generated DDL identifiers in the same case as their model adapters:

- H2 in the datasource's own fold case (upper by default, lower with `DATABASE_TO_LOWER=TRUE`);
- PostgreSQL and CockroachDB in lowercase;
- Oracle in uppercase.

Migrations can now create reserved-word tables and columns — `"order"`, `"group"` — and still alter, rename or drop existing **unquoted** schemas, because the quoted fold-case names resolve the same catalog objects. With H2 identifier folding off, the migrator keeps the legacy unquoted path. `migratorObjectCase` now only applies to adapters that do not quote DDL.

### H2 JOIN memo and tenant isolation

Association JOIN caching for H2 tenants had a cross-tenant edge: a memoised JOIN built for one tenant could be reused for another when their datasources folded identifiers differently. The JOIN memo key now includes the adapter's identifier-quoting mode, and H2's fold-case classifier is a separately tested pure function.

### Queries and result shapes

- `select=` expressions that contain SQL functions with commas (`CONCAT`, `IF`, `COALESCE`, …) are no longer corrupted when used with `include=` or a distinct group-by query.
- Identifier quoting now doubles a closing delimiter inside a table or column name — `"` becomes `""`, a backtick becomes two, `]` becomes `]]` — so generated SQL stays well-formed and the name remains one identifier. This covers the SQLite, PostgreSQL, CockroachDB, Oracle, MySQL and SQL Server model adapters, and the SQLite, MySQL and SQL Server migrators. Dotted `schema.table` names are still quoted part by part. Oracle does not allow a double quote inside a quoted name at all, so there the escaping only keeps the SQL well-formed. Names without those characters are quoted exactly as before.
- XML rendering no longer throws when data contains a null value: null struct, array, query and component values are emitted as `type="null"` elements, and a null top-level value renders as a well-formed `<data type="null"/>` document. The date/time form helpers also coerce a null bound value to the empty selection instead of passing it to the select renderers.
- Extra query columns — custom `select=` aliases, joined columns, driver metadata — now follow the same key-casing rule as model properties when rows are returned as structs or JSON: lowercased when `resetPropertiesStructKeyCase` is enabled (the default), raw casing when it is disabled. Camel-cased `select` aliases therefore serialize in lowercase by default.

### Configuration, analysis and tooling

- `.env` values now coerce to numbers only when they are plain integers, so `007`, `1e3` and `+5` stay strings instead of being truncated to `7` and `1`, and a value that is a lone quote no longer errors. Apps generated by `wheels new` keep the old parser in their own `public/Application.cfc` until they copy the change.
- `wheels analyze` now reports `TODO`/`FIXME`/`HACK`/`XXX`/`BUG` markers that open a `/*` block comment or a doc-comment continuation line (` * FIXME ...`), not only `//` and `<!---` comments. It also stops reporting ordinary comments whose word merely starts with a marker (`BUGGY`, `TODOS`, `HACKATHON`, `XXXL`) as `todo-comment` technical debt; markers now match only as whole words.
- App test runs that omit `useTestDB` now honor `set(allowTestsAgainstPrimaryDatasource=true)` even when a `<datasource>_test` datasource is registered, running on the primary datasource with a warning. The DebugBar Test Suite panel's runner and "Open full runner" links pass `useTestDB=false` in that configuration, so they no longer swap the datasource unexpectedly.
- The Wheels CLI's runtime is **LuCLI 0.6.2.4**, which updates the CLI's bundled Jackson, JLine, Tomcat and Commons Lang libraries. No behaviour change.

## If you're upgrading

Upgrade the CLI first, then check and apply:

```sh
wheels upgrade check --to=4.2.1
wheels upgrade apply
```

The [4.1 to 4.2 upgrade guide](https://guides.wheels.dev/v4-2-0/upgrading/4x-1-to-4x-2/) has the full context. For this patch, the two things most likely to need attention are:

1. **Lucee.** The Lucee pin is per app. If you want 7.0.5.41, set `lucee.version` in your app's `lucee.json`; existing apps are not changed for you.
2. **ESAPI-encoded expectations.** If a test asserts exact view-helper output, update the expected character references for Lucee 7.0.5 and later. The rendering is equivalent in a browser.

If you run Adobe CF 2023 update 26 or 2025 update 14, install 4.2.1 and confirm the controller/action names and `/wheels/info` labels look right. If you maintain an app generated by `wheels new`, copy the `.env` parser change from the current `public/Application.cfc` template when convenient.

That's 4.2.1: smaller than 4.2.0, but it fixes the things that were actively getting in the way. If something here still doesn't line up on your engine, file it with the version and a minimal reproduction.
