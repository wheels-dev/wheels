# Demo runbook — Rails-Style CFML

Build a blog live with Wheels 4.1. This script follows the **eight demo beats
on slides 13–20** of
[`wheels-rails-style-cfml-mmcfug-2026-09-15.pptx`](wheels-rails-style-cfml-mmcfug-2026-09-15.pptx).
[`deck.md`](deck.md) is the matching speaker outline;
[`slide-corrections.md`](slide-corrections.md) lists edits still needed in the
PowerPoint itself. Editing Markdown does **not** update the binary slides.

Budget roughly 25 minutes of context, 50 minutes of live build, then Q&A.
The individual slide budgets total about 52 minutes; trim the optional tour,
not the association or first-run test checks. Route model binding is a
separate optional follow-up, not a replacement for one of the eight beats.

## Before opening the room

- Use Java 21 and the same Wheels installation for rehearsal and the talk.
  Record `wheels --version`, then the generated app's framework version from
  the starter page / `wheels info`. Updating the CLI does not update an
  existing app's `vendor/wheels`.
- Start in a fresh, disposable demo directory. Warm the engine/JDBC downloads
  beforehand, but do not reuse a previously populated test database to hide
  first-run failures.
- Keep a second, already-rehearsed app as a fallback, with its own server
  registration. Do not delete a running app to reset it.
- Have a terminal editor ready. “No configuration ceremony” does not mean
  “no file edits”: the demo deliberately edits models, a policy and a spec.
- Set `TALK_ASSETS` to the absolute presentation directory **before** changing
  into the demo app if you want the optional prepared seed fallback:
  ```bash
  export TALK_ASSETS="/absolute/path/to/wheels/docs/presentations/cfug-2026-09-15"
  ```
- Keep the actual server URL handy. The clean Homebrew rehearsal used
  `http://localhost:8080`; use the printed URL if yours differs.
- Verify release status separately before making a shipped-date claim. A
  snapshot build number is not evidence of a release announcement.

### Recorded rehearsal evidence

The September 12 rehearsal used Homebrew build **2482** for both the CLI and
new app's framework. Confirmed checkpoints: default start on port 8080;
Post and Comment migrations down/up; initial generated seed of 10 Posts;
second generated seed of 20 records; zero orphan Comments with Post IDs
1–10 intact; browser Post dropdown; both association directions in the REPL;
and the parent title **`Post Title 3`**. Browser CRUD, validation and Comment
reassignment between Posts also passed. Auth's migration round-trip,
registration/login/logout, bcrypt storage (`$2a$10$`, 60 characters), and
policy 403/200 passed after adding the logout UI described below. The fresh
first test run was **27 green**, then **28 green → 27 passed / 1 failed →
28 green** through the body-validation exercise. `wheels info`,
`wheels migrate diff` (no differences), and `wheels coverage --top=5` passed.
Product migration round-trip and API checks passed: missing SKU 422,
complete POST 201, list 200, PATCH 200 / invalid PATCH 422, missing record
404, DELETE 204 followed by 404. The first suite after API addition passed
**36/36**. Offline Guides and API documentation returned 200 in the browser;
debug-bar timing, params, routes and complexity panels opened.

**Installed build 2482: MCP/data failures, not a completed data loop.**
MCP initialize/tools-list returned **19 tools**; Tag commands returned
success, `/tags` returned 200, and the suite passed **44/44**. The final
audit found two independent problems:

- MCP `generate` **ignored its advertised `attributes`**: Tag's config was
  empty and its migration had only ID/timestamps, not name/slug. The green
  specs were testing the wrong generated shape.
- All-model generated seeding after auth reported **30 created, 2 skipped**
  but committed no new Tag/Product rows. The Tag page was empty. Product
  also had a decimal-sample limitation; removing that skip alone did not
  prove persistence.

The separately successful explicit Product API requests and pre-auth
Post/Comment seed checks remain valid. Use positional CLI generation and
convention seeding for the fallback below, or verify corrected local code;
**do not imply that these later corrections are in the installed build**.

**Independent convention-seed rehearsal:** in a fresh app, the Post-only
seed produced **2 created / 0 skipped**, then **0 / 2**. The two parent IDs
were deliberately changed to **41 and 97** before adding any children.
After the Comment migration, the parent-and-child seed produced **2 / 2**,
then **0 / 4**. The actual database held two Posts and two Comments linked
to 41/97, with **zero orphans**; the suite passed **20/20**. Repeat safety
was also checked on the earlier prepopulated app.

**Separate local correction/fallback evidence:** rebuilding the empty Tag
with positional CLI attributes gave the intended name/slug schema. The
convention Tag seed below committed `CFUG Demo` / `cfug-demo`, repeated
without adding a Tag, and displayed it in the browser. The correctly
shaped app then passed **46/46**, rather than the empty-Tag run's 44.
Applying the three local Seeder corrections separately produced durable
counts **Posts 29→39, Comments 13→23, Products 2→12, Tags 1→11, Users 1→1**,
with zero orphans and zero nonnumeric prices. The 46-spec suite left those
development counts unchanged. That is local-patch evidence, not a
recharacterization of the failed Homebrew baseline.

**Patched CLI / real stdio MCP proof:** local CLI commit `193563241` passed
its strict suite with **1359 passed, 0 failed, 0 errors**. A separate
isolated MCP client loaded that module while a normal Homebrew-started
server served the recipe app on port 8096; server-registry/cache paths were
aligned for reload and test discovery. The actual protocol returned 19
tools and accepted reordered `attributes`, `name`, `type` keys. Generated
Tag source and real SQLite schema both contained name/slug. MCP migration
round-trip, convention seed **1 created / 4 skipped**, repeat **0 / 5**,
and `/tags` **200 with CFUG Demo / cfug-demo** all passed. SQLite durably
held **2 Posts, 2 Comments, 1 Tag**; MCP `test` passed **30/30** without
changing those live counts. This verifies the locally patched CLI, **not a
global Homebrew upgrade or the original installed MCP implementation**.

> **Reading a convention-seed count.** `created + skipped` always equals the
> number of `seedOnce` blocks in `app/db/seeds.cfm`; each block lands in
> `created` or `skipped` depending on whether its row already exists. The
> `1/4` → `0/5` above is a **five-block file** — the four prepared
> Post/Comment blocks from `seeds-with-comments.cfm` (all already present by
> then) plus the Tag block. Following the main track instead, `app/db/seeds.cfm`
> holds **only** the Tag block, so the same two runs report **`1 created / 0
> skipped`** then **`0 / 1`**. Both are correct. A repeat run that reports
> anything other than `0 created / <block count> skipped` is the actual bug.

The optional binding check reproduced the plain-bound Post's missing
Comments and the query-to-array error from the old workaround. Explicit
`returnAs="objects"` restored HTTP 200 with Comments; browser Post
create/edit/delete/validation passed, and a missing bound key returned
404. With the direct-controller show fixture supplied as described below,
the suite passed **44/44** again.

These checks do not establish that arbitrary existing databases are safe
to auto-seed. Remaining checkpoints below must be verified on the
presentation machine; old slide notes marked “VERIFIED” are not a
substitute for this rehearsal.

---

## Beat 1 — a running app (slide 13, ≈4 min)

From your chosen demo workspace:

```bash
wheels new blogdemo
cd blogdemo
wheels start
```

Open the printed URL. Point at the Wheels wordmark, **The details** list
(version, engine, datasource, environment), and the Guides/API docs cards.
The old “Your Wheels … application is running …” sentence is no longer the
starter page's layout.

**Say:** “No CommandBox, no datasource in the administrator. SQLite is the
default, so the app has a working database before we've written a line.”

Show the directory layout: your code in `app/`, framework in `vendor/wheels/`,
web root in `public/`, and the generated `CLAUDE.md` / `AGENTS.md`.

First JVM boot can take time. Do not repeatedly run `wheels start` while it
is starting. For a confirmed stale registration at another path, use
`wheels start --force`; for a port collision, select a free port with
`wheels start --port=8090` and update subsequent URLs.

## Beat 2 — scaffold, migrate, seed, CRUD (slide 14, ≈8 min)

```bash
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime --dry-run
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime
wheels migrate latest
wheels seed --generate
wheels reload
wheels routes
```

Pause after the dry-run: inspect the plan and confirm it did not create the
Post model, migration or views. Quote brace-bearing arguments so the shell
passes them literally. Then run the full command, not the slide's ellipsis.

Point at the generated model, controller, migration, views, specs and
`.resources("posts")` route. The model already contains presence validation
for **title, body and publishedAt**, plus the title maximum of 50.
`publishedAt` is a real datetime, not a boolean or a string placeholder.

Open `/posts`: on a clean database the first generated seed creates ten
Posts. Show the dates as well as titles. Generated titles include model
context, e.g. **Post Title 3**.

Browser CRUD:

1. Create **Hello, Wheels** with a body and publication date.
2. Edit its body; show the success flash. **Keep this post**: Beat 4 searches
   for `%Wheels%`.
3. Create and delete a separate throwaway post to demonstrate deletion.
   **Do not delete the original Post IDs 1–10** before Comment seeding.

**Say:** “Singular model, plural controller, plural table. I never told it
any of that. One route declaration gives us the REST surface.”

### Two seed modes, not two interchangeable recipes

The main presentation uses `wheels seed --generate`, which generates sample
rows and is **not idempotent**. Every run can add another batch to every
model, not just the newest scaffold. The rehearsed build fills integer FKs
with 1–10; it does not discover the existing parent IDs. A successful seed
exit alone does not prove referential integrity.

The optional [`demo-app/seeds.cfm`](demo-app/seeds.cfm) is a different,
idempotent, two-Post fallback with explicit dates:

```bash
mkdir -p app/db
cp "$TALK_ASSETS/demo-app/seeds.cfm" app/db/seeds.cfm
wheels seed --mode=convention
```

Use that instead of the first generated seed only if you intentionally
switch to the small-data fallback. After the Comment migration, either
create Comments through the form using real Post selections or copy the
standalone parent-and-child seed:

```bash
cp "$TALK_ASSETS/demo-app/seeds-with-comments.cfm" app/db/seeds.cfm
wheels seed --mode=convention
wheels seed --mode=convention
```

That file resolves Posts by title and seeds Comments using their actual
IDs. Check repeat-run counts as described in
[`demo-app/README.md`](demo-app/README.md). **Do not follow two prepared
parents with generated Comments that assume ten parents**. Use actual IDs
in console examples.
Plain `wheels seed` auto-selects convention files when present;
`--generate` bypasses them. There is no `wheels generate seed` command.

## Beat 3 — it wrote files; you own them (slide 15, ≈5 min)

Open `app/models/Post.cfc`. Keep the generated validations and add these
lines inside `config()`:

```cfm
validatesExclusionOf(property="title", list="Untitled", allowBlank=true);
hasMany(name="comments");
```

Then:

```bash
wheels reload
```

Submit an empty Post form to show the generated presence errors. Submit
`Untitled` with the other fields completed to demonstrate the **new**
business rule. Do not pretend to type the presence/length rules that the
scaffold already generated.

**Say:** “The form already knows how to render errors. It's ordinary code
we own, not a black box.”

Do not add title uniqueness for this demo: generated titles repeat on the
second seed. Do not add a body minimum that invalidates the generated
spec fixtures. `hasMany` here does not configure cascading deletion.

## Beat 4 — associations and a REPL (slide 16, ≈5 min)

```bash
wheels generate scaffold Comment body:text --belongsTo=post
wheels migrate latest
wheels seed --generate
wheels reload
```

Inspect what the association flag actually produced:

| File | Expected shape |
|---|---|
| Comment migration | `post_id` integer column in a stock new app |
| `app/models/Comment.cfc` | `belongsTo("post")`, presence of `body,post_id` |
| `app/models/Post.cfc` | one `hasMany("comments")`, reusing Beat 3's declaration |
| `app/controllers/Comments.cfc` | eager-loads `post` in its finders |
| `app/controllers/Posts.cfc` | `show()` eager-loads `comments` |
| `app/views/posts/show.cfm` | related-comments block |
| Comment form | Post dropdown labelled with Post titles, not raw IDs |

The generator preserves custom parent code and reports skipped wiring;
read those messages rather than assuming every parent edit happened.
Do not replace the generated Comment config with an old snippet requiring
`author`—this scaffold has no author column. Body and FK presence are
already generated.

The second generated seed adds **10 Comments and another 10 Posts** on the
rehearsed clean track, not just Comments. Keep the original parents intact.
Before the talk verify every Comment's `post_id` points at a live Post;
opening one successful association is not an orphan audit.

Open `/posts/1`, follow **Add a comment**, and choose the intended Post in
the dropdown—the link is flat and does not preselect its parent. Show a
blank-body error, then create a valid Comment and return to the Post to see
it listed.

```bash
wheels console
```

Enter each complete expression separately (each is a stateless request):

```cfm
model("Post").findByKey(1).comments()
model("Comment").findByKey(3).post().title
model("Post").where("title", "LIKE", "%Wheels%").orderBy("publishedAt", "DESC").get()
```

Expected on the preserved clean track: a related-comment query, **Post
Title 3**, and the retained **Hello, Wheels** post. Row counts can grow if
you added a Comment in the browser. Type **`/exit`** to leave the console
before the next CLI command.

**Say:** “The flag adds the foreign key and wires both sides. Naming is the
configuration. These two-/three-argument query-builder calls bind values;
raw SQL expressions are still the developer's responsibility.”

## Beat 5 — authentication and authorization (slide 17, ≈10 min)

```bash
wheels generate auth --strategy=session
wheels migrate latest
wheels reload
```

Open the generated User model and migration. The storage column is
**`passwordHash`**. The current generator calls **`bcryptHash()` /
`bcryptVerify()` / `bcryptNeedsRehash()`**; it does not generate PBKDF2 into
`passwordDigest`. The JVM implementation bundles jBCrypt.

**Add the navigation before promising a browser logout.** The auth
generator does not insert a logout control into the app layout. In
`app/views/layout.cfm`, add this inside the existing `cfoutput`, before
`flashMessages()` in **both** the content-only and full-page branches:

```cfm
<nav aria-label="Demo navigation">
    #linkTo(route="posts", text="Posts")#
    #linkTo(route="login", text="Log in")#
    #buttonTo(route="logout", method="delete", text="Log out")#
</nav>
```

Use the generated button helper, not a GET link, so logout uses the
expected method and CSRF form handling. This is deliberately simple demo
navigation, not a finished conditional account menu. Reload.

Browser sequence: `/register` → logout button → `/login` with a wrong
password → login with the correct one. Use a disposable demo account, a
password of at least 12 characters, and matching confirmation. Rehearsal
flashes: **Welcome!**, **You have been logged out.**, **Invalid email or
password.**, **Welcome back.** Verify that the stored hash is bcrypt
(normally `$2a$10$…`, 60 characters for this generator), not plaintext.
Do not put a real password in a projected console command.

```bash
wheels generate policy Post
wheels reload
```

Run this as a five-step arc, one edit and one reload per step, checking
`/posts`, `/posts/1` and `/posts/new` after each. Stay logged out for steps
1–4. Every status below was measured on a stock app at build 2490.

1. **Policy exists, nothing enforces it.** All three routes still **200**.
   The generated policy denies every action, but a policy is only consulted
   where a controller calls `authorize()`. Generating the file changes
   nothing on its own — by design.
2. **Gate one action.** Add `authorize(post);` to `Posts.show()` after the
   finder (keep `include="comments"`). `/posts` **200** · `/posts/1` **403**
   · `/posts/new` **200**.
3. **Gate every action.** Remove that line; add
   `filters(through="authorizePost");` to `config()` and a
   `private function authorizePost() { authorize(model("Post")); }`.
   `authorize()` accepts the model class and defaults the action to
   `params.action`, so one filter dispatches to `index()`/`show()`/`new()`.
   All three **403**. `/posts/99999` stays **404** because the scaffold's
   `requireRecord` filter is declared first — nonexistent records 404 before
   the policy is consulted, so 403-vs-404 cannot be used to probe IDs.
4. **Open one door for everyone.** `index()` → `return true;`. `/posts`
   **200**, the other two still **403**.
5. **Open one door for logged-in users.** `show()` →
   `return IsStruct(variables.user) && !StructIsEmpty(variables.user);`.
   Logged out `/posts/1` **403**; log in → **200**; `/posts/new` still
   **403**.

**Say:** “Default-deny at the policy, opt-in at the controller. One line
gates one action; one filter gates them all. The generated login code
handles password hashing instead of asking us to invent it.”

**Before Beat 6, remove the `authorizePost` filter and its private method,
then reload.** The scaffold's CRUD specs are not logged in. Keep the policy
file; do not present the unauthenticated CRUD test failure as a framework
failure.

## Beat 6 — red, green (slide 18, ≈8 min)

```bash
wheels test
```

This must pass on a **fresh test database**, not only on a second run.
Inspect `tests/specs/controllers/CommentsControllerSpec.cfc`: the current
generator creates a Post in `beforeEach` with `save(validate=false)` and
uses that Post's ID. An older spec that hard-codes `post_id=1` can fail
show/edit/update/delete on the first run. Do not hide it with the old
slide-note instruction to run a failing test off-screen.

Add this example inside the existing `describe` in
`tests/specs/models/PostSpec.cfc`:

```cfm
it("requires a body", () => {
    var post = model("Post").new(title="No body here", publishedAt=Now());
    expect(post.valid()).toBeFalse();
    expect(post.errorsOn("body")).notToBeEmpty();
});
```

Run green. Temporarily remove **only `body`** from Post's combined
`validatesPresenceOf(...)`, reload, and run again: the new spec should be
red. Restore `body`, reload, and confirm green. Report the actual totals;
the rehearsal sequence was **27 green → 28 green → 27 passed / 1 failed →
28 green**.

If an edit is not visible, investigate the live/test application reload
boundary instead of claiming the rule worked. Do not continue to the API
beat until the model is restored and the suite is green.

## Beat 7 — the two-minute tour (slide 19, ≈7 min)

```bash
wheels info
wheels migrate diff
wheels coverage --top=5
wheels generate api-resource Product name price:decimal sku:string
wheels migrate latest
wheels reload
```

Rehearse `migrate diff` and coverage on the actual installed build; use the
observed output, not an old snapshot's “shipping polish” warning or an
unverified “no differences” claim. Coverage runs tests, so allow time.
Point at the browser debug bar's timing, params, queries and complexity.

Set the URL to the server you actually started:

```bash
export DEMO_URL=http://localhost:8080
curl -i -X POST "$DEMO_URL/api/products" \
  -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Drum","price":149.99,"sku":"DRUM-001"}}'
curl -i "$DEMO_URL/api/products"
```

The successful request includes **SKU** because it is required by the
generated model. Expect **201**, then **200** for the list. The old slide's
name/price-only payload should return **422**; optionally show that first,
then correct it. Read the response body as well as the status.

An `/api` namespace is not API versioning. Do not claim a versioned API
unless you explicitly add and demonstrate versioned routes. Run
`wheels test` after API generation during rehearsal: build 2482 passed
**36/36 on the first run**, so the old slide-note instruction to avoid
that run because of stale test routes no longer describes this rehearsal.
Also verify update, invalid update, missing record and delete responses;
these passed with 200, 422, 404 and 204 respectively.

Name, don't implement: middleware, SSE, jobs, local/S3 storage, multi-tenancy
and deploy. This is the first beat to shorten if the evening runs long.

## Beat 8 — Wheels and AI coding agents (slide 20, ≈5 min)

Show the stdio MCP entry point:

```bash
wheels mcp wheels
```

This starts a protocol server, not an interactive REPL; let the MCP client
launch it, or stop it before returning to normal terminal commands. The
module name is required. Show `.mcp.json` for the **demo app**, not the
framework repository:

```json
{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}
```

Verify `initialize` and `tools/list` with the configured client. The
rehearsal returned **19 tools**; show the actual list rather than assuming
that count on another build. Optional agent loop: generate a Tag with
`name:string{30} slug:string`, **inspect the generated fields**, migrate,
reload, create valid sample data, and visit `/tags`.

**On installed build 2482, use positional CLI generation for this step:**

```bash
wheels generate scaffold Tag 'name:string{30}' slug:string
```

The baseline MCP call accepted `attributes` but silently generated an
empty Tag. Before migrating, inspect `app/models/Tag.cfc` for name/slug
presence and the name maximum of 30, and inspect its migration for both
columns. With a corrected MCP implementation, repeat the same inspection
and include a request with reordered JSON keys. A successful response is
not evidence that the requested fields were generated. If the empty Tag
migration was already applied, use the prepared fallback app or reconcile
that disposable migration deliberately; don't stack a second create-table
migration or assume `--force` replaces an already-applied schema.

**Do not use the installed build's after-auth generated seed on stage.**
It reported **30 created, 2 skipped**, but committed no new Tag/Product
rows. Use the explicit convention alternative below. Local Seeder fixes
were verified separately with durable counts, but must be present in the
actual app before demonstrating the repaired all-model generated path.

After migrating the **correct name/slug schema**, add this block to
`app/db/seeds.cfm` (create the file if absent; preserve existing blocks).
This fallback was verified after positional CLI generation and through the
separately patched stdio MCP client. It is not a claim that the original
installed MCP generated-data loop passed:

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
wheels console
```

In the new console request, check the specific persisted row:

```cfm
model("Tag").findOne(where="slug = 'cfug-demo'")
```

Type `/exit`, then load `/tags` and confirm **CFUG Demo** is visible. Check
that the second seed added zero Tags. If using the MCP client to run the
seed, select its convention mode explicitly. This avoids autogenerated
User/Product records; do not switch back to all-model generated seeding
until its persistence is independently verified.

> **Expected counts on the main track:** the first run reports **`1 created /
> 0 skipped`** and the repeat **`0 / 1`** — one `seedOnce` block in the file,
> so the two numbers always sum to one. (The recorded `1/4` → `0/5` in the
> rehearsal evidence came from a five-block `seeds.cfm`, i.e. the prepared
> Post/Comment fallback plus Tag. See the note above.)

**Say:** “The agent can ask the running project, not just its memory of a
framework. The generated AI docs and the error page's Copy button give it
context. Tests remain the check on what it changes.”

Return to slides 21–25. Recap only what actually ran; acknowledge any cuts.

---

## Optional follow-up — route model binding

Do this after the eight-beat rehearsal, or trade it for part of the tour.
Edit **only the existing posts resource declaration**, preserving auth,
API, root and other routes:

```cfm
.resources(name="posts", binding=true)
```

In `Posts.show()`, use the bound Post and explicitly request the collection
shape expected by the generated related block:

```cfm
function show() {
    post = params.post;
    post.comments = model("Comment").findAll(
        where="post_id=#post.id#",
        returnAs="objects"
    );
}
```

`params.post` does not have the old finder's `include="comments"` data.
A plain `findAll()` or lazy `post.comments()` returns a **query**, but the
generated block uses `ArrayLen` and an array loop: **keep
`returnAs="objects"`**. The example uses the stock app's `post_id`; use the
actual column if your app uses a different convention.

Reload, then check an existing Post **with its comments still visible**,
a nonexistent key's HTTP **404**, and create/edit/update/delete behavior.
Binding on a resource affects more than `show()`, so a single successful
GET is not a complete regression check.

### Update the direct-controller show spec too

The generated `processRequest` call with explicit controller/action invokes
the controller **without the dispatcher**. It does not populate route-bound
models. After changing `show()` to use `params.post`, supply that action's
input in the existing “renders the show page” example in
`tests/specs/controllers/PostsControllerSpec.cfc`:

```cfm
var result = processRequest(
    params = {
        controller = "Posts",
        action = "show",
        key = variables.post.id,
        post = variables.post
    },
    method = "get",
    returnAs = "struct"
);
expect(result.status).toBe(200);
```

Use the Post already created by the spec's `beforeEach`. This is an
explicit **controller-unit-test fixture**, not evidence that routing loaded
it. Keep the separate real HTTP existing-key / missing-key checks. Without
this fixture the rehearsal correctly failed the direct-controller show
example (`params.POST` missing); with it the full suite returned **44/44**.
No framework change is needed to make a direct-controller helper run the
dispatcher.

Restore the original route/finder and corresponding spec if this was only
a demonstration. `bindBy="slug"` is a talking point unless you also add and
populate the slug column; this schema does not have one.

## Rehearsal completion checklist

- [ ] Record CLI and app framework build, Java, engine, URL and database.
- [ ] Dry-run writes nothing; Post/Comment migrations work up/down/up before seeding.
- [ ] First seed: ten Posts with valid dates; retain IDs 1–10 and Hello, Wheels.
- [ ] Second seed: expected per-model counts and zero orphan Comments.
- [ ] Parent related list, readable dropdown, blank/valid Comment submissions, both REPL directions.
- [ ] Register/logout/wrong-password/right-password; bcrypt stored in passwordHash.
- [ ] Policy 403/200; remove temporary authorization before CRUD specs.
- [ ] Fresh first test run; intentional red; restored green with actual totals.
- [ ] Info/diff/coverage; API 422/201/200; new API specs discover current routes.
- [ ] MCP initialize/tools/list in the intended project; optional Tag loop has committed rows visible in a new request, not only successful commands.
- [ ] Binding existing/missing key, related collection, and CRUD regression checks.
- [ ] Rehearse the optional convention seed separately, including repeat-run idempotency.
- [ ] Update the binary slides using slide-corrections.md; inspect slide show and notes.

## If it goes sideways

| Symptom | Check / recovery |
|---|---|
| First boot takes time | Wait for engine/JDBC downloads; don't stack start commands. |
| Port collision / stale registration | Check the owning process/project; use a free port or confirmed stale-registration `--force`. |
| Seed cannot connect | Run the server for this project; verify its configured URL and reload credentials. |
| Two-post fallback rejects publishedAt | Use the dated reference seed, not the old title/body-only file. |
| Comments disappear after seeding | Audit actual FK targets, including soft-deleted Posts; don't assume 1–10 still exist. |
| Parent UI was not generated | Read scaffold skipped-wiring messages; preserve custom files and wire deliberately. |
| Edit seems ignored | `wheels reload`; a browser reload needs `?reload=true&password=<WHEELS_RELOAD_PASSWORD>` from `.env`. Never project the secret. |
| First test fails, second passes | Inspect parent fixtures and test-app state; do not use warm-up as a fix. |
| Missing SKU API request returns 422 | That's validation working; include sku for the success request. |
| After-auth seed reports created rows but Tag page is empty | Audit committed counts in a new request; use explicit convention seeds or a persistence-verified fix, not the success summary. |
| Need a clean reset | Stop the disposable app, preserve it under a new name, and create a fresh app. Do not delete unrelated data. |
