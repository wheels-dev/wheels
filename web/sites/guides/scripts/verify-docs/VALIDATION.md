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

## Which `wheels` binary the harness runs

Every spawned `wheels` command resolves to one binary, picked once at
startup (`lib/exec.mjs`, `resolveWheels()`), in this order:

1. `WHEELS_BIN` — absolute path to a `wheels` binary; takes precedence
   over everything else when set.
2. `command -v wheels` — whatever is first on `PATH`.
3. Homebrew bin dirs (`/opt/homebrew/bin`, `/usr/local/bin`,
   `/home/linuxbrew/.linuxbrew/bin`).

This covers the long-lived tutorial dev server too: `{test:tutorial}`
`asserts-http` blocks boot the fixture app by spawning the same resolved
binary (`drivers/tutorial.mjs`, `ensureServer()`), not a fresh `PATH`
lookup — so `WHEELS_BIN` redirects it like every other spawn.

`verify-docs.mjs` prints an attestation line at run start stating the
resolved path, how it was resolved, and the binary's `--version` output:

```
verify-docs: wheels binary: /opt/homebrew/bin/wheels (via PATH discovery) — ...
```

A green run only attests to the binary named on that line.

**CI implication:** `.github/workflows/docs-verify.yml` installs the
**released** brew CLI and does not set `WHEELS_BIN`, so a green CI run of
`{test:cli}` / `{test:compile}` / `{test:tutorial}` blocks attests to the
released CLI — not to a CLI built from the PR's checkout. Wiring CI to a
branch-built CLI (so a CLI behavior change in a PR can flip a cli block
red) is tracked in [#3042](https://github.com/wheels-dev/wheels/issues/3042).
To attest to a locally built CLI, point `WHEELS_BIN` at it before running
the harness.

## Running the harness locally

The drivers spawn `wheels new` into a temp directory per test. `wheels new`
needs a `vendor/wheels/` source tree, and a temp directory has none in its
ancestry. Point the CLI at this repo's checkout before running either the
harness unit tests or the full content gate:

```sh
export WHEELS_FRAMEWORK_PATH="$(git rev-parse --show-toplevel)/vendor/wheels"
pnpm --filter @wheels/guides test:docs-harness   # harness unit tests
pnpm --filter @wheels/guides verify:docs         # full content gate
```

Without `WHEELS_FRAMEWORK_PATH`, `wheels new` prints a framework-not-found
error and exits 0 anyway; the harness detects the missing fixture directory
and throws with a pointer back to this doc rather than surfacing a
misleading `spawn … ENOENT` on the next child process.
