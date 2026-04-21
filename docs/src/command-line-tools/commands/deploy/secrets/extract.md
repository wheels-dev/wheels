# `wheels deploy secrets extract`

Extract a single key's value from a `KEY=VALUE` text block.

## Synopsis

```bash
wheels deploy secrets extract --key=<KEY> --from="<block>"
```

## Description

Given a multi-line `KEY=VALUE` text block (typically the output of `wheels deploy secrets fetch`), prints the value associated with `--key`. Returns empty if the key isn't present.

Chains cleanly with `fetch` for pipeline-friendly secret resolution:

```bash
ALL=$(wheels deploy secrets fetch --adapter=op --from=Deploy KEY1 KEY2)
KEY1_VALUE=$(wheels deploy secrets extract --key=KEY1 --from="$ALL")
```

## Flags

| Flag | Description |
|------|-------------|
| `--key=<name>` | **Required.** Key whose value to extract. |
| `--from="<block>"` | **Required.** KEY=VALUE text block to search. |

## Examples

```bash
wheels deploy secrets extract \
  --key=DATABASE_URL \
  --from="DATABASE_URL=postgres://...
OTHER=x"
```
