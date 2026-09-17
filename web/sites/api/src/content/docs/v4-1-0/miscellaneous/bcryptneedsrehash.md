---
title: bcryptNeedsRehash()
description: "Whether an existing bcrypt hash should be re-hashed because its cost"
sidebar:
  label: bcryptNeedsRehash()
  order: 0
---

## Signature

`bcryptNeedsRehash()` — returns `boolean`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`


## Description

Whether an existing bcrypt hash should be re-hashed because its cost
factor differs from the target, or because it is malformed.
Self-contained (regex cost parse) so it can ship on EVERY engine —
including RustCFML, which provides bcryptHash/bcryptVerify as native
builtins and therefore skips the main security.cfm include.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `hash` | `string` | yes | — |  |
| `cost` | `numeric` | no | `10` |  |

</div>

