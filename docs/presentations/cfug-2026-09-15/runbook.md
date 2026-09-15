# Wheels live demo — presenter's runbook

**For the iPad and the projected terminal.** Follow the numbered steps in order.
Every Bash block contains **one terminal command**; copy it separately. A command
with continuation lines is still one command. Console expressions have their own
blocks; editor snippets name the file and whether to add or replace.

**This is your single document for the demo.** Each beat starts with an **Opening
block** you can read or paraphrase: what we're doing, why, and what the audience
should expect. Follow the numbered steps and their **See / Say** cues. Expand an
**If asked** box only when a question comes up; those are explanation notes, **not
extra commands or required live edits**. The Harness prompt is already embedded
in Beat 8, and the fallback, timing and closing notes are included here too.

**Opening the demo — say:** “We're going from a new folder to a working blog:
Posts, Comments, validation, login and explicit permission rules. Then we'll
prove a test can catch a broken rule, expose the same model style as a JSON API,
and ask Harness to add Tags to the Post UI. At each step we'll check what landed
in the database and what works in the browser—not just whether a command said
success.”

**End-to-end validation — 2026-09-15:** all eight beats' functional steps passed,
but **one later intermittent HTTP 500 remains unexplained — see the stability
note below**. The run used **Homebrew CLI and packaged framework build 2500**,
without a framework/CLI source overlay, at **http://localhost:8092**. An independent agent implemented the exact
Tags prompt using the disclosed **CLI fallback**; a separate stdio MCP check
verified actual tool discovery. The app suite grew from **36/36 to 97/97**, and
independent browser/database checks confirmed Post↔Tags assignment, edit, clear,
validation preservation and repeat-safe seeds. This is a **Lucee/SQLite** result,
not a native Harness GUI auto-connection or cross-database claim. See the full
record and limitations at the end. Build **2488** results remain historical in
[demo.md](demo.md); [deck.md](deck.md) is the speaker outline. Markdown edits do
not update the PPTX.

> Keep the projected terminal at least 100 columns wide. Use one terminal session
> for this sequence so its directory and exported variables stay set. Java 21,
> Python 3 (for the API ID capture), the chosen Wheels CLI, and a working browser
> should be ready before the audience arrives. Warm downloads in a separate app.

## 0. Preflight — fresh app, no destructive reset

### 0.1 Record the installed CLI

```bash
wheels --version
```

Use the version actually validated below. Updating the CLI does not update an
existing app's framework. Older builds may not support `wheels setup agents`;
verify that before the talk, not by improvising an upgrade on stage.

### 0.2 Choose a new name and explicit URL

```bash
mkdir -p "$HOME/GitHub/_demo"
```

```bash
cd "$HOME/GitHub/_demo"
```

```bash
export DEMO_APP="cfugdemo$(date +%Y%m%d%H%M%S)"
```

```bash
export DEMO_PORT=8092
```

```bash
export DEMO_URL="http://localhost:$DEMO_PORT"
```

The timestamp gives each rehearsal a fresh valid app name and its own registry
entry. Keep previous apps and databases; do not delete `blogdemo`, clear the
server registry, or remove a live test database. Confirm **8092 is free** before
starting. If occupied, choose a free HTTP port and repeat the last two exports;
do not stop somebody else's process. Wheels may select another shutdown port,
but it does not silently change an occupied HTTP port.

<details>
<summary><strong>Presenter prep — timing, offline use and a safe fallback</strong></summary>

- The labelled beats total about **55 minutes**, before questions and agent wait
  time. The short **Say** lines are the normal path; these expandable notes are
  optional. Trim the broad feature tour first. Do not cut the restore-to-green,
  seed-persistence or tag-clear checks just to keep the original time estimate.
- Warm the JVM, JDBC driver and shipped docs before the meeting. Local docs
  reduce the Wi-Fi dependency, but don't promise that every first install works
  without downloads.
- Keep a separately named, rehearsed app and its exact URL ready. A fallback must
  be at the required checkpoint: the final app already has Tags and is not an
  honest substitute for showing a first scaffold or a pre-Tags 36-test baseline.
  If switching, announce the switch and check the app directory and URL before
  issuing more commands. Keep a disposable fallback login available off the
  projector; don't change a real password to rescue a demonstration. Never reset
  an unrelated app or registry entry.
- Run the CLI steps sequentially and wait for each to finish. An earlier
  rehearsal produced offline-docs mirror warnings with concurrent CLI calls;
  don't introduce that distraction or edit partially written code during seeding.
- Use the recorded CLI **and app** versions. A snapshot number isn't evidence
  that a release has been announced. This runbook's verified track is build 2500;
  the older 2482/2488 app paths and patch launchers are not this session's setup.

</details>

## Beat 1 — a running app (≈4 min)

> **Opening block — from an empty folder to a running application**
>
> **Say:** “First, let's remove the setup ceremony. We'll generate an application
> and start its server without hand-wiring a datasource or an Application.cfc.”
>
> **We'll do:** create a fresh app, start it on our chosen port, and inspect its
> welcome page, project layout and local documentation.
>
> **Expect:** a real Wheels app running on Lucee with SQLite, a details panel
> identifying the stack, and Guides/API cards that open locally. First boot may
> take longer while the runtime warms up; that is not a reason to start it twice.

### 1.1 Create, enter, start

```bash
wheels new "$DEMO_APP"
```

```bash
cd "$DEMO_APP"
```

```bash
wheels start --port="$DEMO_PORT"
```

**See:** server started at `http://localhost:8092` on the default track. Open that
URL; keep a second browser tab for `/register` later. First JVM boot can take time;
wait rather than stacking start commands.

### 1.2 Show the starter page and files

**Browser:** the Wheels wordmark, **The details** panel, **Guides** and **API docs**
cards. Record the app framework and engine versions. Click both docs cards and
check that the shipped documentation opens locally.

**Editor — inspect, no edit:** `CLAUDE.md`, `AGENTS.md`, `app/`, `config/`, `public/`
and `vendor/wheels/`.

**Say:** “One command gave us an MVC app, SQLite, tests, and its own documentation.
It also shipped the instructions our coding agent will read in Beat 8.”

<details>
<summary><strong>If asked — what's in the app, and do I need this exact stack?</strong></summary>

**What's MVC here?** The model owns data rules and ORM behavior; the controller
handles the request and chooses a response; the view renders it. Our application
code is in `app/`, routing/settings in `config/`, the web root in `public/`, and
this app's framework copy in `vendor/wheels/`. Generated files are ours to edit.

**Why SQLite?** It removes database-server setup from this demonstration. It is a
real database, not a mock. Wheels has other engine/database adapters, but today's
measured result is Lucee/SQLite; the later join migration is SQLite-specific.
Don't turn a successful demo into a cross-database compatibility claim.

**Is CommandBox required?** Not for this demonstrated Wheels CLI/Lucee path.
That is not a claim that CommandBox apps cannot use Wheels.

**What did updating the CLI update?** The installed tool and its templates, not
an already-created app's vendored framework. Point at the starter's actual
version rather than assuming it matches the CLI. `CLAUDE.md` and `AGENTS.md`
provide conventions to coding agents; they do not connect or authorize tools.
An earlier app created inside the framework checkout picked up checkout source;
our separate demo workspace avoids confusing that with the packaged build.

</details>

## Beat 2 — scaffold, migrate, seed, CRUD (≈8 min)

> **Opening block — turn a model declaration into something usable**
>
> **Say:** “Now we'll describe a Post once and let Wheels write the routine MVC
> plumbing. We'll inspect the plan before it writes, apply the schema, and put
> real content on screen.”
>
> **We'll do:** dry-run and generate the scaffold, round-trip its migration,
> generate sample data, then create, edit and delete through the browser.
>
> **Expect:** a model, controller, views, migration, tests and registered routes;
> ten seeded Posts with dates; visible success messages; and a 404 when we revisit
> the deleted throwaway. Keep Hello, Wheels for the console demonstration later.

### 2.1 Dry-run first

```bash
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime --dry-run
```

**See:** a project-relative `Would write:` list, including `config/routes.cfm`,
and no files written (historically eleven paths). Inspect `app/models/` in the
editor; no Post model should exist yet.

```bash
wheels routes
```

**See:** the framework's routes, no Post routes. The build-2488 total was **41**;
read the current total rather than promising it.

<details>
<summary><strong>If asked — where did those files and routes come from?</strong></summary>

**What does the scaffold save us?** It writes the repetitive model/controller/
view/test/migration files and registers the resource. The dry-run shows its
intended writes, including the route file; it does not preview database rows or
prove the resulting feature works.

**Why Post, Posts and posts?** Singular model, plural controller and table are
conventions. `Post` is the data type; `Posts.cfc` handles requests for the
collection; `posts` is its table. That common vocabulary replaces routine wiring.
Non-conventional schemas need explicit configuration, not a different language.

**Why so many route rows?** One resources declaration expands to actions and
HTTP verbs, with plain/format variants and both PATCH and PUT for update. The
framework also has its own tooling routes. Filter by the resource to show what
changed; sixteen rows are not sixteen hand-written actions.

</details>

### 2.2 Generate and round-trip the migration before data

```bash
wheels generate scaffold Post 'title:string{50}' body:text publishedAt:datetime
```

```bash
wheels migrate latest
```

```bash
wheels migrate down
```

```bash
wheels migrate up
```

**See:** posts created, rolled back, then recreated. Only do this round-trip at
this fresh-schema point, before seeding or browser writes. The same rule applies
to each new migration later in this runbook.

<details>
<summary><strong>If asked — what is a migration, and why go down and up?</strong></summary>

A migration is a versioned schema change with forward and reverse behavior. A
model declaration is not itself a database migration, and creating a migration
file is not the same as applying it. We inspect the schema and the actual data
instead of trusting generated output alone.

The round-trip proves this newly generated schema can be removed and recreated
**while it has no demo data**. It is not a general rollback recipe for populated
or production tables. Don't repeat it later after adding content. In Beat 8 the
join depends on Tags, so reverse the join before Tags, then restore Tags before
the join; leave the four earlier migrations alone.

</details>

```bash
wheels seed --generate
```

```bash
wheels reload
```

```bash
wheels routes --filter=posts
```

**See:** ten seeded Posts with real datetimes; historically **16 Post routes**,
including plain/format variants and PATCH/PUT update. Generated seeding is **not
idempotent**: don't run it again casually.

<details>
<summary><strong>If asked — generated data versus repeat-safe seeds</strong></summary>

**Generated mode** attempts another batch of sample records across the app's
models. After Comment exists, the next run adds Posts as well as Comments. It is
useful for quickly filling a screen, not for reproducing a fixed dataset or
creating usable accounts with real passwords.

**Convention mode** runs deliberate application seed logic in `app/db/seeds.cfm`.
In this demo it uses `seedOnce` and stable attributes to create/reuse Tags and
look up real parent IDs. Plain seeding detects convention files when present;
explicit generated mode bypasses them. Both paths need this app's running server.

**Does seedOnce fix duplicates?** No: it finds an existing matching record or
creates one. It neither cleans up existing duplicates nor guarantees that every
seed script is repeat-safe. Count actual invocations and durable rows—not just
visible source blocks, because a loop may call the helper several times. The
current Tags seed makes six create/skip decisions: three Tags and three joins.

**Why audit afterward?** Earlier rehearsals exposed false-success summaries and
assumed parent IDs. Those older-build failures explain our checks; don't import
their old patch/reset commands into this build-2500 flow. A successful exit is
not proof of committed rows or valid relationships. Read the data in a fresh
request and look for orphans and duplicate pairs.

The separately rehearsed small-data fallback used two dated Posts and two
Comments, including a test with parent IDs 41/97. That proves why ID lookup
matters; it is **not a mid-demo switch of seed modes**. Keep this sequence intact.

</details>

### 2.3 Show the generated declarations

**Editor — inspect, no edit:** the new resource line in `config/routes.cfm`:

```cfm
.resources("posts")
```

**Editor — inspect, no edit:** these rules inside `app/models/Post.cfc`:

```cfm
validatesPresenceOf("title,body,publishedAt");
validatesLengthOf(property="title", maximum=50, allowBlank=true);
```

**Say:** “The title's 50-character limit became both a database declaration and
a model validation. One resources line became the actual REST route table.”

### 2.4 Browser CRUD

1. Open `/posts`; check ten Posts and dates.
2. Create **Hello, Wheels**, with a body and publication date. Edit its body and
   keep it for Beat 4.
3. Create a separate throwaway, then press **Delete**. Keep the original seeded
   Posts intact for Comment seeding.
4. Revisit the throwaway's URL: expect **404**, not 500. The `deletedAt` soft-delete
   marker keeps the row while the app treats it as gone.
5. Show the consistent **Edit · Delete · ← all posts** button row.

<details>
<summary><strong>If asked — field limits, timestamps, deletion and buttons</strong></summary>

The quoted `title:string{50}` token reaches the generator literally. It produces
both a column-size declaration and a model rule. **SQLite does not enforce a
VARCHAR length just because it is declared**; the model validation is the
observed limit here. Later, the Tag UI also limits entry, and a tampered oversized
request still has to fail server-side validation.

The usual `timestamps()` helper includes **createdAt, updatedAt and deletedAt**.
Our `publishedAt` is separate content data. Soft deletion sets the marker and
normal finders hide the row; a 404 therefore does not mean the row was physically
removed. Retain Hello, Wheels and delete a separate throwaway.

A Delete control is a form submission, not a GET navigation link. Its helper
carries the intended method and CSRF token; it is styled beside the links so the
actions look consistent. The `.wheels-actions` wrapper is a div because placing
the helper's form inside a paragraph creates invalid HTML and breaks alignment.

</details>

## Beat 3 — it wrote files; you own them (≈5 min)

> **Opening block — add a business rule, not more plumbing**
>
> **Say:** “The scaffold is ordinary code, not a black box. Let's change what a
> valid Post means and see whether the existing form knows how to explain it.”
>
> **We'll do:** reject the placeholder title Untitled, declare that Posts have
> Comments, reload, and try both an empty form and a completed-but-invalid form.
>
> **Expect:** presence errors for missing fields and a separate reserved-title
> error for Untitled, without editing the controller or form. The association
> declaration prepares the parent for the child scaffold in the next beat.

### 3.1 Add the business rule and inverse association

**Editor — `app/models/Post.cfc`: add these lines inside the existing `config()`.
Keep all generated validations.**

```cfm
validatesExclusionOf(property="title", list="Untitled", allowBlank=true);
hasMany(name="comments");
```

```bash
wheels reload
```

### 3.2 Show validation

**Browser:** `/posts/new`. Submit blank title/body to show their presence errors;
if the date is blank too, expect its presence error. Submit **Untitled** with the
other fields completed: **Title is reserved**. `allowBlank=true` avoids a second
exclusion error on an already-blank title.

**Say:** “The generator gave us a starting point, not a cage. The existing form
renders our new rule without controller or view changes.” Do not add title
uniqueness: the generated sample titles repeat in the next seed.

<details>
<summary><strong>If asked — why can one model edit change the form's behavior?</strong></summary>

The controller already attempts a save, checks success and renders the form on
failure. The view already renders the model's errors. Adding a model validation
therefore feeds an existing path; it doesn't invent a new form at runtime.
Server-side validation still matters when a client bypasses browser controls.

`allowBlank=true` on the exclusion lets the presence rule own the missing-value
error. A completed but reserved value is a different mistake and gets its own
message. The original presence and maximum-length rules remain in place.

Keep associations, validations and callbacks in `config()`. Use all named
arguments when adding options; don't mix positional and named arguments. Reload
so cached model configuration is refreshed, but read unexpected errors rather
than assuming every 500 is a cache problem.

Don't add a body minimum or title uniqueness as an improvised extra: the former
can invalidate generated fixtures, and the latter changes the sample-seed
contract. Also, declaring `hasMany` alone does **not** choose cascading deletion.

</details>

## Beat 4 — associations and a REPL (≈5 min)

> **Opening block — connect records and ask the running app questions**
>
> **Say:** “A blog isn't just isolated tables. A Comment belongs to a Post, and a
> Post has many Comments. We'll make that relationship visible in both the UI and
> the ORM.”
>
> **We'll do:** scaffold Comment with belongsTo, migrate and seed it, inspect the
> parent edits, add a Comment using a title-labelled picker, then use the console.
>
> **Expect:** one parent hasMany declaration, a Comments section on the Post,
> valid foreign-key targets, and queries that navigate in both directions. The
> second seed adds another ten Posts as well as ten Comments—it isn't child-only.

### 4.1 Scaffold the child and round-trip its migration

```bash
wheels generate scaffold Comment body:text --belongsTo=post
```

```bash
wheels migrate latest
```

```bash
wheels migrate down
```

```bash
wheels migrate up
```

```bash
wheels seed --generate
```

```bash
wheels reload
```

**See:** historically **20 created**, ten Comments and another ten Posts. Confirm
actual counts and zero orphan Comments during rehearsal. The scaffold reports
parent controller/view modifications; read any skipped-wiring warnings.

### 4.2 Inspect both sides

**Editor — inspect, no edit:** `Comment.cfc` has `belongsTo("post")` and validates
`body,post_id`; the migration has the real `post_id` column. `Post.cfc` still has
exactly one `hasMany`. In `app/controllers/Posts.cfc`, `show()` includes Comments:

```cfm
post=model("Post").findByKey(key=params.key, include="comments");
```

**Browser:** open a seeded Post with Comments. **Add a comment** offers Post
**titles**, not raw IDs. Select the desired Post explicitly (the flat add link
does not preselect it). Submit blank body, then a valid body. Return to that
Post and verify its related list. Keep the original seed rows for the examples
below; otherwise substitute IDs you actually observed.

<details>
<summary><strong>If asked — how did a child scaffold change the parent?</strong></summary>

The association flag gives the generator enough information to add the child
foreign-key field, belongsTo declaration and Post picker. For a conventional
parent it can also add/reuse hasMany, eager-load Comments in show, and add the
related view block. It preserves custom code and can skip parent edits it cannot
safely recognize; the output tells you what happened.

The stock app uses underscore reference columns such as `post_id`. Model naming
and schema conventions avoid manual FK configuration in this simple case; a
custom schema may need explicit mapping. A plain integer field called postId is
not equivalent to asking the generator to wire a relationship.

**ORM relationship versus database constraint:** belongsTo/hasMany describe how
models navigate. They are not proof that the database rejects orphan inserts.
The Comment checks establish valid stored relationships in this rehearsal; Beat
8 separately verifies actual join-table foreign keys, unique indexes and enabled
SQLite JDBC enforcement.

</details>

### 4.3 Console — one complete expression per request

```bash
wheels console
```

**Console expression 1:**

```cfm
model("Post").findByKey(1).comments()
```

**Console expression 2:**

```cfm
model("Comment").findByKey(3).post().title
```

**Console expression 3:**

```cfm
model("Post").where("title", "LIKE", "%Wheels%").orderBy("publishedAt", "DESC").get()
```

**See:** a related-comment query, **Post Title 3** on the preserved clean seed
track, then **Hello, Wheels**. Each expression is stateless; don't depend on a
variable assigned in a previous request.

**Console — exit before the next terminal command:**

```text
/exit
```

**Say:** “The console is in our live app and database. These query-builder
arguments bind values separately from SQL; raw SQL still needs developer care.”

<details>
<summary><strong>If asked — eager loading, query results, console state and nested routes</strong></summary>

**Why include Comments in show?** `include="comments"` supplies associated data
for the related view. That generated block consumes an array of objects. A lazy
`post.comments()` call, or a default `findAll()`, returns a query instead. Both
are useful, but their loops and expectations differ—don't paste a query into an
array-oriented view. Explicit `returnAs="objects"` selects that collection shape
when needed; it is not a change to make during this beat.

**Is the console a mock?** No: it uses this running development app and database.
Treat writes as real. Each entered expression is a separate request; a local
variable from one line is not a persistent REPL session. The supplied expressions
are reads, and `/exit` leaves the console—bare `exit` is treated as an expression.

**Is every finder automatically injection-proof?** These two-/three-argument
query-builder calls separate values from SQL. Raw SQL/where fragments still need
care. Don't promise that any string someone writes becomes safe automatically.

**Could URLs be nested?** Yes, the router supports nested resource callbacks.
We deliberately use flat routes to keep the demo moving; selecting the Post in
the form establishes the relationship. Don't introduce new route syntax mid-run.

</details>

## Beat 5 — authentication and authorization (≈13 min)

> **Opening block — distinguish who you are from what you may do**
>
> **Say:** “Authentication answers who you are. Authorization answers whether
> you're allowed to do this. We'll generate login, then build the permission
> story one visible step at a time.”
>
> **We'll do:** register and log in, inspect bcrypt storage, then move from an
> unused deny-by-default policy to one gated action, all gated actions, and a
> readers/members/admins rule set.
>
> **Expect:** an unused policy changes nothing; explicit gates produce 403s;
> readers can read and members can edit, but our member cannot delete. We are
> **not creating an admin account**. At the end we'll remove the demonstration
> gate for the generated tests, so the final demo must not be called secured CRUD.

### 5.1 Generate session auth and round-trip its migration

```bash
wheels generate auth --strategy=session
```

```bash
wheels migrate latest
```

```bash
wheels migrate down
```

```bash
wheels migrate up
```

**Editor — inspect, no edit:** `app/models/User.cfc` stores **passwordHash** and
uses **bcryptHash()/bcryptVerify()**. Show the generated confirmation/reset/session
code; do not project a real password or credential.

<details>
<summary><strong>If asked — bcrypt, salts, password reset and production readiness</strong></summary>

This generator stores **passwordHash** and calls the bcrypt helpers. The
plaintext password/confirmation are transient inputs, not stored password
columns. Bcrypt includes its salt and cost in the stored representation; the
rehearsal observed a 60-character `$2a$10$…` hash. It is a password verifier, not
something to decrypt. Don't substitute the older PBKDF2/passwordDigest story:
PasswordHasher is a separate framework service, not this generated model's path.

We demonstrate registration, login, wrong-password rejection and logout. A
scaffold containing password-reset code is **not** proof that reset email is
wired or delivered; the generated controller has a delivery integration TODO.
Likewise, production still needs appropriate HTTPS, rate limiting, account
policies and secret handling. “Generated securely useful building blocks” is not
“a finished production authentication system with every flow tested.”

</details>

### 5.2 Add deliberate navigation

**Editor — `app/views/layout.cfm`: add this complete navigation block inside the
existing `<cfoutput>`, immediately before `#flashMessages()#`, in BOTH the
content-only and full-page branches. Preserve everything else.**

```cfm
<div class="wheels-actions">
    #linkTo(route="posts", text="Posts", class="button")#
    #linkTo(route="login", text="Log in", class="button")#
    #buttonTo(route="logout", method="delete", text="Log out")#
</div>
```

```bash
wheels reload
```

### 5.3 Register, log out, log in

| Browser action | Expected flash |
|---|---|
| `/register`, disposable email, 12+ character password and matching confirmation | **Welcome!** |
| Press **Log out** | **You have been logged out.** |
| `/login`, wrong password | **Invalid email or password.** |
| `/login`, correct password | **Welcome back.** |

**Say:** “Logout is a button: a state-changing DELETE with CSRF protection, not
a GET link. The generator does not add navigation to our layout for us.”

<details>
<summary><strong>If asked — sessions, CSRF and why super.config stays</strong></summary>

Login establishes the principal used by the session strategy; a policy can then
ask about that identity. Session identity, permission checks and CSRF tokens are
three different responsibilities. A CSRF token helps reject a forged browser
mutation; it does not decide whether an authenticated user is allowed to delete.

`super.config()` keeps the base controller's CSRF protection. The generated form
helpers work with that protection and include the token. Removing the inherited
configuration or using a GET logout link would change the security behavior, not
just the styling.

The later negative CSRF probes blocked mutations, but this development build
rendered **HTTP 500 with InvalidAuthenticityToken**. Don't promise a 403 for that
case, or confuse it with the separate unexplained missing-WO request in the
stability note. Policy denial is the 403 we intentionally demonstrate next.

</details>

### 5.4 Policy step 1 — a policy nobody asks

**Log out again.** Stay logged out for policy steps 1–4. Keep `/posts`, `/posts/1`,
`/posts/new` and `/posts/1/edit` ready; these examples use a preserved seeded Post.
The five-step arc is **readers read, members write, admins delete**. The admin
allow-path is a design extension, not part of the staged recipe.

```bash
wheels generate policy Post
```

```bash
wheels reload
```

**Editor — inspect:** `app/policies/PostPolicy.cfc`; every generated method denies.
**Browser:** list/show/new still **200**.

**Say:** “A policy is a question. Nobody has asked it yet. Generating one does not
silently lock down the application.”

### 5.5 Policy step 2 — gate one action

**Editor — `app/controllers/Posts.cfc`: replace ONLY `show()` with this complete
method. Keep the existing `requireRecord` filter and helper.**

```cfm
function show() {
    post=model("Post").findByKey(key=params.key, include="comments");
    authorize(post);
}
```

```bash
wheels reload
```

**Browser:** list **200**, existing show **403**, new **200**.
**Say:** “One line asks the policy for this action. Other actions still never ask.”

### 5.6 Policy step 3 — gate every action

**Editor — `app/controllers/Posts.cfc`: replace ONLY `show()` with this complete
method, removing the one-action gate.**

```cfm
function show() {
    post=model("Post").findByKey(key=params.key, include="comments");
}
```

**Editor — same file: replace ONLY `config()` with this complete method.**

```cfm
function config() {
    super.config();
    filters(through="requireRecord", only="show,edit,update,delete");
    filters(through="authorizePost");
}
```

**Editor — same file: add this complete helper inside the component, before its
closing brace. Do not replace the existing `requireRecord` helper.**

```cfm
private function authorizePost() {
    authorize(model("Post"));
}
```

```bash
wheels reload
```

**Browser:** list/show/new all **403**. Missing `/posts/99999` should be **404**:
`requireRecord` runs first. **Be precise:** different 403/404 responses **do reveal
which IDs exist**. This ordering preserves the scaffold's missing-record behavior;
it is not an anti-enumeration defense. An app needing concealed existence must
choose a uniform response policy deliberately.

**Say:** “One filter asks for every action. It is private so it isn't a routable
action itself.”

<details>
<summary><strong>If asked — how does one filter choose a policy method?</strong></summary>

`authorize(model("Post"))` uses the current action, so index asks index, new asks
new, and so on. Passing a record is useful for rules depending on that record,
such as ownership; the class-level call is enough for our action-wide example.
Filters are private so they cannot become routable actions. Their order is
visible in `config()`, including the missing-record guard before authorization.

`authorize()` gates a server action. `can()` lets a view decide whether to show a
control, but hiding a button does not protect the endpoint. `policyScope()` is
for narrowing collections; a permission to show one record does not magically
filter an index query. We name these distinct tools, rather than claiming all
three behaviors have been implemented by one filter.

</details>

### 5.7 Policy step 4 — readers read, members write, admins delete

**Editor — `app/policies/PostPolicy.cfc`: replace the seven generated action
methods with the following complete methods; add the two private helpers inside
the same component. Preserve the generated component declaration/inheritance and
any other infrastructure.**

```cfm
public boolean function index()  { return true; }
public boolean function show()   { return true; }
public boolean function new()    { return isLoggedIn(); }
public boolean function create() { return isLoggedIn(); }
public boolean function edit()   { return isLoggedIn(); }
public boolean function update() { return isLoggedIn(); }
public boolean function delete() { return isAdmin(); }

private boolean function isLoggedIn() {
    return IsStruct(variables.user) && !StructIsEmpty(variables.user);
}

private boolean function isAdmin() {
    return isLoggedIn()
        && StructKeyExists(variables.user, "role")
        && variables.user.role == "admin";
}
```

```bash
wheels reload
```

**Browser, logged out:** list/show **200**, new/edit **403**.
**Say:** “Readers read. Anonymous visitors cannot open the writing forms.”

### 5.8 Policy step 5 — prove the member tier

**Browser:** log in. New/edit now **200**. Edit a Post successfully, then attempt
its **Delete**: **403**, with the Post still present.

**Say:** “A member can write, but this account has no role, so it cannot delete.
The admin condition is explicit, but we have not built admin accounts today.”

**Optional discussion only — NOT executed or claimed validated:** a real admin
allow-path requires a reversible `users.role` migration, safe account promotion,
and the role in the principals created by both registration and login. Re-login
would be needed to refresh that principal. Do not paste a blanket users-table
UPDATE or claim promotion was tested by this runbook. Conditional `can()` checks
could hide denied controls; that is separate from controller enforcement.

| Call | Intent |
|---|---|
| `authorize(record)` | Gate an action; deny with 403 |
| `can("update", post)` | Ask whether a control should be visible |
| `policyScope(model("Post")).findAll()` | Narrow a list according to a scope policy |

### 5.9 Before Beat 6 — remove ONLY the demonstration enforcement

**Editor — `app/controllers/Posts.cfc`: replace ONLY `config()` with this complete
method.**

```cfm
function config() {
    super.config();
    filters(through="requireRecord", only="show,edit,update,delete");
}
```

**Editor — same file: remove ONLY the entire `private function authorizePost()`
helper added in 5.6.** Keep `requireRecord`, CRUD actions, Comments eager loading,
auth/session/CSRF code, and the PostPolicy file. `show()` must remain the ungated
version from 5.6. This restores the scaffold's public Post CRUD for the generated
unauthenticated specs; it is a demonstration boundary, not production hardening.

```bash
wheels reload
```

## Beat 6 — red, green (≈8 min)

> **Opening block — prove the safety net can actually fail**
>
> **Say:** “A green test count is reassuring, but let's prove a test notices when
> we break the behavior it is supposed to protect.”
>
> **We'll do:** run the generated suite on the naturally fresh test database, add
> a body-validation example, remove just that rule, then restore it.
>
> **Expect:** 27 passing, then 28; an intentional 27 passed / 1 failed; and 28
> passing again. The failure is the point of the demonstration. We'll restore the
> rule before moving on, and the development Posts should remain untouched.

### 6.1 First test run on this app's naturally fresh test database

```bash
wheels test
```

**Expected historical baseline:** **27 passed**. Never delete the test database
to force a result or hide a failing first run with an off-screen second run.
If a count differs, investigate and record it. The app/test databases are isolated.

<details>
<summary><strong>If asked — where do the test records come from?</strong></summary>

The generated controller specs create the records they need. A Comment fixture
creates its parent and uses that returned ID; it should not depend on a seeded
development Post 1. The test runner uses this app's separate test application
and datasource. Our verification checked that tests left development row counts
unchanged; no test database was deleted to manufacture a passing first run.

The policy gate was removed as an explicit **demo boundary**, so the generated
unauthenticated CRUD specs match the final app. That is not production advice.
A secured real app should retain its gates and test authenticated, denied and
permitted paths with suitable identities—not turn authorization off for green.

</details>

### 6.2 Add a real spec

**Editor — `tests/specs/models/PostSpec.cfc`: add this complete example inside the
existing `describe` block.**

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

**Expected:** baseline plus one (**28** historically).

<details>
<summary><strong>If asked — why test the specific body error?</strong></summary>

A model can be invalid for the wrong reason. We supply a title and date and then
assert both invalidity and an error on **body**, so this example identifies the
behavior we mean to protect. Removing only body presence should break this test;
restoring it should repair that same failure. The failing exit code is expected
in the red phase, not something to suppress.

Generated tests are a starting point. The agent later adds relationship,
constraint and rollback tests because a larger green number alone doesn't prove
Tags can be assigned, cleared, or preserved after a failed edit.

</details>

### 6.3 Break only the body-presence rule

**Editor — `app/models/Post.cfc`: replace ONLY the existing combined presence-rule
statement with this complete statement. Keep all other rules/associations.**

```cfm
validatesPresenceOf("title,publishedAt");
```

```bash
wheels reload
```

```bash
wheels test
```

**Expected intentional red:** **27 passed / 1 failed**, `requires a body`.

### 6.4 Restore the rule before continuing

**Editor — same file: replace ONLY that statement with this complete statement.**

```cfm
validatesPresenceOf("title,body,publishedAt");
```

```bash
wheels reload
```

```bash
wheels test
```

**Expected:** **28 passed** again. Do not continue until restored green.
**Say:** “The tests caught a real model regression without touching the Posts we
have been clicking through.”

## Beat 7 — the two-minute tour (≈7 min)

> **Opening block — inspect the app, then give it a JSON interface**
>
> **Say:** “The framework also needs to help us understand the app and expose
> data without HTML. We'll take a quick tooling tour, then build a small API.”
>
> **We'll do:** inspect project info, schema differences and change risk; generate
> Product's API; send an invalid request, then create, read, update and delete a
> real record using the ID returned by the server.
>
> **Expect:** an explained 422 for the missing SKU, 201 for a valid create, 200 for
> successful reads/updates, 204 for deletion, and 404 afterward. The test suite
> should reach 36 passing before the agent adds anything.

### 7.1 Project tools

```bash
wheels info
```

```bash
wheels migrate diff
```

```bash
wheels coverage --top=5
```

**See:** the actual app/server version and model/routes info; historically diff
reported no differences and coverage ranked change risk by CRAP score. Inspect
current output rather than repeating an old result. Coverage runs tests.
Show the browser debug bar's timing, params, queries and complexity panels.

<details>
<summary><strong>If asked — what do diff, coverage and the debug bar tell us?</strong></summary>

**Info** identifies the actual project, version and server, which helps catch a
wrong-directory or wrong-port demo. **Migration diff** previews differences the
model/schema tooling recognizes. A clean result isn't proof that every intended
business field exists. We are previewing, not writing a migration in this step;
an optional write mode still requires inspection and subsequent application.

**Coverage/CRAP** combines measured coverage and complexity to highlight code
that may be risky to change. It helps choose where to inspect or add tests; it is
not a security audit, a benchmark or a complete quality grade. The command runs
tests and temporarily instruments code, so give it time to finish before editing
or launching another coverage run.

The **debug bar** exposes request timing, parameters and database queries. Use it
to explain what a click caused, not to imply that a fast sample request proves
production performance. Avoid exposing real credentials or sensitive data when
showing request details.

</details>

### 7.2 Generate and round-trip the Product API migration

```bash
wheels generate api-resource Product name price:decimal sku:string
```

```bash
wheels migrate latest
```

```bash
wheels migrate down
```

```bash
wheels migrate up
```

```bash
wheels reload
```

> **Presenter reminder — trust your URL variable.** The generator's informational
> curl example printed localhost:8080 during rehearsal even though this app ran
> on 8092. The copyable commands below use `$DEMO_URL`; do not substitute the
> generic hint or send requests to an older rehearsal app.

### 7.3 Validation failure first

```bash
curl -i -X POST "$DEMO_URL/api/products" \
  -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Drum","price":149.99}}'
```

**See:** **422**, SKU validation error. Read the body, not only the status.

### 7.4 Create and capture the actual ID

```bash
curl -sS -D api-product.headers -o api-product.json -w 'HTTP %{http_code}\n' \
  -X POST "$DEMO_URL/api/products" \
  -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Drum","price":149.99,"sku":"DRUM-001"}}'
```

**See:** **HTTP 201**. The response headers/body are saved in this disposable app.
If it is not 201, inspect the response before continuing; don't reuse a stale ID.

```bash
python3 -m json.tool api-product.json
```

```bash
export PRODUCT_ID="$(python3 -c 'import json; e=json.load(open("api-product.json")); p=next(v for k,v in e.items() if k.lower()=="product"); n=next(v for k,v in p.items() if k.lower()=="id"); assert str(n).isdigit(), "Expected numeric created product ID"; print(n)')"
```

### 7.5 Read, update, reject invalid update, delete that ID

```bash
curl -i "$DEMO_URL/api/products"
```

```bash
curl -i -X PATCH "$DEMO_URL/api/products/$PRODUCT_ID" \
  -H 'Content-Type: application/json' \
  -d '{"product":{"name":"Updated Drum","price":159.99,"sku":"DRUM-001"}}'
```

```bash
curl -i -X PATCH "$DEMO_URL/api/products/$PRODUCT_ID" \
  -H 'Content-Type: application/json' \
  -d '{"product":{"sku":""}}'
```

```bash
curl -i "$DEMO_URL/api/products/99999"
```

```bash
curl -i -X DELETE "$DEMO_URL/api/products/$PRODUCT_ID"
```

```bash
curl -i "$DEMO_URL/api/products/$PRODUCT_ID"
```

**See:** **200 · 200 · 422 · 404 · 204 · 404**. Never hard-code `/1` for a record
created after repeated requests. `/api` is a namespace, not API versioning.

<details>
<summary><strong>If asked — the API contract and what it does not promise</strong></summary>

- **201:** a valid create produced a record; read its returned ID.
- **200:** a successful read or update returned a response.
- **422:** the request reached validation but its data was unacceptable. The
  missing SKU is intentional—its model rule is the same kind of rule a form uses.
- **204:** deletion succeeded with no response body to parse.
- **404:** no visible record matches the requested key, including after deletion.

The created record is inside the response's **PRODUCT** wrapper. Our capture
reads that wrapper and its ID case-insensitively; it does not assume an ID at the
JSON root or reuse a guessed `/1`. Inspect a failed response before going on.

A JSON API uses the same model/rule approach without HTML views. The `/api`
prefix alone provides neither API versioning nor authentication. The generated
API controller is separate from the HTML controller's session/CSRF wiring; a
production API needs a deliberate access/security design. We have not built a
secured or versioned API in this beat.

</details>

### 7.6 Lock in the pre-agent baseline

```bash
wheels test
```

**Expected baseline before Tags: 36 passing**. Record the actual total for the
agent. No generated tests should be removed merely to keep this number.

<details>
<summary><strong>If asked — what else does Wheels cover? (verbal tour, no live edits)</strong></summary>

Keep this to a sentence per topic; it is the first material to cut if time is tight.

| Feature | Short explanation |
|---|---|
| Middleware | Cross-cutting request handling, such as CORS, security headers and rate limiting; configure the behavior your app needs. |
| Background jobs | Deferred work with worker/queue processing rather than making the user wait for everything in one request. |
| SSE/channels | Server-to-client updates for live experiences; not a feature we enabled in this blog. |
| Local/S3 storage | A storage abstraction so app code needn't be coupled to one storage backend. |
| Multi-tenancy | Tenant resolution and isolation choices; not automatically enabled by generating a model. |
| Deployment tooling | The CLI includes deployment support; today's local start is not a production deployment. |

These are broader framework capabilities, **not additional validated features of
this demo**. Don't improvise migrations, workers, credentials or infrastructure
on stage to answer a breadth question.

</details>

<details>
<summary><strong>If asked — route model binding and slug URLs (explanation only)</strong></summary>

Binding can resolve a route key into `params.post` before an action and reject a
missing record. Binding by a slug is a further option, but **this Post schema
has no slug field**. Neither feature is an extra live change in this runbook.

Do not paste the older rehearsal's replacement show method into the final Tags
app: the current action supplies both Comments and `selectedTags` for its view.
Binding does not automatically reproduce those view variables or eager-loaded
collections. The Comments block expects objects, whereas default association
readers return queries. Preserve the complete view contract when changing it.

Also, `processRequest` tests with explicit controller/action call the controller,
not the dispatcher. A bound-model action needs its input supplied as a controller
fixture, plus separate HTTP tests proving route resolution and missing-key
behavior. Verify all affected CRUD paths, not one successful GET. The earlier
binding rehearsal preceded the current Tags feature; it isn't proof for a new
combined implementation.

</details>

## Beat 8 — Wheels and Harness add Tags to Posts (≈5 min presentation)

> **Opening block — let the agent extend the app, then check its work**
>
> **Say:** “Now we'll give Harness the project's conventions and tools and ask
> for a real enhancement: multiple Tags on our existing Posts. The finish line
> isn't a generated file; it's a relationship we can edit and see after refresh.”
>
> **We'll do:** run agent setup, verify the available transport, paste the full
> prompt, and review migrations, repeat-safe seeds, tests and browser behavior.
>
> **Expect:** Tags management plus Post selection/edit/clear/re-add, with Comments
> and login still working and failed edits leaving saved data intact. This
> rehearsal reached 97 passing tests; another implementation must justify its own
> count. Disclose CLI fallback or a prepared app instead of pretending it is a
> native MCP connection or a live five-minute build.

The implementation and full verification can take longer than five minutes.
Rehearse the prompt end to end beforehand; on stage show the live tool connection,
implementation highlights and the working result. If using a rehearsed fallback,
say so. Independent Tags CRUD is **not** this beat's finish line.

### 8.1 Generate the project client configuration

```bash
wheels setup agents
```

**See:** `.mcp.json` and `.opencode.json` created/updated in **this app's root**.
The command merges the Wheels entry while preserving other configured servers;
malformed JSON fails without silently overwriting it. It does **not** install
Harness, enable an integration automatically, or grant tool permissions.

**Editor — inspect, do not replace existing configuration:** the Wheels entry
inside `.mcp.json` has this shape:

```json
{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}
```

### 8.2 Connect Harness to this app and verify discovery

1. Open/select **this demo app root** in Harness, not the framework repository or
   a previous rehearsal. Use the client's supported MCP configuration/loading
   mechanism; do not assume it reads either generated file automatically.
2. Reconnect/reload tools or restart the assistant as appropriate for that client.
   The client launches `wheels mcp wheels` as a stdio server; do not run that
   protocol process as if it were an interactive terminal command.
3. Inspect the actual discovered tool list and schemas. Have Harness invoke the
   advertised routes tool against this app and compare it with our Post/API
   routes. Names/capabilities/counts vary by version; do not promise “19 tools.”
4. If MCP is unavailable, say **CLI fallback** and use the real Wheels CLI through
   Harness's terminal tools. A successful CLI invocation is not an MCP proof.

<details>
<summary><strong>If asked — what MCP adds, and what setup agents actually does</strong></summary>

MCP gives a capable client a structured way to discover and call the project's
advertised tools. The CLI remains the real underlying development surface; MCP
is not an alternate ORM or a source of authority over the app.

Agent setup writes/merges two client-configuration shapes. It does not install
Harness, establish a connection by itself or grant permissions. Open the correct
app in the client, inspect tool discovery and make a project-specific call. In
our rehearsal, the stdio probe found 19 tools, but the implementation worker used
the disclosed CLI fallback because native tools were not exposed to it. Those
are distinct facts, not a claim of automatic GUI integration.

The shipped agent instructions and `/wheels/ai` documentation give useful
context; they don't replace verification. A visible tool name, a successful
response or a green scaffold test is not proof that requested columns, persisted
rows and usable UI exist. That distinction is why this prompt names concrete
acceptance checks.

</details>

### 8.3 Paste the complete implementation prompt

Use the single copyable block in [harness-tags-prompt.md](harness-tags-prompt.md).
It is also reproduced below so this iPad card is self-contained.

```text
Implement a compact, working many-to-many tagging feature in THIS existing Wheels demo app. Do the implementation and verification now, not just a plan. Do not commit or push unless I ask.

Context and discovery
- Read this app's CLAUDE.md and AGENTS.md first. Inspect its actual models, migrations/schema, routes, controllers, forms, layout, seeds and tests before editing. This is an APPLICATION, not the Wheels framework repository: do not alter vendor/ or install/upgrade the framework or CLI.
- Beats 1–7 created Post(title:string max 50, body:text, publishedAt:datetime), Comment(body:text, post_id), bcrypt/session User authentication, a PostPolicy, and a Product JSON API. Preserve the title exclusion/presence/length rules, comments and their related UI, auth/session/logout flows, CSRF protection, routes and existing styling. The temporary authorizePost demonstration filter was removed before the 36-spec baseline; the policy file remains but its existence alone does not enforce authorization. Inspect the actual state. Do not re-enable that temporary filter or invent a role column/admin user.
- Discover the connected Wheels MCP server and inspect its advertised tool names and argument schemas. Prefer native advertised MCP tools for supported operations; use the real wheels CLI for operations not advertised or if MCP is unavailable, and state which transport you used. Do not invent tools or assume a fixed tool count. Confirm the server/project URL from this app, not port 8080 or another rehearsal's registration. Read the shipped Wheels guides/API docs and actual implementation when necessary; specifically VERIFY supported hasMany/belongsTo/through/shortcut syntax, transaction behavior, query-versus-object collection shapes, migration/index/FK helpers and form helpers before using them. Do not import Rails APIs by guesswork.

Persisted feature
- Add Tag with required name (maximum 30) and required unique slug, with model validation AND a database unique index on slug. Keep slug normalization and validation predictable and tested.
- Add a real PostTag join model/table, using the app's actual table and foreign-key naming conventions (stock new apps use underscore reference columns). Persist post/tag foreign keys, enforce referential integrity and a database unique constraint/index on the (post, tag) pair, and validate the association inputs. Wire Post -> Tags and Tag -> Posts through PostTag in both directions using verified Wheels APIs. Define deletion behavior explicitly so joins cannot orphan; preserve existing Post/Comment behavior. Handle Wheels timestamps/soft deletion deliberately so clearing and re-adding a tag works without violating pair uniqueness.
- Do NOT stop at an independent Tags-only CRUD scaffold. Integrate with the EXISTING Post create/update actions and forms: choose multiple existing Tags on new/edit; load the saved selection when editing; persist changes; allow every Tag to be cleared (including the browser's omitted/empty multi-select case); and show no selected tags on the next request. Reject malformed/nonexistent Tag IDs without partial writes. Deduplicate repeated IDs. Save the Post and synchronize its join rows atomically so invalid Post/Tag input cannot leave a changed Post or partial association set.
- Preserve entered Post fields and the submitted valid Tag selections when a form fails validation. Render useful errors. A failed edit must retain the original persisted association set. Escape tag names/slugs in rendered HTML.
- Show readable Tag names on Post index/show, keep Comments visible, and add a Tags navigation link plus compact Tag management (list/new/edit/delete with validations and safe handling of assigned Tags). Match the existing layout/button styling. Keep CSRF on all state-changing HTML forms. Follow whatever authorization is ACTUALLY enforced by this app for equivalent read/write/delete actions; don't weaken it, add unrequested role machinery, or mistake the retained unused PostPolicy for active enforcement.

Seeds and verification
- Add reversible migrations. Apply the new migrations with latest, then down, then up BEFORE seeding; inspect the persisted schema and indexes/FKs, not merely successful generator output. If multiple migrations are necessary, round-trip each new migration in dependency-safe order before seeding. Never roll back pre-existing demo migrations or delete/reset the app, registry or live/test database.
- Extend app/db/seeds.cfm without discarding existing seed logic. Seed a few useful Tags (including CFUG Demo / cfug-demo) and join records for real Posts. Resolve existing Posts by stable attributes and use actual returned IDs; if a dedicated demo Post is needed, create/reuse it idempotently with valid body/date/title. Do not hard-code Post or Tag IDs, regenerate all models' random data, delete unrelated records, or modify existing User/Product/Comment data. Run convention seeding twice and prove the second run adds no duplicate Tags, Posts or join pairs. Check committed associations in a separate request.
- Add focused WheelsTest BDD tests for both association directions, duplicate slug/pair prevention, Post create/edit/clear, re-add after clearing, repeated selected IDs, malformed/nonexistent IDs, invalid Post/Tag input, preserved selections after validation failure, transaction rollback and repeat-safe seeding. Cover unauthenticated/unauthorized behavior consistently with the app's actual enforced policy; if equivalent Post CRUD is currently public, document and test that rather than claiming readers/members/admins are enforced. If testing requires changing fixtures for the new valid relationships, preserve existing coverage rather than deleting or weakening assertions.
- Run the full app suite, report actual before/after counts (expected pre-feature baseline: 36 passing; investigate any discrepancy), and inspect real browser behavior. Browser checks must cover Tags navigation/management; creating a Post with two Tags; editing the selection; clearing all; re-adding; invalid form submission retaining fields/selections; persisted names on list/show after refresh; Comments still visible; and auth/logout/CSRF and permission behavior. HTTP 200 or green generated specs alone are not proof of a working tagging UI. If no browser tool is available, explicitly report that verification gap rather than claiming completion.

Finish with a concise change summary, exact commands/tool calls and test results, migration round-trip and seed-repeat evidence, app URL and browser checks, and any remaining limitations. Keep the feature small enough to explain on stage.
```

<details>
<summary><strong>If asked — why a join model, unique constraints and an atomic save?</strong></summary>

A Post can have several Tags, and a Tag can belong to several Posts: that is
many-to-many. **PostTag** stores the relationships as real rows, not a comma list
of names on the Post. It also gives us a place to enforce valid parent IDs and
one row per Post/Tag pair.

Model validation provides useful form errors. Database foreign keys and unique
indexes protect the stored structure, including callers that bypass model
validation. This SQLite app explicitly enables FK enforcement on its JDBC
connections; a declared FK alone was not accepted as proof. Do not describe the
SQLite-specific join DDL as verified across every database.

Saving the Post and replacing its join set must be atomic: either all of that
change survives or none does. The tests forced a **second join** to fail after
other writes had happened, then verified rollback of both the Post and joins.
Rejecting invalid input before writing is useful, but is not that same proof.

The prompt asks for bounded app changes and preservation of Comments, auth,
CSRF and existing tests. It doesn't ask the agent to redesign the framework,
upgrade dependencies or introduce admin roles. Explain those boundaries while
work runs; if it takes too long, disclose the prepared result rather than
pretending the entire implementation happened instantly.

</details>

### 8.4 Review the work before declaring it done

1. Inspect Tag's required name/max-30/unique-slug schema and validation, plus the
   real PostTag table, FKs and unique pair constraint. Verify both association
   directions from a fresh request.
2. Inspect migration **latest → down → up** evidence before seeds. For multiple
   new migrations require a dependency-safe round-trip of every new migration.
   Do not roll back the pre-existing Post/Comment/User/Product migrations.
3. Confirm the convention seed resolves actual Post/Tag IDs and adds useful
   associations without deleting unrelated data. Re-run the completed seed:

```bash
wheels seed --mode=convention
```

```bash
wheels seed --mode=convention
```

4. Confirm the second run changes no Post/Tag/join counts and creates no duplicate
   pairs. Counts depend on the implemented seed; the old one-Tag **1/0 → 0/1**
   and **46-spec** results are historical, not the acceptance target.

```bash
wheels reload
```

```bash
wheels test
```

5. Record actual final test totals; expect the **36-test baseline plus meaningful
   new tests**, not a predetermined count. Read failures and inspect committed
   records; green scaffold specs alone do not prove a relationship feature.

### 8.5 Browser finish line

1. **Tags** navigation opens usable management; create/edit a Tag, show required,
   maximum-length and duplicate-slug errors, and verify safe deletion behavior.
2. Create a Post with **two** existing Tags; refresh list/show and read their names.
3. Edit that Post, see the saved selection, change it, save and refresh.
4. Clear **every** Tag, save and refresh. Re-add a Tag after clearing.
5. Submit an invalid Post while tags are selected: errors appear and fields and
   valid selections survive. The previously saved join set must not change.
6. Confirm Comments remain visible and usable; registration/login/logout and
   CSRF handling still work. Verify permission behavior matches the actual app:
   the temporary Post policy gate was removed in 5.9, not secretly restored.
7. Show the repeat-seeded Post/Tag associations from a new browser request.

**Say:** “The agent added a feature to our existing app, not another disconnected
scaffold. Wheels supplied conventions and tools; persisted data, tests and the
browser tell us whether the change works.”

<details>
<summary><strong>If asked — clearing tags, validation failures and deleting relationships</strong></summary>

A browser can omit a multi-select field when nothing is selected. Our form's
contract treats that as **clear all**, not “leave the old tags alone.” On desktop,
use Cmd/Ctrl selection as appropriate to toggle options; then save and refresh.
A persisted empty set and successful re-add matter more than a dropdown that
merely looks empty before submission.

An invalid edit keeps the user's fields and valid submitted selections visible,
while the database keeps the **old saved Post and join set**. These are different
states, deliberately: useful error recovery must not mean partial persistence.
Repeated IDs are deduplicated; malformed or nonexistent IDs are rejected.

Tags and join edges in this implementation delete physically. Assigned Tags
refuse deletion; clearing an assignment removes its join, so re-adding cannot
collide with a hidden soft-deleted join. Posts keep their existing soft-delete
behavior and clean up their tag joins. We did not silently change how Comments
are deleted or reactivate the earlier policy gate.

The original 36 tests are still present. The 61 additional tests made 97, but
**97 is a measured result, not a target to game**. Browser checks, database
constraints, repeat seeds and protected-file hashes are separate evidence.
Keep the later unexplained missing-WO 500 caveat distinct from these functional
passes and from deliberate invalid-CSRF probes.

</details>

### Closing the demo — one sentence per result

**Say:** “We started with a new app, generated a real resource, changed its rules,
connected Comments, demonstrated login and explicit policies, broke and repaired
a test, added a JSON API, and had Harness integrate Tags into the Post UI. The
conventions saved typing; the database, tests and browser told us what actually
worked.”

If a beat was shortened or a prepared app was used, name that honestly. The final
app has public Post/Tag CRUD after the deliberate policy-test boundary; don't
call it production-ready. For follow-up questions, point to **guides.wheels.dev**,
**blog.wheels.dev**, and **github.com/wheels-dev/wheels**. The original title and
release slides are not required to deliver this demo or its explanation.

## If it goes sideways

<details>
<summary><strong>Presenter recovery card — stay in the right app and preserve evidence</strong></summary>

**Recorded final rehearsal app:** `$HOME/GitHub/_demo/cfugdemo20260915040245`,
served at `http://localhost:8092` during validation. This is a reference to that
completed app, **not an instruction to replace the new app's exported name**.
Verify it before the meeting; its presence does not reserve a free port or prove
it is still running. If it occupies 8092, choose a different free port for the
fresh build. Use separate prepared terminals so directory and URL cannot drift.

Useful landmarks in that recorded app—not IDs to assume in a fresh build:

| Page | What was checked |
|---|---|
| `/posts/11` | Hello, Wheels with its three repeat-seeded Tags |
| `/posts/3` | An existing Post with two Comments; Hello, Wheels had none |
| `/posts/24` and its edit form | Reviewer's Tag assignment/clear/re-add and validation proof |
| `/tags` | Tag management |
| `/login` | Existing session login/logout |

The final app is already beyond every generation step. Don't rerun the agent
prompt, blindly apply down migrations or claim its 97 tests are the fresh
27-test baseline. Switch to it to show a prepared result, and say that you did.
It also carries the unresolved stability caveat below.

**Expected failures:** the body test goes red on purpose; missing SKU returns
422; the policy denies with 403; a deleted record returns 404. An unexpected
error is different. Preserve the first response, message, stack and timing before
refreshing it away. Use the error page's **Copy** JSON button when available;
redact credentials and sensitive request details before projecting or sharing.
For missing WO, also note recent reload/test requests and whether the client was
in test context. Neither a reload nor the later passing replay was verified as
a fix for that intermittent error.

</details>

| Symptom | Check / recovery |
|---|---|
| HTTP port occupied | Choose a free port; update DEMO_PORT and DEMO_URL before start. Never kill an unrelated app or reset the registry. |
| Registration belongs to an older rehearsal | Use the new timestamped app name; keep the older app intact. |
| Page 500s after an edit | Read the error, check the named file and run `wheels reload`; don't treat every 500 as a cache issue. |
| Tests fail after policy demo | Remove ONLY the demo authorizePost filter/helper and any leftover one-action gate; retain requireRecord/auth/CSRF/comments. |
| First test fails | Investigate actual fixtures and test-app isolation. Do not delete the database or hide the failure with a warm-up run. |
| API ID capture fails | Inspect api-product.json and the POST status. Fix the request; do not fall back to `/1`. |
| Agent tools missing | Reconnect in the correct app and inspect discovery; disclose CLI fallback if needed. Setup writes config, not a live connection. |
| Seeds claim success but UI is empty | Check committed rows in a separate request and actual FK targets; command success is not persistence proof. |
| Tag form cannot clear all | Fix omitted/empty selection handling and test refresh plus re-add; do not omit this acceptance check. |
| Can't diagnose promptly on stage | Switch to the separately rehearsed app and disclose the fallback. Later beats depend on earlier schema/data; do not pretend all beats stand alone. |

## Current end-to-end validation record

**Observed 2026-09-15**, in a fresh app created by the current Homebrew install.
No framework/CLI source overlay was used. These are current measurements, not
inherited build-2488 counts. The independent agent's Tags implementation was
followed by a separate reviewer repeating the browser acceptance and the exact
Beat 8.4 commands, then checking persisted data and protected-source hashes.
The opening blocks and expandable explanations added afterward are commentary
only: all 87 existing fenced blocks, including the 67 Bash commands and exact
Harness prompt, were preserved. Optional Q&A is not additional executed coverage.

| Checkpoint | Current result |
|---|---|
| CLI / framework / Java / engine / DB / URL | **PASS:** Homebrew CLI and packaged app framework **build 2500**; running server executable verified as **Homebrew OpenJDK 21.0.12.1**; **Lucee 7.0.0.395**, SQLite; **http://localhost:8092** (shutdown 8093). |
| Unique-name preflight and explicit HTTP port | **PASS:** fresh `cfugdemo20260915040245` in `$HOME/GitHub/_demo`; no reuse of the prior app/registry/test DB. |
| Dry-run, generation and routes | **PASS:** dry-run listed **11 paths**, wrote no Post model (base `Model.cfc` remained); **41** initial routes; **16** filtered Post routes after generation. |
| Post/Comment/auth/Product migrations before data | **PASS:** each new migration completed **latest → down → up** before its seed or browser/API writes. |
| Starter, local docs and debug UI | **PASS:** branded details page; Guides/API cards opened local `/wheels/guides` and `/wheels/api` tabs, **200** with expected titles; timing/params/routes/complexity panels opened. |
| Post CRUD and validation | **PASS:** first seed **10 Posts** with datetimes; Hello, Wheels created/edited and retained; separate throwaway deleted then **404**; blank form showed two presence errors without an exclusion error; Untitled rejected as reserved. |
| Comments and console | **PASS:** second seed **20 real rows**; **21 live Posts / 10 Comments / 0 orphan Comments** before the browser addition. Blank Comment retained selected Post 3; valid Comment appeared on its parent. All three console expressions passed, including **Post Title 3** and the Wheels title search. |
| Auth and five-step policy arc | **PASS:** register/logout/bad login/good login/logout; stored bcrypt **60 characters, `$2a$10$`**. Unused policy: all 200; one-action gate: **200/403/200**; all-action gate: **403**, missing record **404**; guest reads **200**, writes **403**; member new/edit **200**, actual edit persisted, delete **403** with row retained. Admin promotion was **not staged**. |
| Policy/test boundary | **PASS:** removed only the demo authorizePost filter/helper; retained requireRecord, Comments wiring and auth/CSRF behavior. Post CRUD returned to its generated public behavior; the retained policy alone is not enforcement. |
| Naturally fresh test DB; intentional red and restored green | **PASS:** first run **27 passed**; added body spec **28 passed**; removed only body presence **27 passed / 1 failed**, `requires a body`, exit **1**; restored rule **28 passed**. No test-DB deletion or hidden warm-up. |
| Info/diff/coverage | **PASS:** info identified this app/port; diff reported **no differences**; coverage reported **61 counters, 6/47 files** and its suite request returned **200**. |
| Product API, exact runbook commands | **PASS:** **422 → 201 → 200 → 200 → 422 → 404 → 204 → 404** for invalid create/create/list/update/invalid update/missing/delete/deleted GET. Actual ID captured from the **PRODUCT** wrapper; no assumed `/1`. |
| Pre-Tags baseline | **PASS: 36/36**. |
| Copyable-runbook static checks | **PASS, independently checked:** **67 Bash blocks**, one logical command each; Bash syntax valid, no destructive reset commands, and embedded/standalone Harness prompts identical. |
| setup agents creation/repeat | **PASS:** correct `.mcp.json` and `.opencode.json` generated in the app; repeat reported **Already configured**. |
| setup agents safety probes | **PASS in a separate marked fixture:** other servers and unrelated top-level values survived; wrong Wheels entry corrected; repeat left both files byte-stable. Malformed OpenCode JSON caused nonzero failure with **both files byte-unchanged**. Active app configuration was not modified by these probes. |
| Actual stdio MCP discovery | **PASS:** **19 advertised tools**; routes and info identified this app and its Post/Comment/Product routes on **8092**. This does **not** establish Harness GUI automatic config loading. |
| Tags implementation transport | **PASS via disclosed CLI fallback:** the independent agent executed the exact standalone prompt using the real Wheels CLI because native Wheels MCP tools were unavailable in its session. Separate stdio discovery passed; no native Harness GUI connection is claimed. |
| Tags schema and migrations | **PASS:** required name/max 30 and unique slug; persisted PostTag FKs, unique pair and reverse index; both association directions. Two new migrations completed **latest → down join → down Tags → up Tags → up join before seeding**, without rolling back earlier migrations. |
| Actual database constraints | **PASS:** dev/test JDBC `PRAGMA foreign_keys` returned **1**; raw orphan inserts were rejected; slug/pair uniqueness and Tag **RESTRICT** / physical Post **CASCADE** enforced. Final audit found **zero FK violations, orphan joins or duplicate pairs**. |
| Atomic assignment and deletion behavior | **PASS:** create/edit/clear/re-add and invalid IDs; injected failure on a second join rolled back both Post and joins. Invalid browser edits preserved entered fields/valid selections while retaining the exact old persisted Post fields and join identity. Tags/joins delete physically; Post soft-delete cleans its joins without changing existing Comment behavior. |
| Convention seeds | **PASS:** initial seed **6 created / 0 skipped** (3 Tags, 3 joins), immediate repeat **0 / 6**. After both browser passes, the reviewer executed each literal Beat 8.4 convention-seed command: **0 / 6**, then **0 / 6**; counts remained unchanged through seeds, reload and tests. Existing Posts were resolved by attributes, not hard-coded IDs. |
| Final durable row counts | **24 physical Posts (including 1 pre-existing soft-deleted row), 11 Comments, 1 User, 1 Product, 3 Tags, 6 PostTags**. The agent and reviewer each retained one browser-proof Post. Hello, Wheels has three Tags; the reviewer's **Presenter final tagging check** has CFUG Demo. No unrelated records were removed. |
| Tags final app tests | **PASS: 97/97**, repeated by the agent and then independently via the literal Beat 8.4 `wheels test` (**1.25 s**). Existing 36 specs retained; **61 new BDD examples: 38 model/service/DB + 23 controller**. |
| Agent browser verification | **PASS: 19 checks**, covering Tags management, escaped names, Post create/edit/clear/re-add, invalid/malformed/nonexistent selections, assignment preservation, assigned/unassigned deletion and slug reuse, existing Comments, login/logout and CSRF no-mutation checks. |
| Independent reviewer browser verification | **PASS:** navigation; required/max-30/duplicate validation (server length checked with 31 characters after bypassing HTML maxlength); two-Tag Post creation, preselection/replacement/clear/refresh/re-add; invalid Post preserves fields/selections and original DB state; list/show labels; Hello, Wheels seeded Tags; Post 3 Comments; existing login/logout and public guest edit. Screenshots inspected. These are separate checks, not added to the agent's count of 19. |
| Protected-source audit | **PASS:** all **10 protected existing app source files** and **1,717 vendor files** matched their pre-feature hashes. No framework/CLI upgrade, source overlay, commit or push was needed. |
| Later stability check | **UNRESOLVED:** one later `GET /posts/11` returned **500**, with server log at **04:46:32** reporting missing key `WO`; the initial response body was not retained. Immediate subsequent requests returned 200. Three planned full-test → fresh-HTTP replay cycles each passed **97/97**, with **9/9 replay requests returning 200**. The intermittent failure was not reproduced or fixed. |

### Stability note — one unexplained intermittent HTTP 500

After the functional, test and source-hash checks passed, one extra request to
`/posts/11` returned **500**. The server log recorded `key [WO] doesn't exist` at
04:46:32; the original response body was discarded, so the available evidence is
limited. Immediate follow-up requests succeeded. Three further complete test runs
followed by fresh HTTP checks passed **97/97 each** and **9/9 HTTP 200** in total.

A read-only audit found no direct deletion/reload of `application.wo` in the new
app code/specs, but **the cause remains unknown**. This does not establish whether
the fault belongs to the Tags feature, framework lifecycle, or something else.
No fix or reliable workaround was verified. Keep a rehearsed fallback available;
do not describe the later green runs as proof that the intermittent failure is
resolved. The functional passes above remain valid, with this stability caveat.

### Scope and limitations of this run

- **SQLite-specific implementation:** the join migration uses reversible explicit
  SQLite DDL; app-only datasource configuration enables `foreign_keys=on` for dev
  and test connections. Enforcement was checked through actual JDBC requests.
  No portability claim is made for other databases or engines.
- **Tools:** implementation used the real CLI fallback. The independently verified
  19-tool stdio server is not evidence that Harness automatically loaded either
  generated config file or exposed native MCP tools to the implementing agent.
- **Authorization:** Post and Tag CRUD are public after the deliberate removal of
  the demo policy gate in 5.9. The retained policy is not active enforcement; no
  role column/admin promotion or production authorization hardening is claimed.
- **CSRF:** invalid development-mode requests produced **HTTP 500 with
  Wheels.InvalidAuthenticityToken**, with **no mutation**. The existing behavior
  was preserved; this run does not claim a 403 response for those requests.
- **Implementation was iterative:** a transient seed-source compile error, an
  HTML-encoding expectation in one new spec, and a browser assumption about which
  existing Post had Comments were corrected before the final passes. Final green
  does not mean every intermediate attempt succeeded. The intentional Beat 6 red
  result remains a separate, expected demonstration.

**Historical only:** build 2488's 2026-09-13 run reached 36 specs after the API and
46 after an independent Tag scaffold/convention seed. That did not implement
Post↔Tag assignment and is not evidence for this revised Beat 8. Earlier build
2482 failures and separately patched MCP/seed evidence remain in [demo.md](demo.md).

## The one-line takeaways

1. **New:** a full app, docs included, from one command.
2. **Scaffold:** a declaration becomes schema, model, validation and routes.
3. **Own it:** add a business rule; the existing form enforces it.
4. **Associations:** scaffolding the child wires the parent too.
5. **Auth/policy:** bcrypt sessions; explicit gates; readers read, members write,
   admins delete by policy design (no admin promotion claimed).
6. **Tests:** a real regression goes red; restoring the rule goes green.
7. **API:** same models and validation, JSON responses with meaningful status codes.
8. **AI:** verified tools plus a precise prompt deliver Tags on real Posts.
