# verify-docs — Metadata Reference

Every non-illustrative code block in the v4 guides carries a `{test:*}` meta
string the harness uses to validate it. Three flavors. The harness ignores
any fenced code block that does not carry a `{test:*}` meta flag.

**Driver status:** Phase 1 ships drivers for `{test:cli}`, `{test:tutorial}`,
and `{test:compile}`.

## `{test:compile}`

The body is handed to `wheels cfml <body>`. Pass if exit code 0. Fail if
non-zero. Requires [LuCLI PR #1](https://github.com/lucee/LuCLI) which
makes `wheels cfml` exit non-zero on execution failures.

On older LuCLI versions (where `wheels cfml` always exits 0 regardless
of CFML errors), the driver falls back to a pattern-match validator —
currently only a bracket-balance check. The mode is detected once per
harness run via a probe (`wheels cfml 'throw()'` — if it exits 0,
fallback; if non-zero, native).

```cfm {test:compile}
component extends="Model" {
  function config() {
    validatesPresenceOf("title");
  }
}
```

**Fallback-mode caveat:** The bracket check catches obvious typos but
does NOT validate CFML syntax or semantics. A block like
`hasMany("comments", dependent="delete")` (mixed positional + named
args — a real Wheels anti-pattern) passes the fallback but would fail
a real parse. This is acceptable: fallback buys you typo detection
while we wait for PR #1 to land.

## `{test:cli cmd="..."}`

The `cmd` is tokenized on whitespace and executed in a fresh fixture app.
Optional attrs:

- `asserts-stdout="text"` — stdout must contain `text`.
- `asserts-stderr="text"` — stderr must contain `text`.
- `asserts-output="text"` — stdout *or* stderr must contain `text` (forgiving default when the author doesn't care which stream).
- `asserts-exit=N` — process must exit with code `N` (default 0).
- `step=N` — cumulative ordering within a file.

The `wheels` CLI writes user-facing reports to stderr for some commands
(e.g. `wheels info`) and stdout for others (e.g. `wheels --version`).
Reach for `asserts-output` when you don't want your test coupled to that
stream distinction.

```bash {test:cli cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
wheels dbmigrate latest
```

**Shell features not supported.** No pipes, redirects, `&&`, or quoted args
with spaces. The harness spawns the program directly. Authors who need
shell features must restructure the example or mark it illustrative.

## `{test:tutorial step=N file="path" [mode="write|append"] [asserts-http="..."] [asserts-db-rows="..."]}`

The block body is written to `file` inside the tutorial's shared fixture app
at step N. The fixture is one long-lived `blog-tutorial` app reset at the
start of each harness run; all tutorial blocks (from all tutorial files) and
all `{test:cli step=N}` blocks see the same fixture state in cumulative
step order.

Required attrs:

- `step=N` — integer ordinal. Lower N runs first within a file; tie-break by
  file line.
- `file="relative/path"` — path inside the fixture (relative to the app
  root). Paths that escape the fixture root are rejected.

Optional attrs:

- `mode="write"` (default) — write the body, clobbering any existing file.
- `mode="append"` — append the body to the existing file.
- `asserts-http="METHOD PATH → STATUS"` — after the file is written, boot the
  app server (once per run) and hit this URL, asserting the status code.
- `asserts-http="METHOD PATH → STATUS \"body substring\""` — also asserts the
  response body contains the substring.
- `asserts-db-rows="table1=N,table2=M"` — after the file is written, assert
  `SELECT COUNT(*)` equals N for each table.

**Note:** `asserts-db-rows` is implemented but not exercised by any sample
page yet. First use may reveal adjustments needed in the `wheels cfml`
invocation. File a bug if it misbehaves.

Ordering across files is by (frontmatter sidebar.order, step, file line).

```mdx
```cfm {test:tutorial step=2 file="app/controllers/Posts.cfc" asserts-http="GET /posts → 200"}
component extends="Controller" {
    function index() { posts = model("Post").findAll(); }
}
```
```

## Shared attrs

- `step=N` — cumulative state ordering. Lower N runs first.
- `title="..."` — consumed by Starlight for code-block titles; ignored by the harness.

## Illustrative blocks

Blocks that cannot or should not compile:

```cfm title="illustrative — do not type"
someAPI.callThat.doesntExistYet();
```
