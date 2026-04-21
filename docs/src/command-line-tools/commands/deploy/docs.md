# `wheels deploy docs`

Print embedded topic documentation.

## Synopsis

```bash
wheels deploy docs [<section>]
```

## Description

Ships a small set of topic-specific Markdown docs inside the CLI itself. Running `wheels deploy docs` with no argument prints a list of available sections. Passing a section name prints that section's Markdown content to stdout.

This is a convenience — the full user-facing documentation lives on the docs site.

## Available sections

- `accessories` — sidecar container config
- `builder` — image building options
- `env` — environment variable layering
- `hooks` — lifecycle hooks
- `proxy` — `kamal-proxy` config
- `registry` — Docker registry config
- `servers` — roles and hosts
- `ssh` — SSH options

## Examples

```bash
wheels deploy docs
wheels deploy docs hooks
wheels deploy docs servers | less
```
