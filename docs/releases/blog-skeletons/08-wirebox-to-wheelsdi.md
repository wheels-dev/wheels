---
status: skeleton
slot: post 8 (week 3–4; contributor / framework-internals audience)
target_length: 1000–1300 words
---

# From WireBox to wheelsdi — The Framework Gets Leaner

**Subhead / dek:** *An internal modernization that nobody asked for, that changed how Wheels feels to extend and to ship.*

**Target audience:**
- Contributors who've tried to debug Wheels' boot sequence
- CFML devs who know WireBox/TestBox/CommandBox and want the story behind Wheels stepping off that stack
- Framework authors curious about decomposition strategies
- Tech leads who have to justify "we're not using the standard CFML DI container" in a review

**Lead paragraph intent:**
- Most of 4.0 is about what users do. This post is about what *we* changed under the hood — why `application.wirebox` became `application.wheelsdi`, why TestBox was replaced with WheelsTest, why the init sequence was decomposed.
- None of this is user-visible. All of it is how future features are going to land faster and with less ceremony.
- This is the "rim modernization" story.

## Sections

### 1. "The accidental coupling problem"
- Over a decade, CFWheels (and later Wheels) accreted hard dependencies on Ortus infrastructure — WireBox for DI, TestBox for testing, CommandBox for CLI.
- Each dependency was a reasonable choice in its moment. Collectively, they constrained velocity: upgrading Lucee or Adobe CF meant first confirming WireBox, TestBox, and CommandBox all worked in the new environment.
- The release pace Wheels 4.0 needed (185 PRs in 14 weeks) was not compatible with that coupling.

### 2. What "rim modernization" means
- The "rim" — the outer layer where Wheels meets the CFML engine — got decomposed into engine-specific adapter modules ([#2016](https://github.com/wheels-dev/wheels/pull/2016)).
- Adapter modules isolate: struct member function idioms (Lucee vs Adobe CF), scope handling (Adobe CF's different `application` scope semantics), closure semantics, CFML version quirks.
- Downstream: tests exercise the engine-neutral core against each adapter, not the core against the engine directly.

### 3. WireBox → wheelsdi (#1883, #1888)
- `application.wirebox` renamed to `application.wheelsdi` ([#1888](https://github.com/wheels-dev/wheels/pull/1888)).
- Same surface — `map()`, `bind()`, resolution behavior — but the implementation is in-house and smaller.
- Explicit scopes: transient (default), singleton, request-scoped.
- Expanded DI features landed on this base: request-scoped services, `service()` global helper, declarative `inject()` in controller `config()`, interface binding, auto-wiring of `init()` arguments ([#1933](https://github.com/wheels-dev/wheels/pull/1933)).
- Why in-house: DI container behavior is central to how Wheels extends; keeping it in-tree means fixes ship with the framework, not on a third-party release cadence.

### 4. TestBox → WheelsTest
- WheelsTest is a BDD test runner that lives inside the framework ([#1889](https://github.com/wheels-dev/wheels/pull/1889)).
- Provides `describe()`, `it()`, `expect()` — idiomatic BDD.
- Compatible with the test infrastructure pattern that Wheels specs were already using under TestBox.
- RocketUnit legacy specs continue to work ([#1925](https://github.com/wheels-dev/wheels/pull/1925)).

### 5. Decomposed init
- Historically, Wheels' `onApplicationStart` was a monolithic sequence: engine detection → DI wiring → model/controller loading → route compilation → plugin loading → environment setup.
- 4.0 decomposed this into discrete phases, each testable in isolation.
- Package loading became a phase with per-package error isolation ([#1995](https://github.com/wheels-dev/wheels/pull/1995)) — a broken package logs and skips, the app continues.

### 6. The package system — philosophical shift from plugins
- Legacy `plugins/` folder worked via mixin merging into global scope by default.
- New `packages/` (staging) → `vendor/` (activation) model requires *explicit opt-in* for what the package mixes into (`controller`, `view`, `model`, `global`, `none`). Default `none`.
- Dependency graph via topological sort; `requires` / `replaces` / `suggests` ([#2017](https://github.com/wheels-dev/wheels/pull/2017)).
- Per-package error isolation — the kind of operational posture that makes enabling third-party code a lower-risk decision.

### 7. CommandBox → LuCLI direction (brief; tease post #5)
- CLI story parallels the DI and testing stories: dependency → in-house alternative that's cheaper to evolve.
- Not a CommandBox rejection — CommandBox continues to work. LuCLI is the fast path for the inner loop and CI.

### 8. What this means for contributors
- **Shorter boot time during dev** — decomposed init + package lazy-loading = less startup friction.
- **Smaller surface to learn** — wheelsdi's API is narrower than WireBox's; new contributors don't need to read Ortus docs to wire a service.
- **Testing that explains itself** — BDD specs read like documentation; RocketUnit specs mostly don't.

### 9. What this doesn't mean
- Not a rejection of Ortus tooling. CommandBox, WireBox, TestBox remain excellent products; many Wheels users will keep using them in their own apps.
- Not a "silver bullet." The decomposition shipped with its own set of cross-engine gotchas that had to be solved ([#2028](https://github.com/wheels-dev/wheels/pull/2028), [#2030](https://github.com/wheels-dev/wheels/pull/2030), [#2031](https://github.com/wheels-dev/wheels/pull/2031)).

## Code / config snippets to include (pick 2)

```cfm
// config/services.cfm — in-house DI, same familiar surface
var di = injector();
di.map("emailService").to("app.lib.EmailService").asSingleton();
di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
```

```cfm
// Declarative injection in a controller — ergonomics of the new DI
component extends="Controller" {
    function config() {
        inject("emailService, currentUser");
    }

    function create() {
        this.emailService.send(
            to=this.currentUser.email(),
            subject="Welcome"
        );
    }
}
```

## Suggested visuals

- **Dependency diagram:** two stacks. Left: "Wheels 3.0" with WireBox, TestBox, CommandBox boxes wrapped around the core. Right: "Wheels 4.0" with wheelsdi, WheelsTest, LuCLI as *part of* the core. Visual distinction: the 4.0 diagram has fewer external boxes.
- **Init timeline (optional):** horizontal phases of the decomposed init sequence — engine detect / DI / models / controllers / routes / packages / environment. Caption: "each phase is testable in isolation."

## Outro / CTA

- "The most important 4.0 feature is the one nobody feels directly — the one that lets future features ship faster."
- Link to the package system docs.
- Point to the contributing guide and invite DI container / adapter module contributions.

## Citations (must link in final post)

- [Rim modernization PR #1883](https://github.com/wheels-dev/wheels/pull/1883)
- [WireBox → wheelsdi PR #1888](https://github.com/wheels-dev/wheels/pull/1888)
- [Expanded DI PR #1933](https://github.com/wheels-dev/wheels/pull/1933)
- [WheelsTest namespace PR #1889](https://github.com/wheels-dev/wheels/pull/1889)
- [Package system PR #1995](https://github.com/wheels-dev/wheels/pull/1995)
- [Module system + dependency graph PR #2017](https://github.com/wheels-dev/wheels/pull/2017)
- [Engine adapter modules PR #2016](https://github.com/wheels-dev/wheels/pull/2016)
- [Feature audit § Internal refactors](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md#20-internal-refactors--infrastructure)
