# Rails-Style CFML — building a blog live with Wheels 4.1

Peter Amiri · Mid-Michigan CFUG · September 15, 2026 · 7:00 PM ET

This is the speaker outline for the **25-slide PowerPoint**
[`wheels-rails-style-cfml-mmcfug-2026-09-15.pptx`](wheels-rails-style-cfml-mmcfug-2026-09-15.pptx).
Slide numbers below match that file. It replaces the earlier 23-slide,
five-part outline, which described a different demo.

The current executable sequence is [`runbook.md`](runbook.md): eight live beats
on slides 13–20, approximately 50 minutes, after roughly 25 minutes of context.
Use its separately copyable commands, unique app name and explicit port;
[`demo.md`](demo.md) preserves earlier rehearsal history and optional follow-ups.
The PowerPoint still needs the edits in
[`slide-corrections.md`](slide-corrections.md); these Markdown changes do
not rewrite its slide text or speaker notes.

Use the actual CLI/app build shown during rehearsal. Do not infer a release
date or shipped status from “4.1” in the title or from a snapshot version.

---

## Slide 1 — Rails-Style CFML

**Building a blog live with Wheels 4.1 — no CommandBox, no configuration ceremony.**

> Notes: Thank Rick and MMCFUG. Set the evening's shape: context, eight live
> beats, then Q&A. “No configuration ceremony” is more accurate than “no
> config files”: the demo has intentional model, layout, policy and spec
> edits. There is no requirement to use a particular IDE.

## Slide 2 — Who's talking

- CTO at PAI Industries; Wheels used in a real production business.
- Wheels maintainer and long-time CFML developer.
- Tonight's promise: commands the audience can repeat, with fallbacks identified.

> Notes: Keep this to 90 seconds. The credibility is production use, not a
> promise that every feature or engine was tested in tonight's rehearsal.

## Slide 3 — Three quick show-of-hands

1. Still have a CFML app in production?
2. Tried CFWheels before?
3. Seen the original Rails blog video?

> Notes: Wait for hands. Rick's Rails story is the bridge: conventions and
> generators, applied to the language this room already knows.

## Slide 4 — The 200 lines you've written forty times

CRUD, validation, routing, parameterized queries, login, tests.
None of those repeated plumbing tasks is the business logic.

> Notes: Name the pain, then move. A framework makes the repetitive parts
> consistent; it does not remove the need for application security review.

## Slide 5 — Twenty years of Wheels

Rails inspiration → CFWheels → the Wheels rebrand → modern first-party tooling.

> Notes: Preserve the historical arc in the PowerPoint. Recheck the dated
> release claim before presenting; do not repeat “shipped September 10”
> merely because it is printed on the current binary slide.

## Slide 6 — What Wheels is

**An MVC web framework for CFML, built on conventions.**

ORM, migrations, query builder, routing, validation, auth, policies, tests,
CLI and MCP. Multiple CFML engines and databases; the live demo uses Lucee
and SQLite.

> Notes: Other engines matter to this room, but this local demonstration
> does not verify the current cross-engine test matrix. Keep support and
> coverage claims tied to current project documentation.

## Slide 7 — Convention over configuration

`Post` → `posts` → `Posts.cfc` → `app/views/posts/` → named routes.

```cfm
component extends="Model" {
    function config() {
        hasMany("comments");
        validatesPresenceOf("title,body,publishedAt");
    }
}
```

> Notes: Singular model, plural controller/table. You can override the
> conventions, but the live build won't need foreign-key configuration.

## Slide 8 — One request, end to end

Browser → router → controller → model → view/layout → response.

```cfm
post = model("Post").findByKey(params.key);
```

> Notes: Walk left to right once. A static route/view need not have custom
> controller or model logic. The scaffold supplies real files once we do.

## Slide 9 — Your code and the framework never mix

- `app/`: your models, controllers, views, policies and migrations.
- `config/`: routes and settings.
- `public/`: web root.
- `tests/specs/`: app tests.
- `vendor/wheels/`: framework.

> Notes: Updating a CLI installation and updating an existing app's
> framework are different operations. Record both versions in rehearsal.

## Slide 10 — The model layer in one screen

```cfm
model("Post").findAll(order="publishedAt DESC", include="comments");
model("Post").where("title", "LIKE", "%Wheels%")
    .orderBy("publishedAt", "DESC").get();
```

Finders, associations, validation/callbacks and migrations.

> Notes: These query-builder overloads bind values. Do not promise “you
> cannot accidentally write SQL injection”: raw SQL expressions still need
> care. Use straight quotes in code, not typographic quotes copied from slides.

## Slide 11 — The CLI: one binary, no CommandBox

```bash
brew tap wheels-dev/wheels
brew install wheels
# Or choose the bleeding-edge formula: brew install wheels-be
```

Java 21. Homebrew/Scoop and native Linux distribution options.
`new · generate · migrate · seed · test · console · deploy · mcp`

> Notes: Use the chosen installed channel consistently. Show the build
> that actually ran; do not install a second formula on stage to resolve
> uncertainty about what the first one contains.

## Slide 12 — The next 50 minutes

- Posts: full CRUD and validation.
- Comments: belongsTo/hasMany and visible relationships.
- Users: bcrypt passwords and sessions.
- Policies: explicit authorization, default-deny.
- Tests: first-run green, deliberate red, restored green.
- API and agent tooling.

> Notes: Name the target. The exact steps and safety checks are in demo.md.
> Switch to the terminal; slides 13–20 are prompts, not a different script.

---

## Slide 13 — Beat 1: a running app in one command

```bash
wheels new blogdemo
cd blogdemo
wheels start
```

Point at **The details** list on the starter page.

> Notes: First boot downloads are not a reason to start a second server.
> Use the printed URL; default port 8080 was verified in the rehearsal.

## Slide 14 — Beat 2: scaffold a Post

```bash
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime --dry-run
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime
wheels migrate latest
wheels seed --generate
wheels reload
wheels routes
```

Ten Posts with dates, then browser create/edit/delete.

> Notes: Dry-run first, full command second. Preserve seeded Post IDs 1–10
> for the Comment seed. Create and retain **Hello, Wheels** for the later
> search; demonstrate deletion on a separate throwaway. `seed --generate`
> adds data; it is not the idempotent two-Post fallback.

## Slide 15 — Beat 3: it wrote files; you own them

Keep the generated presence and maximum-length rules. Add:

```cfm
validatesExclusionOf(property="title", list="Untitled");
hasMany(name="comments");
```

Reload; show empty-form errors and a rejected `Untitled` title.

> Notes: These are the new hand edits, not the presence rule. Use all-named
> arguments when specifying options. No title uniqueness in this demo:
> generated titles repeat. No cascade deletion is configured by this hasMany.

## Slide 16 — Beat 4: associations and a REPL

```bash
wheels generate scaffold Comment body:text --belongsTo=post
wheels migrate latest
wheels seed --generate
wheels reload
wheels console
```

```cfm
model("Post").findByKey(1).comments()
model("Comment").findByKey(3).post().title
model("Post").where("title", "LIKE", "%Wheels%").orderBy("publishedAt", "DESC").get()
```

> Notes: Each console expression is one stateless request. Expect **Post
> Title 3**, not the older **Test Title 3**. The second seed adds Posts too.
> The flag reuses our inverse and wires the parent finder/view plus the
> child Post dropdown. Show a blank-body error, then a valid Comment on its
> parent. Select the intended Post explicitly; the add link is not nested.
> Type `/exit` to leave the console before the next CLI command.

## Slide 17 — Beat 5: authentication and authorization

```bash
wheels generate auth --strategy=session
wheels migrate latest
wheels reload
wheels generate policy Post
```

**bcrypt → `passwordHash`**, using `bcryptHash`, `bcryptVerify`,
`bcryptNeedsRehash`. Register, logout, wrong login, correct login.

> Notes: Follow runbook.md's layout edit and five-step policy arc: unused
> deny-all policy; one-action gate; all-action filter; readers read/members
> write/admins delete; login proves member edits but denies deletion. No role
> column/admin promotion is staged. A missing record's 404 versus an existing
> denied record's 403 reveals existence; it is not anti-enumeration. Remove
> ONLY the demo authorizePost filter/helper before unauthenticated CRUD specs;
> retain requireRecord, Comments eager loading, auth and CSRF. Password minimum
> is 12 characters; show the bcrypt shape, not a real user's password.

## Slide 18 — Beat 6: red, green

```bash
wheels test
```

Add a Post body-presence example; remove only body from the validation to
show red; restore and show green.

> Notes: A **fresh first run** must pass. Current generated Comment
> controller specs create their parent; do not retain the old off-screen
> warm-up instruction that masks missing fixtures. Use actual totals, not
> fixed 27/28 claims. Reload after model edits and verify test-app state.

## Slide 19 — Beat 7: the two-minute tour

```bash
wheels info
wheels migrate diff
wheels coverage --top=5
wheels generate api-resource Product name price:decimal sku:string
wheels migrate latest
wheels reload
```

```bash
curl -i -X POST http://localhost:8080/api/products \
  -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Drum","price":149.99,"sku":"DRUM-001"}}'
curl -i http://localhost:8080/api/products
```

> Notes: Substitute the actual port. SKU is required: without it the
> response is 422, not 201. A successful POST returns 201; list returns 200.
> `/api` is a namespace, not versioning. Verify diff/coverage and the suite
> after API generation during rehearsal; don't claim success from old notes.

## Slide 20 — Beat 8: Wheels and Harness add Tags to Posts

```bash
wheels setup agents
```

1. Write/merge `.mcp.json` and `.opencode.json` in the **demo app**.
2. Open Harness there; configure/import the Wheels server if needed, reconnect/
   reload tools and verify actual discovery against this app's routes.
3. Paste [harness-tags-prompt.md](harness-tags-prompt.md): **implement**, not plan.
4. Show **Post↔Tags**, not disconnected Tags CRUD: multi-select, edit, clear all,
   re-add, validation preservation, saved names on list/show, Tags management.
5. Verify migration round-trips, repeat-safe seeds, app tests and browser behavior.

> Notes: Setup writes configuration; it does not install Harness or automatically
> enable MCP. The client launches `wheels mcp wheels`; the stdio process is not a
> REPL. Inspect the real advertised tools/schemas instead of promising a count.
> Disclose CLI fallback if MCP is unavailable. Preserve Comments, auth, CSRF,
> styling and the current public Post CRUD after the temporary policy gate was
> removed; no vendor changes or unrequested admin role. On 2026-09-15 build 2500,
> the exact prompt passed **36 → 97 specs**, repeat seeds and independent browser/
> database review via CLI fallback. This is Lucee/SQLite, with a SQLite-specific
> join migration—not cross-database or native Harness GUI MCP proof. Invalid CSRF
> blocks mutation but returns existing development-mode 500, not 403. Report the
> current result rather than promising a fixed future count or the old Tag's 46.
> One later Post GET returned an unexplained missing-WO 500; three test/HTTP replay
> cycles passed but did not establish a fix. Disclose the runbook's stability caveat.
> Rehearse implementation beforehand if it exceeds five minutes, and disclose a
> prepared result. Current commands/evidence are in runbook.md; old build-2482/
> 2488 and local-patch history remains in demo.md. A green scaffold suite or HTTP
> 200 alone is not proof of persisted assignment.

---

## Slide 21 — What we just built

Posts · Comments · Users · Policies · Tests · JSON API.

**Convention over configuration — but you own every line it generates.**

> Notes: Recap the actual result. Acknowledge any cut or fallback. Do not
> call the API versioned or insist on a fixed command/function count.

## Slide 22 — Also in the box

Security middleware, SSE, background jobs, storage, multi-tenancy, deploy,
dev tooling and packages.

> Notes: Read the headings, not an implementation guide. An optional
> route-binding follow-up is in demo.md; it keeps the related-comments
> array explicit with `returnAs="objects"`.

## Slide 23 — How do I move my existing app to it?

Run beside the legacy app; move one route at a time; map existing tables;
choose the engine deliberately.

> Notes: This is not a rewrite pitch. Keep engine, benchmark and release
> claims tied to current evidence, not a hard-coded slide-note number.

## Slide 24 — Try it tonight

```bash
wheels new myapp
cd myapp
wheels start
```

- [wheels.dev](https://wheels.dev)
- [guides.wheels.dev](https://guides.wheels.dev)
- [github.com/wheels-dev/wheels](https://github.com/wheels-dev/wheels)

> Notes: Java 21; install the chosen CLI channel first. First boot may
> download dependencies, so don't guarantee a 60-second result on venue Wi-Fi.

## Slide 25 — Questions

Thank Rick and Mid-Michigan CFUG. Invite people to build something and file
issues with reproducible examples. Intermediate follow-up: agent-driven
maintenance, MCP and multi-engine CI.
