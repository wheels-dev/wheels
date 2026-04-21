# `wheels deploy secrets fetch`

Pull one or more secrets from a secret manager.

## Synopsis

```bash
wheels deploy secrets fetch --adapter=<name> [--account=<acct>] [--from=<scope>] KEY1 KEY2 ...
```

## Description

Delegates to the named adapter's vendor CLI and prints resolved `KEY=VALUE` lines. The corresponding vendor CLI (`op`, `bw`, `aws`, `lpass`, `doppler`) must be on your PATH.

## Adapters

| Adapter | Aliases | Vendor CLI | `--from` semantics | `--account` used |
|---------|---------|------------|---------------------|------------------|
| 1Password | `op`, `1password` | `op` v2 | Vault name (default `Deploy`) | Account shorthand |
| Bitwarden | `bw`, `bitwarden` | `bw` | Ignored | Ignored |
| AWS Secrets Manager | `aws` | `aws` | Region (default `us-east-1`) | Ignored |
| LastPass | `lpass`, `lastpass` | `lpass` | Ignored | Ignored |
| Doppler | `doppler` | `doppler` | Project name | Ignored |

## Flags

| Flag | Description |
|------|-------------|
| `--adapter=<name>` | **Required.** One of the adapters above. |
| `--account=<acct>` | 1Password account shorthand. |
| `--from=<scope>` | Adapter-specific scope (vault, region, project). |

## Examples

```bash
wheels deploy secrets fetch --adapter=op --from=Deploy KAMAL_REGISTRY_PASSWORD
wheels deploy secrets fetch --adapter=aws --from=us-west-2 prod/db-url
wheels deploy secrets fetch --adapter=doppler --from=myapp KAMAL_REGISTRY_PASSWORD
```
