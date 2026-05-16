# Social Posts — "Wheels + Claude: Building a Feature via the stdio MCP"

**Status:** Copy-paste ready. Third post in the post-GA series after the rate-limiter and packages articles.
**Pairs with:** [docs/releases/blog-drafts/wheels-claude-stdio-mcp.md](../blog-drafts/wheels-claude-stdio-mcp.md)
**Post date:** 2026-05-19 (same day as the article)
**Tone:** Post-GA, present tense, "AI is just another developer using the same CLI" angle.

**Canonical URL** (use everywhere):
- `https://blog.wheels.dev/posts/wheels-claude-stdio-mcp`

---

## Slack (#wheels-dev)

```
New on the blog: Wheels + Claude — Building a Feature via the stdio MCP.

<https://blog.wheels.dev/posts/wheels-claude-stdio-mcp|Full post>

What it covers:
• The architecture — `wheels mcp wheels` is one CLI subcommand, the MCP protocol is LuCLI's runtime, and Wheels just exposes public functions on Module.cfc as tools via reflection. No parallel surface.
• `mcpHiddenTools()` and why start/stop/new/console/browser/mcp/d are excluded
• A worked example — Claude builds an entire commenting feature (migration, model, association, test) from a single prompt by chaining wheels_generate / wheels_migrate / wheels_test
• The deprecated `/wheels/mcp` HTTP endpoint and why the stdio surface replaces it
• Setup is one command: `wheels mcp setup` writes .mcp.json (Claude Code) and .opencode.json (OpenCode)

Side effect of writing the post: two template-drift fixes (#2735) — the OpenCode setup template still pointed at the deprecated HTTP endpoint with an unsubstituted `{PORT}` placeholder. Anyone running `wheels mcp setup` for OpenCode got a config that couldn't connect. Both templates now use the stdio form already shipped in tools/build/base/.opencode.json.
```

---

## LinkedIn

```
New on the Wheels blog: Wheels + Claude — Building a Feature via the stdio MCP.

There are two ways to make an AI assistant useful inside a framework. The first is to put it in a sidecar — a chat window glued to the IDE, generating snippets you copy-paste. The second is to teach the assistant the same vocabulary the framework already uses with humans. You don't ship "AI code generation"; you ship a CLI, and you let the assistant call that CLI directly. Wheels 4.0 ships the second one.

The mechanism is the Model Context Protocol, the transport is stdio, and the implementation is small enough to fit in your head: a single Module.cfc whose public functions become MCP tools by reflection, with a one-line override to hide the ones that don't make sense over RPC. The post walks the architecture and then builds a real feature — adding commenting to a blog (migration, model, association, test) — end-to-end through Claude Code talking to that surface.

Topics covered:

— The reflection model. Module.cfc IS the CLI, and Module.cfc IS the MCP server. Every public function with a hint annotation becomes a tool named wheels_<function>. New CLI features become MCP features automatically, with no schema to write and no router to update.
— Why some commands are deliberately hidden via mcpHiddenTools(). start/stop are stateful; console needs an interactive terminal; new scaffolds a whole project; mcp would let one MCP server spawn another.
— The full tool catalog — wheels_generate, wheels_migrate, wheels_test, wheels_destroy, and a dozen others. The shape of a tools/list response.
— What an actual MCP exchange looks like for a tools/call request, what the framework does in response, and how Claude reads the text content back to decide the next step.
— Why the parallel-surface trap is real: hand-curated AI schemas drift from the CLI they wrap. The reflection model avoids that by construction.
— The deprecated HTTP endpoint at /wheels/mcp, the deprecation notice it now emits, and the path to migrating off it.

A side note in the post: writing it surfaced two template-drift bugs. The OpenCode setup template (used by `wheels mcp setup`) still pointed at the deprecated HTTP endpoint with an unsubstituted `{PORT}` placeholder. Anyone configuring OpenCode through the setup command ended up with a non-functional config. Fixed in the same PR; both OpenCode template copies now match the stdio shape already shipped in the build-base reference copy.

Read: https://blog.wheels.dev/posts/wheels-claude-stdio-mcp

#CFML #Wheels #MCP #AI #ClaudeCode #DeveloperTools
```

---

## X / Twitter

**Hero tweet (unnumbered):**
```
New on the Wheels blog — Wheels + Claude: Building a Feature via the stdio MCP.

Module.cfc is the CLI. Module.cfc is also the MCP server. Reflection on public functions. No parallel surface to drift.

https://blog.wheels.dev/posts/wheels-claude-stdio-mcp
```

**Reply 1:**
```
1/ The architecture in one paragraph:

`wheels mcp wheels` spawns a stdio JSON-RPC server. LuCLI's runtime handles the protocol. Wheels exposes Module.cfc, and every `public string function ...()` becomes a tool named `wheels_<function>`.

No router, no hand-written schemas, no second surface.
```

**Reply 2:** (outer fence is `~~~~` so the inner ```` ```json ```` block renders correctly in the Markdown preview)

~~~~
2/ The whole .mcp.json:

```json
{
    "mcpServers": {
        "wheels": {
            "command": "wheels",
            "args": ["mcp", "wheels"]
        }
    }
}
```

That's it. `wheels mcp setup` writes it for you.
~~~~

**Reply 3:**
```
3/ Why some commands are hidden via mcpHiddenTools():

• start/stop — stateful, long-lived processes
• console — interactive REPL needs a bidirectional terminal
• new — scaffolds a whole project; not a mid-session move
• mcp — would let one MCP server spawn another
• browser — multi-step flow, doesn't fit single RPC calls

Everything else is on.
```

**Reply 4:**
```
4/ Side effect of writing the post: two template-drift fixes (#2735).

`wheels mcp setup` wrote a .opencode.json pointing at the deprecated HTTP endpoint, with the {PORT} placeholder left as a literal string. OpenCode users got a config trying to connect to a host called {PORT}.

Both templates now use the stdio form. Same shape as the build-base reference copy.
```

---

## GitHub Discussions

**Title:** `Post-GA blog: Wheels + Claude — Building a Feature via the stdio MCP`

```markdown
Third in the post-GA series. The rate-limiter post took the middleware pipeline; the packages post took the extension model; this one takes the AI surface and answers the question we've been getting since 4.0 went GA: "how do I actually use the MCP integration?"

**Read:** https://blog.wheels.dev/posts/wheels-claude-stdio-mcp

The post is an architecture walkthrough plus a worked end-to-end example (building a commenting feature on a blog through Claude Code). It covers:

- **The shape of the integration** — `wheels mcp wheels` is one CLI subcommand; the AI editor spawns it as a subprocess and speaks newline-delimited JSON-RPC 2.0 over stdin/stdout. No port, no socket, no running dev server.
- **The reflection model** — `Module.cfc` IS the CLI, and `Module.cfc` IS the MCP server. Every `public string function ...()` becomes a tool named `wheels_<function>` via LuCLI's reflection layer. The `hint:` annotation becomes the tool description. New CLI features become MCP features automatically with no parallel surface to maintain.
- **`mcpHiddenTools()`** — the one-line override that excludes `start`, `stop`, `new`, `console`, `mcp`, `d`, `browser` from MCP `tools/list` while keeping them available as CLI subcommands. Each exclusion maps to a property of the tool (stateful, interactive, scaffolding, meta, alias, multi-step).
- **The tool catalog** — 20 tools, after `mcpHiddenTools()` strips the seven that don't translate to RPC. `wheels_version`, `wheels_showHelp`, `wheels_generate`, `wheels_destroy`, `wheels_migrate`, `wheels_seed`, `wheels_db`, `wheels_packages`, `wheels_test`, `wheels_reload`, `wheels_routes`, `wheels_info`, `wheels_analyze`, `wheels_validate`, `wheels_doctor`, `wheels_stats`, `wheels_notes`, `wheels_upgrade`, `wheels_create`, `wheels_deploy`. Most are read-only or strictly additive; `destroy` is the one you'll think twice about.
- **The worked example** — one developer prompt ("add commenting to the blog, comments belong to Post, with author and body, generate the migration and model, wire the association, run the migration, add a smoke test"), four chained tool calls (`wheels_generate model`, file edit, `wheels_migrate`, `wheels_generate test`, `wheels_test`), one passing test. The whole loop in maybe four seconds of RPC round-trip plus the actual migration and test time.
- **Why the reflection model holds up** — the parallel-surface trap (hand-curated AI schemas drift from the CLI they wrap), how the reflection approach makes drift structurally impossible, and the honest trade (one-line `hint:` descriptions vs. richly typed JSONSchema).
- **The deprecated HTTP endpoint** — `/wheels/mcp` in `vendor/wheels/public/views/mcp.cfm` still exists with a deprecation notice and `WriteLog(type="warning", ...)` on first request. Scheduled for removal.

## Side note: two template-drift bugs surfaced while writing this

Drafting the post turned up two pieces of config-template drift around `wheels mcp setup`, both fixed in the same PR ([#2735](https://github.com/wheels-dev/wheels/pull/2735)).

The first: `wheels mcp setup` writes `.mcp.json` (Claude Code) and `.opencode.json` (OpenCode). The Claude config was correct, pointing at the canonical `{"command": "wheels", "args": ["mcp", "wheels"]}` stdio surface. The OpenCode config was not — it still pointed at the deprecated HTTP endpoint with `"url": "http://localhost:{PORT}/wheels/mcp"`, and the `{PORT}` placeholder was left as a literal string. OpenCode users running `wheels mcp setup` got a config trying to connect to a host called `{PORT}` against an endpoint that emits a deprecation warning on every call. The canonical stdio shape was already in `tools/build/base/.opencode.json`; the two template copies that the setup command actually reads from (`cli/src/templates/OpenCodeConfig.json` and `app/snippets/OpenCodeConfig.json`) had been missed when the stdio shift originally landed. Both now match. The CHANGELOG entry from that earlier work claimed all templates had been updated; this closes the two that weren't.

The second: the `mcp()` meta function in `Module.cfc` prints "For OpenCode, Cursor, and other AI IDEs, see: docs/command-line-tools/commands/mcp/mcp-configuration-guide.md" — and that file doesn't exist. The same path is also referenced from the deprecation notice on the HTTP endpoint. Two places advertise a guide that was planned but never written. Not fixed in this PR — the v4 MCP integration content actually lives at `web/sites/guides/.../v4-0-1-snapshot/command-line-tools/mcp-integration.mdx`; aligning the CLI's runtime output (and the deprecation notice) to point there, or writing the missing guide and keeping the original path, is its own follow-up.

Neither was a code-path bug. They're documentation-and-templates drift, the same shape as the package-system fixes from the previous post. The pattern keeps holding: writing the article forces you to walk every path a reader will walk, and the parts where the docs disagree with the code are exactly the parts where the next person was going to get stuck.

## What's next in the post-GA series

The remaining two titles from the second batch:

1. *Beyond findAll* — scopes, enums, the chainable query builder
2. *From Empty Directory to Deployed SaaS* — end-to-end with generators, multi-tenancy, jobs, browser tests, `wheels deploy`

Feedback on the MCP post — what's confusing, what's missing, what you'd want a future post to cover — welcome in this thread. The author-facing integration guide for v4 lives at https://guides.wheels.dev/v4-0-1-snapshot/command-line-tools/mcp-integration/ if you want the full field-by-field treatment.
```

---

## Posting checklist

- [ ] Article live at `https://blog.wheels.dev/posts/wheels-claude-stdio-mcp`
- [ ] PR #2735 merged (article + OpenCode template drift fix + CHANGELOG entry)
- [ ] Slack post in `#wheels-dev`
- [ ] LinkedIn post from the Wheels org account
- [ ] X / Twitter hero + 4-reply thread from `@wheels_dev`
- [ ] GitHub Discussions thread under "Show and tell" or equivalent category
- [ ] Verify all four channels link to the same canonical URL
