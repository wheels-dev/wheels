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

## Examples

<pre><code class='javascript'>// 1. Switch to a different tenant mid-request (minimal required argument)
switchTenant(tenant = {dataSource = &quot;tenant_db_acme&quot;});

// 2. Switch with a full tenant struct (id and per-tenant config override)
switchTenant(
    tenant = {
        dataSource = &quot;tenant_db_beta&quot;,
        id         = &quot;beta&quot;,
        config     = {timeZone = &quot;America/New_York&quot;}
    }
);

// 3. Force-switch even when the current tenant is locked by TenantResolver middleware
switchTenant(
    tenant = {dataSource = &quot;tenant_db_admin&quot;, id = &quot;admin&quot;},
    force  = true
);
</code></pre>
