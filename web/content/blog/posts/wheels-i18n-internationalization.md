---
title: 'Internationalization in an Afternoon: wheels-i18n'
slug: wheels-i18n-internationalization
publishedAt: '2026-07-24T14:00:00.000Z'
updatedAt: '2026-07-06T05:23:50.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - i18n
  - packages
  - views
categories: []
excerpt: >-
  i18n usually arrives as an emergency. wheels-i18n makes the mechanical part
  boring: t() and tp() with interpolation and pluralization, JSON or database
  catalogs, session-based locale switching, and the fallback chain that makes
  incremental translation actually shippable.
coverImage: null
---

Internationalization has a way of arriving as an emergency. The app was English-only for three years, then sales lands a customer in Guadalajara, and suddenly every hardcoded string in every view is a line item. The teams that survive this gracefully are the ones whose framework makes the mechanical part — externalize, key, look up, fall back — boring.

For Wheels 4 that's `wheels-i18n`: a first-party package, zero dependencies, JSON-file or database-backed, with interpolation, pluralization, session-based locale switching, and fallback handling. It's small enough to read in a sitting and complete enough to ship with. Here's the whole thing.

## Install and configure

```bash
wheels packages add wheels-i18n
wheels reload
```

(No wheels CLI? Same as any package: extract the release into `vendor/wheels-i18n/` and reload — the loader auto-discovers it.)

Configuration is six settings in `config/settings.cfm`, all with sensible defaults:

```cfm
set(i18n_defaultLocale = "en");        // locale when the session hasn't picked one
set(i18n_availableLocales = "en,es");  // what changeLocale() will accept
set(i18n_fallbackLocale = "en");       // where missing keys go looking
set(i18n_translationSource = "json");  // "json" or "database"
set(i18n_translationsPath = "/app/locales");
set(i18n_cacheTranslations = false);   // flip to true in production
```

That last one matters more than it looks: `i18n_cacheTranslations=true` holds translations in memory instead of re-reading files, and it's the difference between i18n being free and i18n being a per-request file-IO tax. Set it `true` in `config/production/settings.cfm` and leave it `false` in development so edits show up live — exactly the [per-environment override pattern](https://blog.wheels.dev/posts/how-wheels-reads-configuration) the config system is built for.

## The translation files

JSON files, one directory per locale, one file per namespace:

```
/app/locales
  /en
    common.json
    forms.json
  /es
    common.json
    forms.json
```

```json
// app/locales/en/common.json
{
  "welcome": "Welcome to my app!",
  "greeting": "Hello, {name}!",
  "posts": {
    "zero": "No Post Found",
    "one": "{count} Post Found",
    "other": "{count} Posts Found"
  },
  "nav": {
    "home": "Home",
    "contact": "Contact"
  }
}
```

The filename is the key's first segment — `common.welcome`, `forms.save` — and nesting inside the file extends the path: `common.nav.home`. That two-level convention (namespace file, nested keys) is the thing that keeps a translation catalog navigable at 500 keys instead of becoming one giant undifferentiated JSON swamp. Split by feature area early; future-you is grateful.

## Using it: `t()` and `tp()`

The package mixes into controllers — which in Wheels means views too, since views execute in the controller's variable scope. Two functions carry the whole API:

```cfm
<!--- simple lookup --->
<h1>#t("common.welcome")#</h1>

<!--- interpolation: named arguments fill {placeholders} --->
<p>#t("common.greeting", name=user.firstName)#</p>

<!--- pluralization: tp() picks .zero / .one / .other by count --->
<span>#tp("common.posts", count=posts.recordCount)#</span>
```

`tp()` is the one that saves you from the `if (count == 1)` ternaries that infest view code — declare the three forms in the catalog (`zero`, `one`, `other`, with `{count}` available for interpolation) and the call site stays a single expression regardless of grammar.

Locale management is three more functions: `currentLocale()`, `availableLocales()`, and `changeLocale("es")` — which validates against your `i18n_availableLocales` list and stores the choice in the session. A locale switcher is a tiny controller action:

```cfm
function setLocale() {
    changeLocale(params.locale ?: "");
    redirectTo(back=true);
}
```

Because the choice is session-based, it follows the user across requests without touching your URLs — no `/es/` route prefixes to thread through every link helper.

## Fallback: the graceful-degradation contract

The lookup chain is: current locale → `i18n_fallbackLocale` → the key handling for genuinely-missing entries. This is the property that makes *incremental* translation shippable — the day you add Spanish, you don't need 100% catalog coverage before deploying; untranslated keys render the fallback-locale text instead of holes. Translate the high-traffic namespaces first, ship, iterate. The alternative frameworks teach — all-or-nothing catalog completeness — is why i18n projects stall.

The database source (`i18n_translationSource="database"`) swaps JSON files for table-backed translations — same API, same fallback — for teams whose translators work through an admin UI rather than pull requests. Starting with JSON and moving to database later is a config change, not a rewrite.

## Migrating from the 3.x plugin

If you ran the old i18n plugin on Wheels 3: the 4.0 package is its successor, and the migration is deliberately dull — delete the old `plugins/i18n/` directory, install the package, done. Your existing `i18n_*` settings and `app/locales/*.json` files work unchanged. (This package is also a nice specimen of the [plugins-to-packages](https://guides.wheels.dev/v4-0-0/digging-deeper/packages/) story generally: same code circa 3.x, now living in `vendor/`, auto-discovered from its `package.json`, isolated if it errors.)

## The honest boundaries

`wheels-i18n` does keys, interpolation, plurals, locales, and fallback — the 90% that makes multilingual UI mechanical. What it doesn't do: date/number/currency *formatting* (use CFML's built-in `LSDateTimeFormat`/`LSNumberFormat` family, which is what they're for), right-to-left layout (that's CSS), and translation *workflow* (who translates what, when — a people process no package fixes). Scope it accordingly: this is the string layer, done right, in a package small enough to audit over coffee.

Full details and the database-source schema are in the [package README](https://github.com/wheels-dev/wheels-i18n); the surrounding pattern — building the same thing by hand, and when you'd want to — is the [Internationalization guide](https://guides.wheels.dev/v4-0-0/digging-deeper/internationalization/).

