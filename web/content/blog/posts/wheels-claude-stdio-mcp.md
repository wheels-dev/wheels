---
title: 'Wheels + Claude: Building a Feature via the stdio MCP'
slug: wheels-claude-stdio-mcp
publishedAt: '2026-05-29T14:00:00.000Z'
updatedAt: '2026-05-29T14:00:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - mcp
  - ai
  - cli
categories: []
excerpt: >-
  Wheels 4.0 ships a stdio MCP server that exposes the CLI to AI editors —
  not as a chat sidekick, but as a tool surface a model can call. This post
  walks the architecture (reflection over a single CFC), builds a commenting
  feature end-to-end via Claude, and is honest about the config-template
  drift I hit while writing it.
coverImage: null
---

There are two ways to make an AI assistant useful inside a framework. The first is to put it in a sidecar — a chat window glued to the IDE, fed with a vector index of your codebase, generating snippets you copy-paste. That's where most frameworks landed first, and it's fine. The model is a smarter Stack Overflow.

The second is to teach the assistant the same vocabulary the framework already uses with humans. You don't ship "AI code generation"; you ship a CLI with `wheels generate model Post title:string`, and then you let the assistant *call that CLI directly* — with the same arguments, the same templates, the same validation — when a developer types "make me a Post model with a title." The model writes nothing. The framework writes everything, the same way it always has. The model just decides which command to run.

Wheels 4.0 ships the second one. The mechanism is the Model Context Protocol, the transport is stdio, and the implementation is small enough to fit in your head: a single `Module.cfc` whose public functions become tools by reflection, with a one-line override to hide the ones that don't make sense over an RPC. This post walks the architecture and then builds a commenting feature end-to-end through Claude Code talking to that surface.

## The shape of the integration

```
┌─────────────────┐   spawn   ┌────────────────────────┐
│   AI editor     │──────────▶│ wheels mcp wheels      │
│ (Claude/Cursor) │           │ (LuCLI stdio MCP)      │
│                 │ JSON-RPC  │                        │
│                 │◀─────────▶│   Module.cfc           │
└─────────────────┘  (stdio)  │   (public functions    │
                              │    → MCP tools)        │
                              └────────────────────────┘
```

The AI editor spawns `wheels mcp wheels` as a subprocess and speaks newline-delimited JSON-RPC 2.0 over stdin and stdout. There's no port, no socket, no running dev server. The subprocess lives for the duration of the session.

`wheels mcp wheels` is two pieces of vocabulary glued together: `wheels mcp` is LuCLI's generic MCP dispatcher (the binary's runtime is LuCLI, shipped under the `wheels` brand), and the trailing `wheels` is the *module name* to expose. LuCLI loads `cli/lucli/Module.cfc`, scans its public functions, and turns each one into a tool whose name is `<module>_<function>` — `wheels_generate`, `wheels_migrate`, `wheels_test`. The MCP protocol — `initialize`, `tools/list`, `tools/call`, the JSON-RPC framing — is all handled by the LuCLI runtime. The Wheels codebase contributes the functions, not the protocol.

This is the design choice worth noticing first: the MCP server is not a separate codebase you maintain alongside the CLI. It *is* the CLI. Anything you can do as a developer typing `wheels migrate latest` is something Claude can do by calling `wheels_migrate(action="latest")`. New CLI features become MCP features automatically, with no schema to write and no router to update.

## Setup, end to end

```bash title="your shell"
wheels mcp setup
```

That command writes two files into your project root:

- `.mcp.json` — picked up by Claude Code and any generic MCP-aware IDE.
- `.opencode.json` — picked up by OpenCode.

The Claude Code config is tiny:

```json title=".mcp.json"
{
    "mcpServers": {
        "wheels": {
            "command": "wheels",
            "args": ["mcp", "wheels"]
        }
    }
}
```

That's the whole thing — a command and its arguments. Claude Code reads it on startup, spawns `wheels mcp wheels`, and starts speaking JSON-RPC over the subprocess's stdio. There's no installation step, no API key, no auth handshake. If the `wheels` binary is on your `PATH` and the project has a `vendor/wheels/` checkout, you have a working MCP integration.

Cursor, Continue, and Windsurf all read the same `.mcp.json` — there's no per-IDE wrapper shape to configure. The setup command writes the two files and stops there; the IDE-specific config you'll see in some older docs is for tools that don't speak the standard MCP config format and need an entry in their own settings file. None of the four IDEs above falls into that bucket.

Restart your editor after running the setup command. On first start, the editor will spawn the subprocess and call `initialize` and `tools/list` — and the tools panel should now list `wheels_generate`, `wheels_migrate`, and the rest.

## What gets exposed (and what doesn't)

Tool discovery is a one-line CFML reflection step. LuCLI walks `Module.cfc`, finds every `public string function ...()`, reads its `hint:` annotation for the description, and emits a tool entry. The tool name is the module name (`wheels`) joined to the function name with an underscore.

A handful of functions don't belong over RPC, though, and the framework names them explicitly:

```cfm title="cli/lucli/Module.cfc"
public array function mcpHiddenTools() {
    return [
        "mcp",      // meta command — prints MCP setup instructions
        "d",        // alias for destroy
        "new",      // scaffolds a whole new Wheels project
        "console",  // interactive CFML REPL — not usable over stdio
        "start",    // dev server lifecycle (stateful)
        "stop",     // dev server lifecycle (stateful)
        "browser"   // multi-step browser testing flow
    ];
}
```

Each exclusion has a reason that maps to a property of the tool. `start` and `stop` manage long-lived processes, which are awkward over a single JSON-RPC call. `console` needs a bidirectional interactive terminal; stdio MCP gives you one direction per message. `new` creates a whole project hierarchy and isn't something a model should fire mid-session without an explicit out-of-band confirmation. `mcp` itself is hidden because calling it over RPC would let one MCP server spawn another, which is a recursion you don't want.

After the exclusions, the surface looks like this:

| Tool | Purpose |
|---|---|
| `wheels_generate` | Create models, controllers, migrations, scaffolds, tests, helpers. |
| `wheels_destroy` | Remove generated components, cascading by default. |
| `wheels_migrate` | Run migrations (`latest`, `up`, `down`, `info`). |
| `wheels_seed` | Run convention-based seed scripts. |
| `wheels_db` | Database utilities (reset, status, version). |
| `wheels_packages` | List, search, and add packages from the registry. |
| `wheels_test` | Run the test suite or a named subset. |
| `wheels_reload` | Reload a running dev-server app. |
| `wheels_routes` | Print the routing table. |
| `wheels_info` | Framework + project metadata. |
| `wheels_analyze` | Convention and anti-pattern scanner. |
| `wheels_validate` | Configuration + model validation. |
| `wheels_doctor` | Diagnose setup issues. |
| `wheels_stats` | Project statistics (model/controller/route counts). |
| `wheels_notes` | Find `TODO` / `FIXME` / `HACK` comments. |
| `wheels_upgrade` | Read-only breaking-change scanner. |
| `wheels_create` | Programmatic app creation (the non-interactive sibling of `new`). |
| `wheels_deploy` | Deployment orchestration (the `wheels deploy` family). |

Most of these are read-only or strictly additive. `destroy` is the one to think twice about, but it's also the one a developer is most likely to want to drive through Claude — "drop the abandoned Comment scaffold, redo it with the new association."

## A worked example: shipping commenting in 90 seconds

The [previous post in this series](/posts/anatomy-of-a-wheels-package/) introduced a deliberately toy package called `wheels-greeter` to walk the manifest fields. Here's a real flow with no toy in sight: add commenting to an existing `Post` model on a blog. Migration, association, controller, routes, tests. The whole loop, driven by Claude through the MCP surface.

Type this into Claude Code:

> Add commenting to the blog. Each comment belongs to a Post, has an `author` (string) and `body` (text). Generate the migration and model, wire the association on Post, run the migration, and add a smoke test that asserts a Post can have many comments.

Claude reads the surface (it called `tools/list` on session start), recognises that this is a generate-then-migrate-then-test loop, and starts dispatching:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "wheels_generate",
    "arguments": { "type": "model", "name": "Comment",
                   "attributes": "postId:integer,author:string,body:text" }
  }
}
```

`Module.generate()` runs, the codegen service substitutes templates, and you see `created app/models/Comment.cfc` plus a `*_create_comments.cfc` migration land on disk. The response back over stdout is a JSON-RPC result wrapping the CLI's stdout output as a single text content block:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      { "type": "text", "text": "created  app/models/Comment.cfc\ncreated  app/migrator/migrations/20260529140100_create_comments.cfc" }
    ]
  }
}
```

Claude reads the response, sees the migration filename, and continues. Next it edits `app/models/Post.cfc` directly (no MCP tool needed for a one-line file edit) to add `hasMany(name="comments", dependent="delete")`. Then:

```json
{ "method": "tools/call",
  "params": { "name": "wheels_migrate", "arguments": { "action": "latest" } } }
```

Migration runs, the `comments` table appears in the DB. Then:

```json
{ "method": "tools/call",
  "params": { "name": "wheels_generate",
              "arguments": { "type": "test", "name": "CommentAssociationSpec",
                             "target": "models" } } }
```

A spec file gets generated under `tests/specs/models/`. Claude writes the actual assertions into it (`expect(post.commentCount()).toBe(2)`), then runs the test suite:

```json
{ "method": "tools/call",
  "params": { "name": "wheels_test",
              "arguments": { "filter": "CommentAssociationSpec" } } }
```

If the test passes, Claude reports back to the developer. If it fails, Claude reads the error output (still text content, still over stdio), patches the model or the spec, and re-runs. The loop is conversational because the protocol is conversational — every tool call returns text, every text is something the model can read and act on.

The whole exchange takes the model maybe four seconds of round-trip plus however long the migration and test suite take. The developer types one prompt; the framework does what it would have done if a developer had typed five commands. The MCP server is the bridge.

## Why the reflection model holds up

The temptation, when designing an AI integration, is to invent a separate surface. A new "AI service" CFC. A `aiCommands.cfm` that wraps the real CLI with a parallel set of carefully-curated entry points. A JSON schema kept by hand and updated whenever someone adds a new generator type.

That's how you end up with two surfaces that drift. The CLI gains a `wheels generate api-resource` verb and somebody forgets to add it to the AI surface. The MCP tool advertises an `--attributes` flag that the underlying CLI renamed three months ago. The two surfaces are different enough that a bug fix in one doesn't reach the other.

The reflection approach skips that drift by construction. `Module.cfc` is the CLI. It is also the MCP server. There is no second copy of "what generate accepts" to keep in sync. The tools/list response is regenerated every time the subprocess starts; the descriptions come from the same `hint:` comments humans read when they run `wheels generate --help`. If a generator gains a new component type, the MCP tool gains the same type at the same moment, with no extra work.

The cost is that the MCP schema is a little less expressive than a hand-curated one would be. Tool descriptions are one-line `hint:` strings rather than richly-typed JSONSchema with enums and per-parameter examples. In practice, that ceiling hasn't bitten — models are fine with one-liners and a couple of canonical examples in the system prompt — but it's the honest trade. If you ever need richer schemas you can add explicit annotations to individual functions and let the reflection layer prefer them; nothing in the design forces every tool to live at the same level of detail.

## The deprecated HTTP endpoint

If you've used the MCP integration in a 3.x build, you may remember a different shape: a dev-server route at `/wheels/mcp` that spoke Streamable HTTP JSON-RPC, required a running app, and lived in `vendor/wheels/public/views/mcp.cfm`. That endpoint still exists, with a deprecation notice at the top of the file and a one-time `WriteLog(type="warning", ...)` on first request. It's scheduled for removal in a future release.

The reason for the shift is the same as the reason for the design choice above: the HTTP endpoint was a parallel surface that had to be kept in sync. Tool schemas in `vendor/wheels/public/mcp/McpServer.cfc` were hand-written, separate from the CLI's behaviour, and drifted. The stdio surface deletes the parallel surface entirely; the CLI *is* the MCP server, and the MCP server *is* the CLI.

If you have a `.mcp.json` or `.opencode.json` from a 3.x project that points at `http://localhost:<port>/wheels/mcp`, re-run `wheels mcp setup --force` to overwrite it with the stdio form.

## What changed while writing this post

Drafting the post turned up two pieces of config drift in the setup command's own templates. Both fixed in the same PR.

`wheels mcp setup` writes two files: `.mcp.json` and `.opencode.json`. The first one — the one Claude Code reads — was correct, pointing at the canonical `{"command": "wheels", "args": ["mcp", "wheels"]}` stdio surface. The second one, the OpenCode template, was not. It still pointed at the deprecated HTTP endpoint:

```json
{
    "$schema": "https://opencode.ai/config.json",
    "mcp": {
        "wheels": {
            "url": "http://localhost:{PORT}/wheels/mcp",
            "type": "remote",
            "enabled": true
        }
    }
}
```

Two problems. First, the URL is the deprecated endpoint that emits a warning every time it's called and is scheduled for removal. Second, the `{PORT}` placeholder is a literal string — the setup command writes the template verbatim without substituting it, so an OpenCode user running `wheels mcp setup` ends up with a `.opencode.json` that contains the literal characters `{PORT}` in the URL. It does not resolve to anything. The OpenCode MCP plumbing tries to connect to a host called `{PORT}` and fails.

The fix is the same shape OpenCode supports for any stdio MCP server — `type: "local"` plus a `command` array:

```json
"wheels": {
    "type": "local",
    "command": ["wheels", "mcp", "wheels"],
    "enabled": true
}
```

This shape was already in `tools/build/base/.opencode.json` (the canonical reference copy used by the monorepo's build), and the CHANGELOG entry from when the stdio shift landed actually claimed the templates had been updated everywhere. They hadn't — two files (`cli/src/templates/OpenCodeConfig.json` and `app/snippets/OpenCodeConfig.json`) were missed. Both are now corrected, and a future `wheels mcp setup` run gives OpenCode users a working stdio config on the first try.

The second piece of drift is smaller and worth flagging without fixing in this PR. The `mcp()` meta function in `Module.cfc` prints "For OpenCode, Cursor, and other AI IDEs, see: docs/command-line-tools/commands/mcp/mcp-configuration-guide.md" — and that file doesn't exist. The same path is referenced from the deprecation notice in `vendor/wheels/public/views/mcp.cfm`. Two places point at a guide that was planned but never written. The author-facing v4 MCP integration coverage currently lives at `web/sites/guides/.../v4-0-1-snapshot/command-line-tools/mcp-integration.mdx` — a fine place for it — but the CLI runtime and the deprecation warning both advertise a different filename. Fixing the references (or writing the missing guide and aligning the references to it) is its own follow-up.

Neither of these is a code-path bug. They're documentation-and-templates drift, the same shape as the package-system fixes from the previous post. The pattern keeps holding: writing the article forces you to actually walk every path a reader will walk, and the parts where the docs disagree with the code are exactly the parts where the next person was going to get stuck.

The next post in the series picks up the other surface where 4.0 quietly changed posture: *Beyond findAll — scopes, enums, and the chainable query builder*. Coming next week.
