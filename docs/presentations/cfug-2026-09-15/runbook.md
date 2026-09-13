# Wheels live demo — presenter's runbook

**For the iPad.** Every command you type, in order, with what you should see and
one line on *why it matters*. Verified end to end on a stock `wheels new` app,
CLI build **2488**, on 2026-09-13. Exact counts below are what that run
produced — if yours differ, say so out loud rather than glossing over it.

> Terminal width matters. Keep the projected terminal at ≥ 100 columns so
> `wheels routes` and the scaffold output don't wrap.

---

## Before you walk in

```bash
wheels --version
```

Expect **4.1.0-snapshot.2488** or newer. Anything older is missing the
button styling and the 404 guard, and the demo will *look* wrong.

```bash
cd ~/GitHub/_demo
rm -rf blogdemo && rm -rf ~/.wheels/servers/blogdemo
```

Start from nothing. The whole point is that the audience watches the app come
into existence.

Have these two browser tabs open and hidden: `http://localhost:8080` and an
empty tab for `/register` later.

---

## Beat 1 — a running app (≈4 min)

```bash
wheels new blogdemo
cd blogdemo
wheels start
```

**See:** `Using port 8080 (shutdown 8081)`, then `✅ Server started`. Open
`http://localhost:8080` — the Wheels wordmark, a "The details" panel, and two
cards: **Guides** and **API docs**. Click one; it opens a new tab and works
**offline** — the docs shipped with the app.

**Why it matters.** Zero configuration produced a running MVC app with a
SQLite database, a test suite, and its own documentation. Point at
`CLAUDE.md` and `AGENTS.md` in the tree: the app ships instructions for AI
coding agents too — that's Beat 8.

> If port 8080 is taken, `wheels start` picks the next free *shutdown* port
> automatically and tells you. It will never silently move the HTTP port.

---

## Beat 2 — scaffold, migrate, seed, CRUD (≈8 min)

```bash
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime --dry-run
```

**See:** eleven `Would create` lines and **no files written**. Check
`ls app/models` — empty.

**Say:** "Dry run first. It tells me exactly what it's about to do."

```bash
wheels routes
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime
wheels migrate latest
wheels seed --generate
wheels reload
wheels routes
```

**See:** `Created table posts` · `Seeded: 10 created, 0 skipped` · the
`posts` resource routes.

Open `app/models/Post.cfc`:

```cfm
validatesPresenceOf("title,body,publishedAt");
validatesLengthOf(property="title", maximum=50, allowBlank=true);
```

**Why it matters.** The `{50}` on `title` became *both* a column limit in the
migration *and* a validation rule in the model. One declaration, two
consequences, kept in sync by the generator. The seed produced ten posts with
real datetimes, not nulls.

**Browser:** `/posts` → ten posts. Create one titled **Hello, Wheels** (keep
it — it's used in Beat 4). Edit its body. Create a throwaway, then press its
**Delete** button.

**See:** the three actions — **Edit · Delete · ← all posts** — are identical
blue buttons in one flush row. Then type the deleted post's URL back into the
address bar.

**See:** **404**, not an error page.

**Why it matters.** Delete is a *soft* delete (`deletedAt`), so the row
survives for audit but the app treats it as gone — including returning a
proper 404 instead of a 500. That guard is in every scaffolded controller.

---

## Beat 3 — it wrote files; you own them (≈5 min)

Open `app/models/Post.cfc` and add two lines inside `config()`:

```cfm
validatesExclusionOf(property="title", list="Untitled", allowBlank=true);
hasMany(name="comments");
```

```bash
wheels reload
```

**Browser:** `/posts/new`. Submit empty → **Title can't be empty**,
**Body can't be empty**. Submit with title **Untitled** → **Title is
reserved**.

**Why it matters.** The generator gave you a starting point, not a cage.
You add a business rule in one line and the form enforces it — no controller
change, no view change. The `hasMany` is deliberate setup for Beat 4: watch
what the *next* scaffold does with it.

---

## Beat 4 — associations and a REPL (≈5 min)

```bash
wheels generate scaffold Comment body:text --belongsTo=post
wheels migrate latest
wheels seed --generate
wheels reload
```

**See:** two extra lines you didn't ask for —
`modify controller: app/controllers/Posts.cfc` and
`modify view: app/views/posts/show.cfm`. Then
`Seeded: 20 created, 0 skipped`.

**Say:** "I scaffolded Comment. It reached back and wired the *parent*."

Show the audience what changed in `Posts.cfc`:

```cfm
post=model("Post").findByKey(key=params.key, include="comments");
```

And in `Post.cfc` — still exactly **one** `hasMany`. It saw yours from Beat 3
and reused it rather than adding a duplicate.

**Why it matters.** Both sides of the relationship are wired: `belongsTo` on
the child, eager-load on the parent's show action, a comments block in the
parent's view. And the seeder is association-aware — every one of those ten
comments points at a real post. Zero orphans.

**Browser:** `/posts/1` shows its comment. **Add a comment** — the Post
dropdown lists **titles**, not IDs. Submit blank → **Body can't be empty**.
Pick **Post Title 3**, add a body, then visit `/posts/3` to see it.

```bash
wheels console
```

```cfm
model("Comment").findByKey(3).post().title
model("Post").where("title", "LIKE", "%Wheels%").orderBy("publishedAt", "DESC").get()
/exit
```

**See:** `=> Post Title 3`, then your **Hello, Wheels** row from Beat 2.

**Why it matters.** The console runs *inside the live app* — same models,
same database — not a mock. The second line is the chainable query builder:
`where` / `orderBy` / `get`, injection-safe because the value travels
separately from the SQL.

---

## Beat 5 — authentication and authorization (≈10 min)

```bash
wheels generate auth --strategy=session
wheels migrate latest
```

Open `app/models/User.cfc`. The column is **`passwordHash`**; the model
calls **`bcryptHash()`** and **`bcryptVerify()`**.

**Why it matters — say this one carefully.** Nobody in this room should be
writing their own password hashing. The generator produced bcrypt with a
cost factor, a `passwordConfirmation` virtual field, reset tokens with
expiry, and session handling — the parts people get wrong, done once, done
right.

The generator does *not* add a logout link to your layout (that's your
design decision). Add this to `app/views/layout.cfm`, inside the
`<cfoutput>`, **before `#flashMessages()#`, in both branches**:

```cfm
<nav aria-label="Demo navigation">
    #linkTo(route="posts", text="Posts")#
    #linkTo(route="login", text="Log in")#
    #buttonTo(route="logout", method="delete", text="Log out")#
</nav>
```

```bash
wheels reload
```

**Browser** (use a throwaway address; type the password, don't project it):

| step | flash you should see |
|---|---|
| `/register`, 12+ char password + matching confirmation | **Welcome!** |
| press **Log out** | **You have been logged out.** |
| `/login`, wrong password | **Invalid email or password.** |
| `/login`, right password | **Welcome back.** |

**Say:** "Log out is a *button*, not a link — it's a DELETE with a CSRF
token. A GET link that logs you out is a security hole the framework won't
let me create by accident."

Now authorization — a different question from authentication:

```bash
wheels generate policy Post
```

Open `app/policies/PostPolicy.cfc`. **Every method returns `false`.**

**Say:** "Default deny. Nothing is allowed until I say so."

Change `show()`:

```cfm
public boolean function show() {
    return IsStruct(variables.user) && !StructIsEmpty(variables.user);
}
```

In `app/controllers/Posts.cfc`, add one line in `show()` **after** the
finder:

```cfm
authorize(post);
```

```bash
wheels reload
```

**Browser:** log out, visit `/posts/1` → **403**. Log in, same URL →
**200**.

**Why it matters.** Authentication answers *who are you*. Authorization
answers *are you allowed*. Wheels keeps them separate on purpose: policies
are plain CFCs you can unit-test, and calling `authorize()` is explicit —
no hidden magic deciding access for you. Notice also that a soft-deleted
post returns **404** even when logged out: the not-found guard runs *before*
the policy, so an attacker can't probe which IDs exist.

**Before Beat 6 — remove the `authorize(post);` line and reload.** The
scaffold's controller specs aren't logged in; leaving it in makes them fail
for a reason that has nothing to do with the framework.

---

## Beat 6 — red, green (≈8 min)

```bash
rm -f db/test.sqlite
wheels test
```

**See:** **27 passed** on a *fresh* test database.

**Say:** "Every scaffold generated its own specs. I haven't written a test
yet and I have 27."

Open `tests/specs/models/PostSpec.cfc` and add inside the `describe`:

```cfm
it("requires a body", () => {
    var post = model("Post").new(title="No body here", publishedAt=Now());
    expect(post.valid()).toBeFalse();
    expect(post.errorsOn("body")).notToBeEmpty();
});
```

```bash
wheels test
```

**See:** **28 passed**.

Now break the rule on purpose. In `Post.cfc`, remove **only `body`** from
`validatesPresenceOf("title,body,publishedAt")` so it reads
`"title,publishedAt"`.

```bash
wheels reload
wheels test
```

**See:** **27 passed, 1 failed** · `FAIL: requires a body`.

Put `body` back.

```bash
wheels reload
wheels test
```

**See:** **28 passed**.

**Why it matters.** The test caught a real regression in the model within
seconds — this is the safety net that makes the "you own the files" promise
from Beat 3 safe. Tests run against an *isolated* test application and
database, so nothing here touched the data you've been clicking through.

---

## Beat 7 — the two-minute tour (≈7 min)

```bash
wheels info
wheels migrate diff
wheels coverage --top=5
```

**See:** `info` names the framework version, models, routes and the running
server. `migrate diff` → **No differences found — models and database are in
sync.** `coverage` ranks files by **CRAP** score — change risk.

**Say:** "`migrate diff` compares my *models* to the *actual schema*. If I'd
added a property without a migration, it would write the migration for me."

```bash
wheels generate api-resource Product name price:decimal sku:string
wheels migrate latest
wheels reload
export DEMO_URL=http://localhost:8080
```

```bash
curl -i -X POST "$DEMO_URL/api/products" -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Drum","price":149.99}}'
```

**See:** **422** with `{"ERROR":"Validation failed","ERRORS":[{"property":"sku",...}]}`

```bash
curl -i -X POST "$DEMO_URL/api/products" -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Drum","price":149.99,"sku":"DRUM-001"}}'
```

**See:** **201** with the created product.

```bash
curl -i "$DEMO_URL/api/products"
curl -i "$DEMO_URL/api/products/99999"
curl -i -X DELETE "$DEMO_URL/api/products/1"
```

**See:** **200** · **404** · **204**.

**Why it matters.** Same models, same validations, no views — a JSON API in
one command. The 422 carries the *same* error the HTML form would show. The
status codes are right without you thinking about them.

```bash
wheels test
```

**See:** **36 passed** — the API resource brought its own specs.

---

## Beat 8 — Wheels and AI coding agents (≈5 min)

Show `.mcp.json` (create it if you like):

```json
{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}
```

**Say:** "That's the entire configuration. Any MCP-capable assistant —
Claude Code, Cursor, OpenCode — now has **19 tools** that run against *this
project*: generate, migrate, routes, test, seed, doctor…"

If your assistant is connected, ask it to scaffold a Tag. Otherwise:

```bash
wheels generate scaffold Tag 'name:string{30}' slug:string
wheels migrate latest
wheels reload
```

Open `app/models/Tag.cfc`: `validatesPresenceOf("name,slug")` and
`maximum=30`. The attributes arrived intact.

Create `app/db/seeds.cfm`:

```cfm
<cfscript>
seedOnce(modelName="Tag", uniqueProperties="slug", properties={
    name: "CFUG Demo",
    slug: "cfug-demo"
});
</cfscript>
```

```bash
wheels seed --mode=convention
wheels seed --mode=convention
```

**See:** `1 created, 0 skipped`, then `0 created, 1 skipped`.

**Say:** "Idempotent. I can run seeds on every deploy and never duplicate a
row."

**Browser:** `/tags` → **CFUG Demo**.

```bash
wheels test
```

**See:** **46 passed**.

**Why it matters.** The generated `CLAUDE.md` and `AGENTS.md` from Beat 1,
the `/wheels/ai` JSON docs, and the MCP server together mean an AI agent
working in this codebase gets *Wheels' conventions*, not its guess at them.
And the tests are the check on whatever it changes.

---

## If it goes sideways

| symptom | do this |
|---|---|
| `wheels start` says port in use | It already picked the next free shutdown port; read the line it printed. If 8080 itself is taken: `lsof -nP -iTCP:8080` and stop that process. |
| A page 500s after an edit | `wheels reload`. Lucee caches compiled templates. |
| Validation edit "didn't take" | You edited the model but didn't reload. `wheels reload`, refresh. |
| `wheels test` fails after Beat 5 | You left `authorize(post);` in. Remove it, reload. |
| Browser looks unstyled | Hard-refresh (⌘⇧R). |
| A seed count differs from this card | `created + skipped` should equal the number of `seedOnce` blocks. If it does, you're fine — say the real number. |
| Comments don't appear on `/posts/N` | Check `Posts.cfc` `show()` has `include="comments"`. If not, add it and reload. |
| Something you can't diagnose in 20 s | Say "that's one for the Q&A," move to the next beat. Every beat stands alone after Beat 2. |

---

## The one-line takeaways, in order

1. **New:** a full app, docs included, from one command.
2. **Scaffold:** one declaration → migration + model + validation, in sync.
3. **Own it:** add a rule in one line; the form enforces it.
4. **Associations:** scaffolding the child wires the parent. Both sides.
5. **Auth:** bcrypt done right, once. **Policy:** default-deny, explicit.
6. **Tests:** generated with everything; caught a real break in seconds.
7. **API:** same models, same rules, one command.
8. **AI:** conventions the agent can read, tests that check what it did.
