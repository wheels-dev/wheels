# article-tests

A standalone harness for validating blog-post code snippets against the live
Wheels framework code without booting a full Wheels app, web server, or test
runner. Originally built to validate every claim in
[Skip the Plugin: Building a Rate-Limited API in Wheels 4.0][post] before
publishing.

## When to use this

Reach for `tools/article-tests/` when you are writing a blog post that
demonstrates middleware, helpers, or other CFCs that can be exercised in
isolation — no controller dispatch, no database, no HTTP layer. It is
deliberately *not* a substitute for `tools/test-matrix.sh`; the framework
test suite still owns full integration coverage. This harness is for the
narrow case where you want quick, deterministic validation of the exact
snippets that will end up in a published article.

## Running

```bash
# from anywhere in the repo
tools/article-tests/run.sh
```

The script picks up BoxLang from `$PATH` or `/opt/boxlang/bin/boxlang`. It
runs from the project root with a custom `boxlang.json` that maps `/wheels`
to `vendor/wheels` so the dotted-path imports inside `run.cfm` resolve.

## What's in here

- `run.cfm` — the harness itself. Twenty-plus inline tests that construct
  middleware components, drive synthetic request structs through them, and
  assert observable behavior. New tests follow the same `test("name", fn)`
  shape.
- `edge-cases.cfm` — additional probes for boundary conditions
  (`windowSeconds=0`, missing `cgi` key, empty `keyFunction` return). Useful
  when an article should mention what happens at the corners.
- `Probes.cfc` / `Probe.cfc` — small helper components. `Probes.cfc` wraps
  constructors that touch frameworks under test, because BoxLang 1.5's
  bytecode generator currently crashes when a top-level closure body wraps
  `new wheels.X(...)` in a try/catch with chained property access on the
  caught exception.
- `boxlang.json` — runtime config: defines the `/wheels` mapping, points
  `classPaths` at `vendor/`, and sets logging conservatively so test output
  isn't drowned by framework logs.
- `run.sh` — entry-point wrapper.

## Adding new tests

Lift the snippet you intend to publish verbatim. Wrap it in a `test(...)`
call. Assert observable behavior with the harness's tiny matchers
(`assertEquals`, `assertContains`, `assertTrue`, `assertFalse`). If the
matched behavior depends on framework state that this harness can't bootstrap
(a live `application` scope, a routed dispatch), either pull that section
of the article down to a unit-of-merge-logic equivalent (see the
`scoping.cfc` test in `run.cfm`) or fall back to the full engine matrix.

[post]: ../../web/content/blog/posts/skip-the-plugin-rate-limited-api.md
