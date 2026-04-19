# verify-docs — Metadata Reference

Every non-illustrative code block in the v4 guides carries a `{test:*}` meta
string the harness uses to validate it. Three flavors. The harness ignores
any fenced code block that does not carry a `{test:*}` meta flag.

**Driver status:** Phase 0 ships drivers for `{test:compile}` and `{test:cli}`.
`{test:tutorial}` is documented below but its driver lands in Phase 1 —
content authored now with `{test:tutorial}` will fail until Phase 1 ships.

## `{test:compile}`

The block is written to a temp file and compiled against Lucee 7 via the
`wheels` CLI. Pass if compilation succeeds.

```cfm {test:compile}
component extends="Model" {
  function config() {
    validatesPresenceOf("title");
  }
}
```

## `{test:cli cmd="..."}`

The `cmd` is tokenized on whitespace and executed in a fresh fixture app.
Optional attrs:

- `asserts-stdout="text"` — stdout must contain `text`.
- `asserts-exit=N` — process must exit with code `N` (default 0).
- `step=N` — cumulative ordering within a file.

```bash {test:cli cmd="wheels dbmigrate latest" asserts-stdout="Migrating up"}
wheels dbmigrate latest
```

**Shell features not supported.** No pipes, redirects, `&&`, or quoted args
with spaces. The harness spawns the program directly. Authors who need
shell features must restructure the example or mark it illustrative.

## `{test:tutorial step=N file="path"}` — lands in Phase 1

Contents of the block are written to `file` inside the tutorial's fixture
app at step N. Follow-up CLI commands (`{test:cli step=N}`) see this state.
Phase 0 does not implement this driver; documented here so Phase 0 sample
content can forward-reference it.

## Shared attrs

- `step=N` — cumulative state ordering. Lower N runs first.
- `title="..."` — consumed by Starlight for code-block titles; ignored by the harness.

## Illustrative blocks

Blocks that cannot or should not compile:

```cfm title="illustrative — do not type"
someAPI.callThat.doesntExistYet();
```
