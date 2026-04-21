---
title: updateProperties()
description: "Updates all the properties from the properties argument or other named arguments. If the object is invalid, the save will fail and false will be returned."
sidebar:
  label: updateProperties()
  order: 0
---

## Signature

`updateProperties()` — returns `any`




## Description

Updates all the properties from the properties argument or other named arguments. If the object is invalid, the save will fail and false will be returned.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | yes | `[runtime expression]` | Struct containing key/value pairs with properties and associated values that need to be updated globally. |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `validate` | `boolean` | yes | — | Set to false to skip validations for this operation. |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |

</div>

## Examples

<pre>updateProperties([ properties, parameterize, validate, transaction, callbacks ]) &lt;!--- Sets the `new` property to `1` through `updateProperties()` ---&gt;
&lt;cfset product = model(&quot;product&quot;).findByKey(56)&gt;
&lt;cfset product.updateProperties(new=1)&gt;</pre>
