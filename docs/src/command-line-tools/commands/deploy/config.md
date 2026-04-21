# `wheels deploy config`

Print the resolved deploy configuration as YAML.

## Synopsis

```bash
wheels deploy config [--destination=<name>]
```

## Description

Loads `config/deploy.yml`, applies the `--destination` overlay if given, resolves Mustache expressions, and prints the effective configuration. Useful for verifying destination overlays and diffing between environments.

Secrets are **not** expanded — their names appear as written. Use `wheels deploy secrets print` to resolve `.kamal/secrets`.

## Flags

| Flag | Description |
|------|-------------|
| `--destination=<name>` | Overlay `config/deploy.<name>.yml` on top of the base. |
| `--configPath=<path>` | Alternate path. |

## Examples

```bash
wheels deploy config
wheels deploy config --destination=staging
diff <(wheels deploy config --destination=staging) <(wheels deploy config --destination=production)
```
