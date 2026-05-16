---
title: Anatomy of a Wheels Package
slug: anatomy-of-a-wheels-package
publishedAt: '2026-05-22T14:00:00.000Z'
updatedAt: '2026-05-22T14:00:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - packages
  - mixins
  - plugins
categories: []
excerpt: >-
  Wheels 4.0 replaces plugins with a package system that treats your filesystem
  as the registry. This post takes a small package from empty directory to
  installed-and-mixed-in, names every field in the manifest, and is honest
  about the rough edges I hit while writing it.
coverImage: null
---

If you've shipped a Wheels app in the last decade, you've shipped a plugin. Maybe one of the four-or-five common ones — a Stripe wrapper, a search-form helper, a quick-and-dirty admin. Maybe a half-finished one that lived in `plugins/` and never made it to its own repo. The plugin model worked, more or less. It also stopped scaling somewhere around the point where "which file is `currentUser()` actually defined in" became an unanswerable question.

Wheels 4.0 quietly replaces that whole layer. Plugins still load (with a deprecation warning), but the canonical extension surface is now *packages* — and the inversion at the centre of the new design is small enough to miss on a first read: the filesystem is the registry. There is no plugin registration step, no `set(plugins=[...])`, no boot-time enumeration in `config/settings.cfm`. You drop a directory under `vendor/`, the loader finds it, and it activates. To remove a package you delete the directory. That's the entire activation model.

This post is the anatomy: how the loader works, what every field in `package.json` actually does, and why the targeting model — which is the unusual part — makes the rest of the system make sense.

## Filesystem layout is the registry

On startup, Wheels runs `vendor/wheels/PackageLoader.cfc`. It walks `vendor/`, skips itself (`vendor/wheels/`) and any hidden directory, finds every subdirectory that contains a `package.json`, resolves the dependency graph across whatever it found, and loads each package in topological order. Per-package error isolation: any package that throws during manifest parsing, instantiation, or mixin collection gets recorded in `failedPackages` and skipped. The app continues to boot.

A typical install looks like this:

```text
vendor/
  wheels/                # framework core — excluded from discovery
  wheels-hotwire/        # installed package
    package.json
    WheelsHotwire.cfc
  wheels-sentry/         # installed package
    package.json
    WheelsSentry.cfc
    lib/SentryClient.cfc
```

The framework reads `wheels/`'s presence and ignores it. It reads the other two, instantiates each one's entry CFC, collects the public methods declared by their manifests, and hands them to the same mixin pipeline that legacy plugins use. The methods land on controllers (or models, or routes, or wherever the manifest said) and become callable as if you'd defined them in your app.

That's the whole runtime model. Everything else — version constraints, dependency ordering, mappings, service providers — is bookkeeping around that core idea.

## Build one, end to end

Let's build `wheels-greeter`, a deliberately tiny package that adds a `greet(name)` method to every controller. Three files:

```text
vendor/wheels-greeter/
  package.json
  WheelsGreeter.cfc
```

The manifest:

```json title="vendor/wheels-greeter/package.json"
{
    "name": "wheels-greeter",
    "version": "0.1.0",
    "description": "Adds a greet() helper to controllers",
    "wheelsVersion": ">=4.0",
    "provides": {
        "mixins": "controller"
    }
}
```

The entry CFC. The loader's convention is to look for a `.cfc` whose filename matches the directory name (`wheels-greeter.cfc`); if that's missing it falls back to the first `.cfc` in the directory, which is how PascalCase entry filenames like `WheelsGreeter.cfc` work without ceremony:

```cfm title="vendor/wheels-greeter/WheelsGreeter.cfc"
component output="false" {

    public any function init() {
        return this;
    }

    public string function greet(required string name) {
        return "Hello, " & arguments.name & "!";
    }
}
```

Reload the app — `?reload=true&password=...` or `wheels reload` from the CLI — and every controller has a `greet()` method. From a view (because views run inside the controller's `variables` scope):

```cfm title="app/views/pages/home.cfm"
<h1>#greet(params.name ?: "world")#</h1>
```

That's it. No registration, no `set()` call, no `Application.cfc` edit. The loader scanned `vendor/`, found the package, instantiated `WheelsGreeter.cfc`, saw `provides.mixins: "controller"`, collected the public `greet` method, and merged it into the controller mixin table. The next request runs through dispatch, the controller materialises, and the mixed-in method is on it.

If you've authored a Wheels plugin before, the model is intentionally familiar: the same mixin machinery, the same allowlist of targets. What changed is the activation surface — no `plugins/` directory, no `init.cfm`, no naming convention you have to memorise. The manifest carries the metadata explicitly.

## Where it lands: the mixin allowlist

The interesting part of the manifest is `provides.mixins`. It's a comma-delimited list drawn from the framework's allowlist:

```
application, dispatch, controller, mapper, model, base,
sqlserver, mysql, postgresql, h2, test
```

Plus two special values: `global` (inject into all targets) and `none` (opt out entirely). Each name maps to a specific framework component, and a method declared for that target becomes available on instances of that component.

Most packages target `controller`, and that's not laziness — it's a deliberate consequence of how Wheels renders views. Wheels views execute *inside the controller's `variables` scope*, which means a method mixed into the controller is callable from the view too. There is no separate `view` mixin target because there doesn't need to be one. `wheels-basecoat`'s form helpers, `wheels-i18n`'s `t()` and `t.pluralize()`, `wheels-seo-suite`'s `metaTagsFor()` — all of these are controller mixins, and you call them from your `.cfm` templates as if they were view helpers, because at runtime they are.

The `model` target works the same way for `Model` instances — useful when you're shipping behaviour like `wheels-i18n`'s translatable-attribute support, which needs to hook into the model lifecycle. The `mapper` target lets a package add custom routing primitives. The four database adapter targets (`sqlserver`, `mysql`, `postgresql`, `h2`) let a package extend a specific engine's SQL generation. `base` is the lowest-level shared utility class — almost always the wrong choice; reach for it when you need a method available on *every* framework component including ones you weren't thinking about.

`global` is the legacy default. Wheels 3.x plugins implicitly registered every public method on every target unless they fought against it, and that's exactly why "where is `currentUser()` defined?" became a hard question. Packages **default to `none`** — a manifest with no `provides.mixins` field contributes no mixins. You have to declare what you're providing and where you want it. That's the same opt-in posture the rest of the framework moved to in 4.0 ([the rate-limiter post](/posts/skip-the-plugin-rate-limited-api/) got into the same theme from a different angle), and the consequence is the same: there is a finite, named set of methods on a controller, and you can answer the provenance question by reading manifests instead of running grep.

Typos and unsupported targets fail loudly. If you write `"mixins": "controler"` (one `l`), the loader throws `Wheels.PackageInvalidMixinTarget` at load time, names the bad value, and lists the valid set. If you try to use `view` because that's what made sense in your head, same thing — it's not in the allowlist, the package fails, and the log tells you `controller` is the target you wanted.

## Per-method overrides

A package can declare one default in the manifest and then opt individual methods out of it (or into a different target) by annotating the method with a `mixin` metadata attribute. The loader reads the annotation via `GetMetadata()` and overrides the package-level default for that method only.

```cfm title="vendor/wheels-greeter/WheelsGreeter.cfc"
component output="false" {

    public any function init() {
        return this;
    }

    // Follows the manifest default ("controller" — so available in
    // controllers and views, since Wheels views run in the controller's
    // variables scope).
    public string function greet(required string name) {
        return "Hello, " & arguments.name & "!";
    }

    // Overrides to "model" target. Lands on every Model instance instead.
    public string function inspectAttributes() mixin="model" {
        return SerializeJSON(this.properties());
    }

    // Excludes this method from mixin injection entirely. Still callable
    // via application.wheels.PackageLoaderObj.getPackage("wheels-greeter").
    public string function internalOnly() mixin="none" {
        return "not mixed in anywhere";
    }
}
```

The annotation accepts the same allowlist as the manifest, including `global` and `none`. Unknown targets in a method annotation fail the same way as unknown targets in the manifest — the loader validates the whole package's annotations *before* mutating any mixin table, so a typo on method N never leaves methods 1..N-1 partially registered.

## Dependencies, replacements, suggestions

A package can declare three kinds of relationships to other packages, and each maps to a dedicated manifest field:

- **`requires`** — hard dependency. The named package must be present and satisfy the version constraint, or this package fails to load. Dependents see their dependencies' mixins already installed by the time their own `init()` runs.
- **`replaces`** — exclusion. If the named package is present and satisfies the version range, it is *excluded* from loading and this package supplants it. Useful for migration paths — a new package can declare it replaces an older one, and an install of the new one cleanly takes over.
- **`suggests`** — soft dependency. Influences load order (the suggested package, if present, loads first) but doesn't cause this package to fail if the suggested package isn't installed.

```json title="vendor/wheels-greeter-pro/package.json"
{
    "name": "wheels-greeter-pro",
    "version": "1.0.0",
    "wheelsVersion": ">=4.0",
    "requires": {
        "wheels-i18n": ">=0.2.0"
    },
    "replaces": {
        "wheels-greeter": "*"
    },
    "suggests": {
        "wheels-sentry": "*"
    },
    "provides": {
        "mixins": "controller"
    }
}
```

The version syntax is semver — `>=`, `<`, `^`, `~`, ranges, exact pins. A literal `*` means "any version." The loader runs everything through `wheels.SemVer.satisfiesAll()`, the same matcher used for `wheelsVersion`. If a required package is missing, the dependent is recorded in `failedPackages` with a clear "Required package not found" entry and the rest of the graph loads around it. Circular dependencies — a requires b, b requires a — surface as a graph error at resolution time; every package in the cycle is excluded and named in the log.

(One drift point I'll come back to in the closing section: the public `Packages` guide and `CLAUDE.md` both used to call this field `dependencies`, matching the legacy plugin shape. The loader has always read `requires`. Both docs are now consistent with the code.)

## The mapping alias

Wheels package directory names can contain hyphens — `wheels-sentry`, `wheels-i18n`, `wheels-greeter`. CFML identifiers cannot. That mismatch is why every package gets a CFML-identifier-safe alias registered at load time. Without it, code inside `wheels-sentry/lib/Client.cfc` would have to address its sibling as `CreateObject("component", "vendor.wheels-sentry.SentryClient")` because `new vendor.wheels-sentry.SentryClient()` is a parse error — the parser sees subtraction.

The loader computes the alias as the lower-camel-case form of the package `name`:

| `name`                  | Alias                |
|-------------------------|----------------------|
| `wheels-sentry`         | `wheelsSentry`       |
| `wheels-i18n`           | `wheelsI18n`         |
| `wheels-legacy-adapter` | `wheelsLegacyAdapter`|
| `myfeature`             | `myfeature`          |

(Single-segment names get lowercased rather than preserved — the first segment is always passed through `LCase()`, so a `name` of `myFeature` yields `myfeature`, not `myFeature`. Set `mapping` explicitly if the case matters.)

A package can override the auto-derivation by setting `mapping` explicitly in the manifest — useful when the camelCase form clashes with something else in your app or when the derivation produces a name you don't like. The override must match the CFML identifier regex `[A-Za-z_][A-Za-z0-9_]*`; an invalid value or an empty string fails the package at load time. When two packages compute (or declare) the same alias, the first-loaded one keeps its alias and the second is recorded in `failedPackages` with a `Duplicate package mapping alias` error that names both claimants. The second package's mixins, service providers, and middleware are all rolled back — never partially applied — and you fix it by setting a unique `mapping` in the second package's manifest.

Inside a package, code uses the alias like a static CFML mapping:

```cfm title="vendor/wheels-sentry/WheelsSentry.cfc"
component output="false" {
    public any function init() {
        variables.client = new wheelsSentry.lib.SentryClient();
        return this;
    }
}
```

That `new wheelsSentry.lib.SentryClient()` works because the alias is registered as a CFML mapping (`/wheelsSentry` → `vendor/wheels-sentry/`). From outside the package, the same path resolves identically. You can inspect every registered alias via `application.wheels.PackageLoaderObj.getPackageMappings()`.

## When you need a lifecycle: service providers

Some packages need more than mixins. They register services with the DI container, wire event listeners, set up scheduled jobs, or do startup work that depends on other packages already being loaded. For those, the package implements `wheels.ServiceProviderInterface` — a two-method contract:

```cfm title="vendor/wheels-greeter/WheelsGreeter.cfc"
component implements="wheels.ServiceProviderInterface" output="false" {

    public any function init() {
        return this;
    }

    // Phase 1: bind services. Runs after every package has been
    // instantiated, before any boot() hook.
    public void function register(required any container) {
        arguments.container
            .map("greetingService")
            .to("wheelsGreeter.lib.GreetingService")
            .asSingleton();
    }

    // Phase 2: cross-package wiring. Every register() has completed
    // by the time boot() runs, so resolving services here is safe.
    public void function boot(required struct app) {
        // Hook listeners, configure environments, etc.
    }

    // Normal mixin method, still follows provides.mixins.
    public string function greet(required string name) {
        return service("greetingService").greet(arguments.name);
    }
}
```

`register` and `boot` are infrastructure hooks — the loader recognises them and excludes them from mixin collection along with `init`, `onPluginLoad`, and `onPluginActivate`. The two-phase split exists because cross-package wiring is brittle if every provider does both binding and resolution in the same hook: package A's `register` can't safely depend on package B's services being registered yet. Splitting it lets every `register` run before any `boot` does, so by the time you're in `boot` every service the framework will know about is already bound.

The DI container itself is covered in the dependency-injection guide; the only thing worth saying here is that service-providing packages compose cleanly with mixin-providing ones. A package can do both, neither, or some of each, and the framework treats them as orthogonal concerns.

## Error isolation

Every package loads inside its own try/catch. The promise is straightforward: activating a broken package cannot take down a working app.

The failure modes the loader specifically handles:

- **Malformed `package.json`** — logged, package skipped, `failedPackages` entry created.
- **Missing required manifest fields** — same.
- **Incompatible `wheelsVersion`** — package is excluded from the load order before any CFC is instantiated. The log entry names the constraint and the running version.
- **Required package missing** — dependent is excluded, with a "Required package not found" entry. The independent half of the graph loads normally.
- **Circular dependencies** — every package in the cycle is excluded with a clear graph-error log entry.
- **Duplicate mapping alias** — the second claimant is rolled back; its mixins, service providers, and middleware are all unregistered cleanly.
- **Exception during `init()`** — caught, logged with stack, package skipped. Mixins are never partially applied.

After a deploy, the application log records — for each package — either "Package 'X' v1.2.3 loaded (controller mixins)" or "Package 'X' skipped: ...". That log is the source of truth for what activated. Two related getters help you inspect the same state at runtime: `application.wheels.PackageLoaderObj.getFailedPackages()` returns the failures, and `getMixinCollisions()` returns the cross-package method overwrites — same method registered on the same target by two different packages — even when the overwrite was acknowledged via `provides.overrides`. (Overrides suppress the warning log but still record the collision so you can see what's happening.)

## Distribution: the registry and CLI

Most of the time, you'll install packages via the CLI rather than copying directories. The install commands resolve names against the `wheels-dev/wheels-packages` registry, verify the tarball's sha256 against the manifest entry, and extract into `vendor/<name>/`:

```bash title="your shell"
wheels packages list                      # browse the registry
wheels packages search hotwire            # match name/description/tags
wheels packages show wheels-sentry        # detail page + versions
wheels packages add wheels-sentry         # install latest compat version
wheels packages add wheels-sentry@1.2.0   # pin a specific version
wheels packages update wheels-sentry --yes
wheels packages update --all --yes
wheels packages remove wheels-sentry
wheels packages registry refresh          # bust the 24h cache
wheels packages registry info             # cache state + registry URL
```

The verb is `add`, not `install` — LuCLI (the runtime under the `wheels` brand) registers `install` for its own extension installer, which intercepts the token before it reaches the Wheels package handler. Same shape as why `wheels browser install` got renamed to `wheels browser setup` during 4.0 development. `add` is the canonical verb across the CLI and the docs.

The default registry is `wheels-dev/wheels-packages`; override with `WHEELS_PACKAGES_REGISTRY=<org>/<repo>` if you're running an internal mirror. The full publishing flow — fork the registry, open a PR, the mirror workflow builds a deterministic tarball and computes sha256 — is documented in the `wheels-dev/wheels-packages` repo's `CONTRIBUTING.md`. It's deliberately friction-light: anyone can submit, the registry is curated rather than gatekept.

## What changed while writing this post

Two things drifted between the docs and the code while I was drafting, and both got fixed in the same week the article landed.

The first was the dependency field name. Both the public `Packages` guide and `CLAUDE.md` documented the manifest field as `dependencies`, in three separate places. The loader has always read `requires`. The drift came from the legacy-plugin shape: 3.x plugins declared `"dependencies": {...}` in `box.json`, and when the new system was designed the manifest field was renamed to `requires` so dependents and replacements and suggestions could share a consistent vocabulary. The example manifests in the docs never got updated. Anyone copying the example would have ended up with a package that loaded but ignored its declared dependency entirely — no error, no warning, just silent breakage if the dependency happened to be missing. Both docs are now corrected to use `requires`, and the example manifests round out with `replaces` and `suggests` so the full graph syntax is in one place.

The second was the `wheelsVersion` constraint. The guide described mismatches as "logged" — accurate but soft. The actual behaviour is a hard skip: an incompatible package is excluded from the load order before its CFC is ever instantiated, recorded in `failedPackages`, and the log entry names both the constraint and the running version. "Logged" undersells the consequence; if your package requires `>=4.0` and you deploy it onto a 3.x app, it does not partial-load, it doesn't degrade gracefully, it simply isn't there. The guide now says so, in those words. Knowing the difference matters when you're debugging "why isn't my mixin showing up after I installed the package" — the answer is sometimes "you didn't install it; the version gate refused it" and the framework will tell you that, but only if you know the gate exists.

Neither of these is a code change — both are documentation fixes — but they're the kind of drift that costs an hour the first time you hit it, and they're the reason a piece like this is worth writing. Anything you have to write down to be sure of is something the next person was going to have to figure out from scratch.

The next post in the series — *Wheels + Claude: building a feature via the stdio MCP* — picks up the same theme on a different surface: what the framework's tools look like when the consumer is a model rather than a developer. Coming next week.
