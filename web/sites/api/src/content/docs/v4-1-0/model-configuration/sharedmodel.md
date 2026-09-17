---
title: sharedModel()
description: "Marks this model as shared — it will always use the default application datasource"
sidebar:
  label: sharedModel()
  order: 0
---

## Signature

`sharedModel()` — returns `void`

**Available in:** `model`
**Category:** Multi-Tenancy

## Description

Marks this model as shared — it will always use the default application datasource
even when a tenant is active. Use this for models like <code>Tenant</code>, <code>Plan</code>, or any
lookup table that lives in the central database rather than per-tenant databases.




## Examples

<pre><code class='javascript'>// 1. Mark the Tenant model as shared so it always reads from the central database
// models/Tenant.cfc
component extends=&quot;Model&quot; {
    function config() {
        sharedModel();
    }
}

// 2. Use sharedModel() for lookup tables that live in the central database,
//    not in per-tenant databases
// models/Plan.cfc
component extends=&quot;Model&quot; {
    function config() {
        sharedModel();
        // All finder calls on Plan will use the default application datasource
        // regardless of which tenant is currently active.
    }
}
</code></pre>
