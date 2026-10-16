---
title: scope()
description: "Defines a named query scope that can be chained onto finders."
sidebar:
  label: scope()
  order: 0
---

## Signature

`scope()` — returns `void`

**Available in:** `model`
**Category:** Scope Functions

## Description

Defines a named query scope that can be chained onto finders.
Scopes allow you to define reusable query fragments in the model config and compose them together.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The name of the scope. This becomes a callable method on the model (e.g. `model("User").active()`). |
| `where` | `string` | no | — | A `WHERE` clause fragment to apply when this scope is used. |
| `order` | `string` | no | — | An `ORDER BY` clause fragment to apply when this scope is used. |
| `select` | `string` | no | — | A `SELECT` clause override to apply when this scope is used. |
| `include` | `string` | no | — | Associations to include when this scope is used. |
| `maxRows` | `numeric` | no | `0` | Maximum number of records to return when this scope is used. |
| `handler` | `string` | no | — | The name of a method on this model that returns a struct of query arguments. Use for dynamic scopes that accept parameters. The method receives any arguments passed to the scope call. |

</div>

