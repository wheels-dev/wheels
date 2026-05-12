---
title: whereNumber()
description: "Constrain a route variable to only match numeric values (digits). Similar to Laravel's <code>whereNumber()</code> or ASP.NET's <code>:int</code> constraint."
sidebar:
  label: whereNumber()
  order: 0
---

## Signature

`whereNumber()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match numeric values (digits). Similar to Laravel's <code>whereNumber()</code> or ASP.NET's <code>:int</code> constraint.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain (e.g., `"id"`). Can also be a comma-delimited list to constrain multiple variables. |

</div>

