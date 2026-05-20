---
title: switchTenant()
description: "Switches the active tenant mid-request. Throws if the current tenant is locked"
sidebar:
  label: switchTenant()
  order: 0
---

## Signature

`switchTenant()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Multi-Tenancy

## Description

Switches the active tenant mid-request. Throws if the current tenant is locked
(set by TenantResolver middleware) unless <code>force</code> is true.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `tenant` | `struct` | yes | — | Struct with at minimum a `dataSource` key. Optional: `id`, `config`. |
| `force` | `boolean` | no | `false` | If true, overrides the lock set by TenantResolver middleware. |

</div>

