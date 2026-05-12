---
title: updateProperty()
description: "Updates a single <code>property</code> and saves the record without going through the normal validation procedure."
sidebar:
  label: updateProperty()
  order: 0
---

## Signature

`updateProperty()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Updates a single <code>property</code> and saves the record without going through the normal validation procedure.
This is especially useful for boolean flags on existing records.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to update the value for globally. |
| `value` | `any` | no | — | Value to set on the given property globally. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

</div>

## Examples

<pre><code class='javascript'>// Sets the `new` property to `1` through updateProperty()
product = model(&quot;product&quot;).findByKey(56);
product.updateProperty(&quot;new&quot;, 1);</code></pre>
