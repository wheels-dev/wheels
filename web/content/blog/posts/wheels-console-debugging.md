---
title: 'wheels console: The Debugging Move You''re Not Using'
slug: wheels-console-debugging
publishedAt: '2026-07-21T14:00:00.000Z'
updatedAt: '2026-07-06T05:23:50.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - cli
  - console
  - debugging
categories: []
excerpt: >-
  A REPL inside your running app: models resolve, scopes chain, the DI
  container answers, settings read back. The sessions that replace
  writeDump-and-refresh archaeology, the slash-commands, and why console and
  repl are different tools that look alike.
coverImage: null
---

There's a debugging move every Rails developer has muscle-memorized: something's weird, so you open `rails console`, poke the actual application — real models, real config, real database — and know in thirty seconds what would have taken thirty minutes of `writeDump()`-and-refresh archaeology.

Wheels 4 has that move: `wheels console`. It connects to your **running dev server** and evaluates whatever you type *inside the live application context* — models resolve, scopes chain, the DI container answers, settings read back. This post is the working tour: what's available at the prompt, the slash-commands, the sessions that replace dump-and-refresh, and the difference between `console` and its lookalike, `repl`.

## What the prompt can see

Start a dev server, then from the project root:

```bash
wheels console
```

You get a `wheels>` prompt wired into the app. Anything that would compile inside a CFML component is fair game, and the surfaces you'll actually reach for:

| Surface | Example |
|---|---|
| Model finders | `model("User").findAll()` |
| Model instances | `model("User").new(email="test@example.com")` |
| Scopes & chains | `model("Post").published().where("authorId", 1).get()` |
| DI services | `service("emailService")` |
| Framework settings | `get("environment")`, `get("dataSourceName")` |
| Live app globals | `application.wheels.version`, `application.wheels.routes` |
| Plain CFML | `now()`, `arrayLen([1,2,3])` |

Results come back formatted for a terminal: queries as column-aligned tables, model instances as key-value blocks, structs and arrays pretty-printed as JSON, primitives inline after `=>`.

## The sessions that pay for themselves

**"Why is this record invalid?"** — the classic. Instead of a form, a submit, and a dump:

```text
wheels> var u = model("User").new(email="bad")
wheels> u.valid()
=> false

wheels> u.errorsOn("email")
=> [
    {
      "message": "must be a valid email address"
    }
  ]
```

Three lines, and you're reading the actual validation output of the actual model class the running app loaded — not your assumption about it.

**"Is my scope chain building the query I think it is?"**

```text
wheels> model("Post").published().recent().findAll().recordCount
=> 17
```

Seventeen, not the forty you expected? Now you know the problem is in the scope definitions, not the view — before you've touched a template.

**"Did my service register correctly?"** — the DI question that otherwise surfaces as a 500 three requests later:

```text
wheels> var svc = service("emailService")
wheels> svc.isConfigured()
=> true
```

**"What does the app think its config is?"** — not what `settings.cfm` says; what the merged, per-environment, `.env`-resolved runtime actually holds. `get("environment")`, `get("dataSourceName")`, one keystroke each. If you read our [configuration post](https://blog.wheels.dev/posts/how-wheels-reads-configuration), this is the fastest way to confirm which of the two systems won.

## The slash-commands

Lines starting with `/` are shortcuts for inspections you'd otherwise type long-form:

| Command | Does |
|---|---|
| `/models` | Every registered model, alphabetized |
| `/routes` | All routes as `pattern -> controller#action` |
| `/env` | The current environment struct |
| `/ds` | The current datasource name |
| `/version` | The Wheels version the app is actually running |
| `/reload` | Reload the application — same as `?reload=true` |
| `/help`, `/clear`, `/exit` | What they say |

`/routes` deserves a highlight: "which route does this URL actually hit?" is a question the console answers in one line, with the same data the dispatcher uses. And `/reload` closes the loop on a config-editing session — change `settings.cfm` in your editor, `/reload` in the console, `get()` the value to confirm, never touching a browser.

## `console` is not `repl`

The CLI ships two prompts that look alike and aren't:

| | `wheels console` | `wheels repl` |
|---|---|---|
| Prompt | `wheels>` | `cfml>` |
| App context | Full Wheels app | None — bare CFML evaluator |
| Models / DI resolve? | Yes | No |
| Requires a running server? | Yes | No |

`repl` is a calculator: quick CFML expression evaluation anywhere, no project needed. `console` is a stethoscope: it needs a running server precisely *because* its whole value is evaluating inside that server's state. If you type `model("User")` into `repl` and get an error, nothing's broken — you're in the wrong tool.

## Two habits worth forming

**Verify state after mutations, not from memory.** After a migration, `model("Post").new()` in the console and eyeball the properties — the schema the ORM read, not the schema you meant. After a seed run, `model("Role").findAll()` — did `seedOnce()` match on the unique property or create a duplicate? The console reads the same application state the next request will use, so what you see is what production logic gets.

**Treat it as executable, so treat it with respect.** `model("User").deleteAll()` at the console prompt does exactly what it does anywhere else — this is a live evaluator against your dev database, not a sandbox. That immediacy is the point; it just cuts both ways.

One boundary worth stating plainly: the console is a development-workflow tool wired to your dev server. For inspecting *production* state, the answer is the observability plumbing — [request IDs, health endpoints, and structured logs](https://blog.wheels.dev/posts/observability-in-wheels-4) — not a REPL against a production box.

If you don't use the wheels CLI, this is one of the few features on the [honest list](https://blog.wheels.dev/posts/wheels-4-the-commandbox-way) with no in-app equivalent — the interactivity *is* the feature. It's also, in our experience, the single best argument for having the CLI installed alongside whatever else you use: the full reference is at [Console & REPL](https://guides.wheels.dev/v4-0-0/command-line-tools/wheels-commands/console-and-repl/) in the CLI guides.

