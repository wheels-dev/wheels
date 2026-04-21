---
title: updateProperty()
description: "Updates a single property and saves the record without going through the normal validation procedure. This is especially useful for boolean flags on existing re"
sidebar:
  label: updateProperty()
  order: 0
---

## Signature

`updateProperty()` — returns `any`




## Description

Updates a single property and saves the record without going through the normal validation procedure. This is especially useful for boolean flags on existing records.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to update the value for globally. |
| `value` | `any` | yes | — | Value to set on the given property globally. |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |

</div>

## Examples

<pre>updateProperty(property, value [, parameterize, transaction, callbacks ]) &lt;!--- Sets the `new` property to `1` through updateProperty() ---&gt;
&lt;cfset product = model(&quot;product&quot;).findByKey(56)&gt;
&lt;cfset product.updateProperty(&quot;new&quot;, 1)&gt;</pre>
