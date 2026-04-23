---
title: 'LuCLI and the Zero-Docker Developer Experience'
slug: lucli-zero-docker-developer-experience
publishedAt: '2026-05-07T07:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - lucli
  - developer-experience
categories: []
excerpt: >-
  Wheels 4.0 ships with a new inner-loop story: a single native binary, a
  sixty-second full test run, and a multi-phase migration that quietly moved
  the framework off Docker for day-to-day development. This post walks through
  how we got here, what LuCLI is, and why cross-engine matrix testing still
  belongs in Docker.
coverImage: null
---

# LuCLI and the Zero-Docker Developer Experience

_Peter Amiri, Wheels Core Team_

---

If you last cloned Wheels in the 3.x era and gave up halfway through setting up the Docker dev stack, this is the post for you. Between 3.0.0 and the 4.0 snapshot we merged more than 260 pull requests over roughly fifteen weeks. Plenty of that was features — the Kamal port, the package system, browser testing, middleware, auto-migrations. But the change that has quietly reshaped how Wheels is built every day is not a feature. It is the end of Docker as the default inner-loop tool.

You can now clone the repo, run two commands, and have the core test suite complete in about sixty seconds. No Docker Desktop. No container warm-up. The command your CI runs is the command you run locally, and the feedback loop is short enough that you will actually use it.

## Why Docker was the wrong default for the inner loop

Docker is still the right tool for Wheels' cross-engine compatibility matrix. The framework supports Lucee 5, 6, 7, Adobe ColdFusion 2018, 2021, 2023, 2025, plus BoxLang, across seven databases. No laptop can natively host that matrix. Docker Compose is the correct answer, and we still run it in CI, nightly, and on demand when you are chasing an Adobe CF quirk.

Docker was never the correct answer for the inner loop. The inner loop is what you do when you are writing a test, watching it fail, fixing it, and watching it pass. If that cycle takes ninety seconds, you do not run it. You push to CI, wait ten minutes, and context-switch four times while you wait. Multiply that by a contributor's first day on the project and you have explained why CFML frameworks have a contribution-curve problem.

The recent CFML landscape shifted enough to let us fix this. Lucee 7 matured to the point of being a reliable reference engine. [LuCLI](https://github.com/bpamiri/LuCLI) matured from an experiment into a production-quality single binary. Together they gave us a pure-Java, zero-Docker inner loop that still compiles the same CFML code CI runs.

## What LuCLI is

LuCLI is a single native binary — `lucli` — that runs Lucee directly without CommandBox or any Ortus orchestration layers. It starts a CFML server, runs a script, or drops you into a REPL. Homebrew-installable on macOS; direct-download tarballs for Linux and Windows.

The closest analogy is Node.js for CFML: a single binary, fast startup, scriptable, no assumptions about package managers or server containers before you can run a `.cfm` file.

Wheels does not require you to know any of that. The framework's test harness, generators, migration runner, seeder, job worker, and deploy tooling all invoke LuCLI under the hood. You see `wheels test run` or `bash tools/test-local.sh`. What runs is a LuCLI server, a SQLite database file, and the core test suite executing in-process.

## The migration arc

None of this happened in a single pull request. It is a multi-phase arc that started before 4.0 and finished during the 4.0 development window.

Phase 1, pre-4.0, was LuCLI itself maturing to production readiness. That work lives in [bpamiri/LuCLI](https://github.com/bpamiri/LuCLI), separate from the Wheels repo, but every Wheels release since 3.1 has leaned harder on it.

Phase 2 was the first time contributors could run tests without Docker. [#2063](https://github.com/wheels-dev/wheels/pull/2063) shipped `tools/test-local.sh`. [#1941](https://github.com/wheels-dev/wheels/pull/1941) added the service layer and MCP annotations that let generators and the migration runner be called as library functions rather than shelled-out CLI processes.

The critical inflection was [#2032](https://github.com/wheels-dev/wheels/pull/2032): LuCLI-native CI. Every pull request now runs Lucee 7 + SQLite through LuCLI as its required check, before the Docker compatibility matrix fans out. Green locally means green in CI.

Phases 3 and 4 — [#2065](https://github.com/wheels-dev/wheels/pull/2065), [#2092](https://github.com/wheels-dev/wheels/pull/2092), [#2018](https://github.com/wheels-dev/wheels/pull/2018) — moved scaffold, seed, and the Tier 1 command set to in-process service invocation, and handled distribution so the right LuCLI binary ships with `wheels` itself. Fewer fork boundaries, less startup tax; generators feel instant.

## What it feels like now

The onboarding story is about a minute of prerequisites and about a minute of running tests.

```bash
# One-time setup
brew install lucli              # or download from GitHub releases
brew install openjdk@21         # Java 21 required
```

```bash
# Inner loop — the sixty-second test run
cd /path/to/wheels
bash tools/test-local.sh           # all core tests
bash tools/test-local.sh model     # model tests only
bash tools/test-local.sh security  # security tests only
```

That is the entire contract. The script creates SQLite databases if needed, starts a LuCLI server on a free port, hits the test runner, parses the JSON response, prints a summary, and exits. If you want a persistent server for browser poking, `lucli server run --port=8080` gets you one.

The CI configuration in `.github/workflows/pr.yml` runs the same script. No local-only path, no CI-only path. Local equals CI by construction.

## Why the framework team made this strategic

This is not only an ergonomic change. It is a deliberate shift in where Wheels' tooling dependency graph lives.

Before 4.0, Wheels development was tightly coupled to CommandBox, TestBox, and the rest of the Ortus toolchain. Those are fine tools. They are also a supply chain the Wheels core team does not control. When they ship breaking changes, we absorb them. When a user tries to contribute and trips over a CommandBox module resolution bug, we own the support burden even though the bug is not ours.

Moving the inner loop to LuCLI reduces that exposure. It also optimizes for the kind of development most of us actually do now — fast feedback loops, AI-augmented editing, a short leash between "I wrote something" and "I know it works." A sixty-second full test run is the difference between running the suite between keystrokes and not running it at all.

None of this is a rejection of CommandBox or TestBox. Both continue to work with Wheels 4.0. Teams standardized on the Ortus toolchain do not need to change anything. The LuCLI path is complementary.

## Cross-engine testing still matters

This is the honest paragraph. LuCLI plus Lucee 7 plus SQLite is the inner loop. It catches something like ninety-five percent of real bugs. It is not the full story.

The other five percent are the Adobe CF quirks — struct member function collisions, application-scope limitations, closure-this-capture differences, the bracket-notation function call parser crash in CF 2021 and 2023. And the database-specific SQL corners. Those still run in the full Docker compatibility matrix, on every PR.

The working pattern is simple: push early, push often. Run the LuCLI suite locally while you iterate. Let Docker CI catch the edge cases when you open the PR. Do not try to reproduce the full matrix on your laptop.

## What ships in the 4.0 CLI

The `wheels` command in 4.0 is itself a LuCLI module. The surface is broad:

- `wheels new` scaffolds a fresh app.
- `wheels generate model | controller | scaffold | admin` runs generators as in-process service calls.
- `wheels test run` executes the test suite through LuCLI.
- `wheels dbmigrate latest | up | down | info | diff` handles migrations, including auto-diff for model-versus-schema drift.
- `wheels seed` runs convention-based seeding from `app/db/seeds.cfm`.
- `wheels jobs work | status | retry | purge | monitor` handles the background job queue.
- `wheels browser:install` fetches the Playwright JARs and Chromium for the new browser testing DSL.
- `wheels server start | stop | status` wraps the LuCLI server lifecycle.
- `wheels deploy` is the Kamal port — covered in [its own post](/posts/wheels-deploy-kamal-port/).

Startup cost on all of these is close to zero once the LuCLI binary is on disk.

## What is still coming

Parity with the CommandBox-era `wheels` command surface is not complete yet. A handful of less-trafficked commands still need to be ported, and some subcommands still fork a subprocess rather than invoking the service layer in-process. Neither affects day-to-day work; both are on the 4.0.x polish list.

Per-OS packaging is the other open item. Homebrew and direct-download tarballs cover most contributors, and [chocolatey-wheels](https://github.com/wheels-dev/chocolatey-wheels) covers Windows, but we want the Linux install experience to be as one-line as macOS is today.

## Getting started

If you have not tried contributing to Wheels in a while, the barrier to entry is lower than it has been in a decade. `brew install lucli`, clone the repo, `bash tools/test-local.sh`. If your full test run does not come back in roughly a minute, we want to know — that number is the contract now, not an aspiration.

Thanks to the contributors who made this migration possible: [@bpamiri](https://github.com/bpamiri) on LuCLI itself, [@zainforbjs](https://github.com/zainforbjs), [@chapmandu](https://github.com/chapmandu), [@mlibbe](https://github.com/mlibbe), [@MukundaKatta](https://github.com/MukundaKatta), and Dependabot for keeping the supply chain moving underneath all of it.

## Where to go next

- [Contributing guide](https://github.com/wheels-dev/wheels/blob/develop/CONTRIBUTING.md) — workflow, branch conventions, and the Definition of Done for a PR.
- [LuCLI repo](https://github.com/bpamiri/LuCLI) — the binary itself; issues and feature requests go here, not on the Wheels tracker.
- [Running tests locally](https://guides.wheels.dev/v4-0-0-snapshot/testing/running-tests-locally/) — LuCLI path and the Docker matrix fallback for cross-engine coverage.
- [`wheels-cli-lucli`](https://github.com/wheels-dev/wheels-cli-lucli) — the distribution repo for the LuCLI module itself.

If you have been holding off on a Wheels PR because the dev setup was too heavy, now is a good time to try again.
