# verify-docs — Metadata Reference

Every non-illustrative code block in the v4 guides carries a `{test:*}` meta
string the harness uses to validate it. Three flavors. The harness ignores
any fenced code block that does not carry a `{test:*}` meta flag.

**Driver status:** Phase 1 ships drivers for `{test:cli}`, `{test:tutorial}`,
and `{test:compile}`.

## `{test:compile}`

The contract is **parse/compile, never execute**. Doc snippets are
fragments — models without an app, `set()` calls without a config file,
`describe()` without a test runner — so executing them in a bare engine
can only fail on missing context (see issue
[#3041](https://github.com/wheels-dev/wheels/issues/3041)). Instead the
driver wraps each body by sniffed kind so the engine compiles it without
running it, then invokes `wheels cfml <wrapped>`. Pass if exit code 0.

Wrap kinds (`drivers/compile.mjs`):

- **component** — the body declares `component`/`interface` in script
  syntax. The declaration header is stripped and each declaration's inner
  body is wrapped in its own never-invoked function shell. The engine
  compiles the whole script before executing anything, so syntax errors
  fail while framework functions (`validatesPresenceOf`, `hasMany`, …)
  are never resolved. *Limitation:* typos in the header itself (e.g. the
  `extends` target) are not checked; top-level `property` declarations
  are neutralized before wrapping.
- **tag** — the body starts with `<` (tag CFML, view templates, or an
  author-supplied `<cfscript>` wrapper). The engine wraps inline code in
  `<cfscript>…</cfscript>`, so the driver closes that wrapper and emits
  the body inside `<cfif false>…</cfif>`: compiled in template context
  (catching mismatched tags, bad expressions inside `<cfoutput>`, …),
  never executed, and never double-wrapped in `<cfscript>`.
- **script** — everything else (config fragments, spec fragments, plain
  script). Wrapped in a single never-invoked function shell. `var` at the
  top level is legal inside the shell, matching how the framework runs
  `config/services.cfm` and friends.

The native path needs `wheels cfml` to exit non-zero on errors (wheels
CLI 4.0.3+). On older CLIs where `wheels cfml` always exits 0, the
driver falls back to a bracket-balance check. The mode is detected once
per harness run via a probe (`wheels cfml 'throw(message="probe")'` —
exit 0 ⇒ fallback; non-zero ⇒ native).

```cfm {test:compile}
component extends="Model" {
  function config() {
    validatesPresenceOf("title");
  }
}
```

**What this does and does not verify:** a passing block is syntactically
valid CFML in its declared shape — it parses and compiles. It is NOT
executed, so semantic mistakes (mixed positional + named args, phantom
helper names, wrong argument values) still pass. Behavioral verification
belongs to `{test:cli}` / `{test:tutorial}` blocks.

**Fallback-mode caveat:** the bracket check catches obvious typos but
does not validate CFML syntax at all. Treat fallback results as
advisory.

## Expected failures (allowlist)

`scripts/verify-docs/expected-failures.json` masks known-failing blocks
so CI can gate the live tree while individual blocks are being fixed.
Override the file path with `VERIFY_DOCS_ALLOWLIST`. Shape:

```json
{
  "entries": [
    {
      "file": "src/content/docs/v4-0-0/basics/routing.mdx",
      "bodySha256": "0123abcd4567",
      "reason": "fragment needs surrounding app context; rewrite pending",
      "issue": "#3041"
    }
  ]
}
```

- `file` — path suffix of the page (conventionally relative to
  `web/sites/guides/`).
- `bodySha256` — first 12 hex chars of the sha256 of the block body.
  Every failing block's hash is printed in the report, so entries are
  copy-pasteable. Keying on content (not line numbers) keeps entries
  stable across unrelated page edits and forces re-verification the
  moment the block changes.
- `reason` — required, non-empty.
- `issue` — required, `#NNNN` or a GitHub issue/PR URL.

Allowlisted failures are reported in their own section and do not affect
the exit code. An entry whose block now **passes** produces a stale-entry
warning; on full-tree runs, entries matching no block at all produce an
orphan warning. Both warnings ask you to delete the entry. An invalid
allowlist file (missing reason, bad issue ref, malformed JSON) makes the
harness exit 2 before running anything.

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
resolved path, how it was resolved, the binary's `--version` output, and
the **mode** — whose CLI code the binary dispatches to:

```
verify-docs: wheels binary: /opt/homebrew/bin/wheels (via PATH discovery) — Wheels Version: 4.0.3 — mode: as-installed (no module overlay declared)
```

A green run only attests to the binary + mode named on that line. The mode
comes from `WHEELS_ATTEST_MODE` (free-form text, set by whoever arranged a
non-default module); when unset it reports `as-installed`.

**CI (#3042):** the `wheels` CLI is the released LuCLI runtime plus a CFML
module, and that module is this repo's `cli/lucli/`. `.github/workflows/docs-verify.yml`
installs the released brew CLI, then **overlays the checkout's `cli/lucli/`
(plus `vendor/wheels/`) onto `$HOME/.wheels/modules/wheels`** before any
command runs, and sets `WHEELS_ATTEST_MODE` accordingly. So a green CI run
of `{test:cli}` / `{test:tutorial}` blocks attests to the PR branch's CLI
module on the released runtime — a branch change to a command's behavior
flips its block red. Two caveats: the LuCLI runtime itself stays at the
released version (runtime changes ship via LuCLI releases, not this repo),
and bare `wheels --version` / `wheels --help` are intercepted by the brew
wrapper script before the module is consulted, so those two surfaces still
answer with released wrapper text.

To attest to a locally built CLI, point `WHEELS_BIN` at it (and set
`WHEELS_ATTEST_MODE` to describe it) before running the harness.

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

### Local listeners on port 8080 (and other common ports)

`wheels new` pins port 8080 in every scaffold's `lucee.json`, and the CLI's
server detection trusts an open pinned port unconditionally. The harness
therefore rewrites every fixture's `lucee.json` to closed ephemeral ports
right after `wheels new` (`scrubFixturePorts` in `lib/fixtures.mjs`), so the
documented no-running-server refusal blocks (`wheels routes`,
`wheels migrate info`, `wheels seed`) stay deterministic even when the repo's
demo app, `docker-compose.dev.yml`, or any unrelated service occupies 8080.

One residual gap on **released** CLIs up to 4.0.3: read-side commands
(`wheels routes` on 4.0.3; any command behind the read-side gate once #3080
ships) fall back to probing the common ports 8080/60000/3000/8500 even when
the project pins a different port, so a stray listener there can still turn
that refusal block red locally (symptom: `Failed to parse routes response`
instead of the refusal text). Free those ports or point `WHEELS_BIN` at a
CLI that includes the pinned-port fix (`detectServerPort` skips the probe
whenever the project pins a port — shipped together with this harness
change). CI is unaffected: the module overlay always carries the fix.
