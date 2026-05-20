# Social Posts — "Anatomy of a Wheels Package"

**Status:** Copy-paste ready. Second post in the post-GA series after the rate-limiter article.
**Pairs with:** [docs/releases/blog-drafts/anatomy-of-a-wheels-package.md](../blog-drafts/anatomy-of-a-wheels-package.md)
**Post date:** 2026-05-17 (same day as the article)
**Tone:** Post-GA, present tense, how-to angle. Picks up the "now go build with it" thread from the rate-limiter post and applies it to the framework's other inversion: plugins → packages.

**Canonical URL** (use everywhere):
- `https://blog.wheels.dev/posts/anatomy-of-a-wheels-package`

---

## Slack (#wheels-dev)

```
New on the blog: Anatomy of a Wheels Package — authoring, mixins, the registry.

<https://blog.wheels.dev/posts/anatomy-of-a-wheels-package|Full post>

What it covers:
• The filesystem-as-registry inversion — drop a directory under vendor/, it activates. No registration step, no set(plugins=[...]).
• The package.json manifest, field by field — and the explicit-opt-in default for provides.mixins (`none`, not `global` like 3.x plugins)
• Why `controller` is the everyday mixin target — Wheels views run in the controller's variables scope, so a controller mixin is also a view helper
• The requires / replaces / suggests dependency graph, topological load order, circular-dep handling
• The mapping alias — how `wheels-sentry` becomes `wheelsSentry` so siblings can use `new wheelsSentry.SentryClient()` instead of the verbose vendor-path form
• ServiceProviderInterface — when you need register/boot hooks instead of (or alongside) mixins
• Error isolation — one bad package can never take down the app

Side effect of writing the post: two doc-drift fixes (#2734) — both the public Packages guide and CLAUDE.md were documenting the inter-package dependency field as `dependencies` (the legacy 3.x plugin shape). The loader has always read `requires`. Anyone copying the example would have shipped a package whose declared dependencies were silently ignored. Same PR also tightens the guide's wheelsVersion description — incompatible packages are hard-skipped, not just "logged."
```

---

## LinkedIn

```
New on the Wheels blog: Anatomy of a Wheels Package — authoring, mixins, the registry.

For most of Wheels' history, extending the framework meant writing a plugin. Maybe one of the well-known ones — a Stripe wrapper, an admin scaffold, a search-form helper. Maybe a half-finished one that lived in plugins/ and never made it to its own repo. The plugin model worked, more or less. It also stopped scaling around the point where "which file is currentUser() actually defined in" became an unanswerable question.

Wheels 4.0 quietly replaces that whole layer. Plugins still load (with a deprecation warning), but the canonical extension surface is now packages — and the inversion at the centre of the new design is small enough to miss on a first read: the filesystem is the registry. There is no plugin registration step, no set(plugins=[...]), no boot-time enumeration in config/settings.cfm. You drop a directory under vendor/, the loader finds it, and it activates. To remove a package, you delete the directory. That is the entire activation model.

The post walks an end-to-end wheels-greeter example and names every field in package.json. Topics covered:

— The manifest's provides.mixins allowlist (application, dispatch, controller, mapper, model, base, the four DB adapters, test) and why default is "none" instead of "global" — the same opt-in posture the rest of the framework moved to in 4.0.
— Why controller is the everyday answer: Wheels views execute inside the controller's variables scope, so a controller mixin is also a view helper. No separate "view" target exists because there does not need to be one.
— Per-method mixin overrides via metadata annotation — annotate a single method with mixin="model" or mixin="none" to opt it out of the package default.
— The requires / replaces / suggests dependency graph — hard, exclusion, soft, in that order — and topological load order so dependents see their dependencies already installed.
— The mapping alias system — how wheels-sentry becomes wheelsSentry so a sibling CFC can do new wheelsSentry.SentryClient() instead of the verbose CreateObject string form (hyphens aren't valid CFML identifiers, which is why this exists).
— ServiceProviderInterface for packages that need a register/boot lifecycle to bind services with the DI container or do cross-package wiring.
— Error isolation — every package loads in its own try/catch, so a broken package gets recorded in failedPackages and the app continues booting.

A side note in the post: writing it surfaced two documentation-drift bugs. Both the public Packages guide and CLAUDE.md were calling the manifest's dependency field "dependencies" — the shape inherited from 3.x plugins. The modern PackageLoader has always read "requires" (plus "replaces" and "suggests" for replacements and soft edges). Anyone copying the example would have shipped a package whose declared dependencies were silently ignored — no error, no warning, just broken at the first missing dep. Same PR also tightens the guide's wheelsVersion description: not just "logged" but a hard skip. An incompatible package is excluded from the load order before its CFC is instantiated.

Read: https://blog.wheels.dev/posts/anatomy-of-a-wheels-package

#CFML #Wheels #Packages #Plugins #FrameworkDesign #WebDevelopment
```

---

## X / Twitter

**Hero tweet (unnumbered):**
```
New on the Wheels blog — Anatomy of a Wheels Package.

The filesystem is the registry. Drop a directory under vendor/, the loader finds it, it activates. No registration step, no set(plugins=[...]).

https://blog.wheels.dev/posts/anatomy-of-a-wheels-package
```

**Reply 1:**
```
1/ Three things changed when packages replaced plugins:

• Activation is "directory exists" — no Application.cfc edit
• Mixin default is `none`, not `global` — opt-in surface area
• Dependencies are explicit (requires / replaces / suggests) with topological load order

The first one is the inversion. The other two follow from it.
```

**Reply 2:** (outer fence is `~~~~` so the inner ```` ```json ```` block renders correctly in the Markdown preview)

~~~~
2/ The whole manifest for a controller-mixin package:

```json
{
    "name": "wheels-greeter",
    "version": "0.1.0",
    "wheelsVersion": ">=4.0",
    "provides": { "mixins": "controller" }
}
```

Drop the dir + the entry CFC in vendor/, reload, every controller has your methods.
~~~~

**Reply 3:**
```
3/ Why `controller` is the everyday mixin target:

Wheels views execute inside the controller's variables scope. A method mixed into the controller is also callable from the view. There is no separate "view" target because there does not need to be one.

wheels-basecoat, wheels-i18n, wheels-seo-suite — all controller mixins.
```

**Reply 4:**
```
4/ Side effect of writing the post: two doc-drift fixes (#2734).

The guide + CLAUDE.md called the manifest dependency field "dependencies" (3.x plugin shape). The loader has always read "requires." Anyone copying the example shipped a package whose deps were silently ignored.

Both docs now match the code.
```

---

## GitHub Discussions

**Title:** `Post-GA blog: Anatomy of a Wheels Package`

```markdown
Second in the post-GA series. The rate-limiter post took the middleware pipeline — this one takes the other big 4.0 inversion: plugins → packages. Specifically, what happens when "extension point" stops being a registration step and starts being a directory on disk.

**Read:** https://blog.wheels.dev/posts/anatomy-of-a-wheels-package

The post is an end-to-end tour of the package system, from a worked `wheels-greeter` example through to publication on the `wheels-dev/wheels-packages` registry. It walks through:

- **The activation model** — filesystem-as-registry. `PackageLoader.cfc` scans `vendor/*` on boot, skips itself and hidden dirs, resolves a dependency graph, loads in topological order. To install you drop a directory; to remove you delete one. No `set(plugins=[...])` call survives.
- **The mixin allowlist** — `application`, `dispatch`, `controller`, `mapper`, `model`, `base`, four DB adapters, `test`, plus the special `global` (legacy default) and `none` (modern default). Why `controller` is the everyday answer: Wheels views execute inside the controller's `variables` scope, so a controller mixin is callable from views and partials too. There is no `view` target because there doesn't need to be one.
- **Per-method overrides** — `mixin="model"` or `mixin="none"` as a metadata annotation on a single method overrides the package-level default. The loader validates the whole package's annotations before mutating any mixin table, so a typo on method N never leaves methods 1..N-1 partially registered.
- **The `requires` / `replaces` / `suggests` graph** — hard deps fail the package if missing; `replaces` excludes a named package (migration paths); `suggests` is a soft edge that influences load order without failing on absence.
- **The mapping alias** — `wheels-sentry` → `wheelsSentry`. Hyphens aren't valid CFML identifiers, so the loader auto-derives a lower-camel-case alias and registers it as an `application.mappings` entry. Sibling CFCs can do `new wheelsSentry.SentryClient()` instead of the verbose `CreateObject("component", "vendor.wheels-sentry.SentryClient")`.
- **ServiceProviderInterface** — the optional two-phase `register(container)` / `boot(app)` lifecycle for packages that need to bind services or do cross-package wiring. Split because resolution-during-registration is brittle when other providers haven't registered yet.
- **Error isolation** — every package loads in its own try/catch. A broken package is recorded in `failedPackages` and the app continues booting. No partial application of mixins.

## Side note: two doc-drift bugs surfaced while writing this

Drafting the post turned up two real doc/code mismatches in the package reference, both fixed in the same PR ([#2734](https://github.com/wheels-dev/wheels/pull/2734)).

- The public `Packages` guide and `CLAUDE.md` documented the inter-package dependency field as `dependencies` — three places, all wrong. The shape is inherited from the legacy 3.x plugin manifest (`box.json`'s `dependencies` struct). The modern `PackageLoader` has always read `requires`, plus `replaces` and `suggests` for replacements and soft edges. Anyone copying the example manifest would have shipped a package that loaded cleanly but silently ignored its declared dependencies — no error, no warning, just broken the first time something tried to use the absent dep. All three docs are now corrected to use `requires`, and the example manifests round out with `replaces` and `suggests` so the full graph syntax lives in one place.
- The same guide described `wheelsVersion` mismatches as "logged" — accurate but soft. The actual behaviour is a hard skip: an incompatible package is excluded from the load order before its CFC is ever instantiated, recorded in `failedPackages`, and the log entry names both the constraint and the running version. "Logged" undersells the consequence; if your package requires `>=4.0` and you deploy it onto a 3.x app, it does not partial-load, it doesn't degrade gracefully, it simply isn't there. The guide now says so.

Neither was a code change — both are doc fixes — but they're the kind of drift that costs an hour the first time you hit it. The article closes with the "what changed while writing this" section so the rationale doesn't get lost.

## What's next in the post-GA series

The remaining three titles from the second batch:

1. *Wheels + Claude* — building a feature via the stdio MCP
2. *Beyond findAll* — scopes, enums, the chainable query builder
3. *From Empty Directory to Deployed SaaS* — end-to-end with generators, multi-tenancy, jobs, browser tests, `wheels deploy`

Feedback on the packages post — what's confusing, what's missing, what you'd want a future post to cover — welcome in this thread. The author-facing reference guide lives at https://guides.wheels.dev/v4-0-1-snapshot/digging-deeper/packages/ if you want the full field-by-field treatment.
```

---

## Posting checklist

- [ ] Article live at `https://blog.wheels.dev/posts/anatomy-of-a-wheels-package`
- [ ] PR #2734 merged (article + doc fixes for `dependencies` → `requires` and `wheelsVersion` clarification)
- [ ] Slack post in `#wheels-dev`
- [ ] LinkedIn post from the Wheels org account
- [ ] X / Twitter hero + 4-reply thread from `@wheels_dev`
- [ ] GitHub Discussions thread under "Show and tell" or equivalent category
- [ ] Verify all four channels link to the same canonical URL
