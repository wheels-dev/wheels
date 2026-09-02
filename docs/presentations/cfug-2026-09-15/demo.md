# Demo runbook — "Wheels 4.1: Modern CFML, the Rails Way"

A rehearse-it-end-to-end script for the live build. Everything here is the
real CLI, real code, and real output — practice it twice and the night is
just typing.

This is **Part 2 of a ~60-minute talk** (see [`deck.md`](deck.md)). The live
build is the centerpiece at **~25 minutes**, leisurely; Parts 3–5 (the deeper
feature tour, the 4.1 release story, and the close) are slides and terminal
snippets, not more live typing. In a 1.5-hour meeting that leaves ~30 minutes
for announcements and Q&A.

## Prerequisites

- Wheels CLI 4.x (`wheels --version`) — Homebrew/Scoop/apt. Java 21.
- A clean shell. No prior app state.
- Optional but recommended: run the build once the day before so the Lucee
  server JARs and the SQLite JDBC driver are cached (first boot is the slow one).

> The rehearsal checklist is at the bottom — read it before the talk.

---

## Act 1 — the `wheels new` moment (≈2 min)

```bash
wheels new blog
cd blog
wheels start
```

Open the printed URL. **Point at the status line** on the welcome page:
`Wheels <version> · <engine> · <database> · <environment>`.

**Say:** "That's the whole stack — a running app with zero config. No
`Application.cfc` hand-editing, no wiring, no XML. It's already up."

> Gotcha: `wheels new` may ask for the app name if you omit it; pass it as the
> positional arg as above. If `wheels start` picks a port you don't like,
> stop and restart with `--port`.

---

## Act 2 — scaffold + migrate (≈4 min)

```bash
wheels generate scaffold Post title:string body:text
wheels migrate latest
```

Reload. Create a post, list it, edit it, delete it — all live.

**Open one generated file** (`app/models/Post.cfc`, `app/controllers/PostsController.cfc`)
to make the point that it's **real code you own**, not a black box.

**Say:** "One command produced the model, the migration, the controller, the
views, the tests, and the route. In Rails this is the `generate scaffold`
moment — same idea, same payoff."

> Gotcha: the scaffold also drops a `.resources("posts")` line into
> `config/routes.cfm` automatically. Mention that you didn't touch routing yet.

---

## Act 3 — associations + validation (≈4 min)

```bash
wheels generate scaffold Comment postId:integer author:string body:text
wheels migrate latest
```

Edit **`app/models/Post.cfc`** — add the association in `config()`:

```cfm
component extends="Model" {
    function config() {
        hasMany(name="comments", dependent="delete");
    }
}
```

Edit **`app/models/Comment.cfc`**:

```cfm
component extends="Model" {
    function config() {
        belongsTo(name="post");
        validatesPresenceOf("author,body");
    }
}
```

Show: create a post, add comments, show `post.comments` in the view. Then
submit an empty comment and **let the validation error render**.

**Say:** "No foreign-key config. `belongsTo("post")` figures out `postId` from
the schema. `Post` ↔ `posts`, `Comment` ↔ `comments` — the convention *is*
the configuration."

> Gotcha: if you want nested URLs (`/posts/1/comments`), that's the callback
> syntax in routes — `.resources(name="posts", callback=function(map){ map.resources("comments"); })`.
> Skip it live unless time allows; flat routes keep the demo moving.

---

## Act 4 — the 4.1 "wow" (≈6 min)

### 4a — route model binding

In **`config/routes.cfm`**, change the posts resource:

```cfm
mapper()
    .resources(name="posts", binding=true)
    .resources("comments")
    .wildcard()
.end();
```

In **`app/controllers/PostsController.cfc`**, delete the `findByKey` +
not-found guard from `show()` — with binding, the record is loaded for you
and a missing `:key` returns a 404 before the action runs.

**Say:** "With `binding=true`, the dispatcher loads `params.post` before the
action. No `findByKey`, no `IsObject` guard. And `bindBy="slug"` swaps the
segment to any column for pretty URLs."

### 4b — one-command auth

```bash
wheels generate auth
wheels migrate latest
```

Reload and show registration + login + logout, all generated. **Point at the
`passwordHash` column** and say the magic words: *bcrypt, per-user salt in the
hash, constant-time verify.*

### 4c — the CLI quick hits (30s each, pick two)

```bash
wheels migrate diff          # what would migrations say?
wheels coverage --top=5      # change-risk ranking
```

Plus: the **debug bar** in dev (request timing, params, queries, the new
complexity panel).

---

## Act 5 — close (≈2 min)

One slide, then Q&A:

> **Convention over configuration — but you own every line it generates.**

Point to `guides.wheels.dev`, `blog.wheels.dev` (the 4.1 series), and
`github.com/wheels-dev/wheels`.

**Say:** "Come build something with it — and when it breaks, file the issue.
That's how 4.1 got its security pass: real apps in the wild."

---

## Rehearsal checklist

- [ ] Run the full build once the day before (warms the server + JDBC cache).
- [ ] Time each act; trim Act 4c if you're over 20 minutes.
- [ ] Confirm `wheels generate auth` runs against the **released** 4.1.0 CLI
      (not a checkout) — the demo targets shipped software.
- [ ] Have a fallback if the venue Wi-Fi blocks Maven/CFPM downloads — pre-cache
      by running the build once online beforehand.
- [ ] Keep a clean `blog/` dir in a side terminal; if you fat-finger a step,
      `cd .. && rm -rf blog && wheels new blog` resets you in ~10 seconds.

## If it goes sideways

| Symptom | Fix |
|---|---|
| `wheels start` hangs on first boot | It's downloading engine JARs — wait, or restart. |
| Port already in use | `wheels start --port 8090` |
| Migration says "already applied" | `wheels migrate down` then `wheels migrate latest`, or just roll forward. |
| Auth generator warns about existing `User` | You already have a User model — scaffold used `User`, pick a different model name with `--model=`. |
| Live edit didn't take effect | Hard reload (`?reload=true`) or restart the server — Adobe caches compiled CFCs. |
